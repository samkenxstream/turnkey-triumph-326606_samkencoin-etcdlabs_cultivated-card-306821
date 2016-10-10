// Copyright 2016 CoreOS, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package backend

import (
	"context"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"sync"
	"time"

	"github.com/coreos/etcdlabs/cluster"
	"github.com/coreos/etcdlabs/listener"
	"github.com/coreos/etcdlabs/ratelimit"
)

var (
	rootPortMu sync.Mutex
	rootPort   = 2379
)

func startCluster(rootCtx context.Context, rootCancel func()) (*cluster.Cluster, error) {
	rootPortMu.Lock()
	port := rootPort
	rootPort += 10 // for testing
	rootPortMu.Unlock()

	dir, err := ioutil.TempDir(os.TempDir(), "backend-cluster")
	if err != nil {
		return nil, err
	}

	cfg := cluster.Config{
		Size:          5,
		RootDir:       dir,
		RootPort:      port,
		ClientAutoTLS: true,
		RootCtx:       rootCtx,
		RootCancel:    rootCancel,
	}
	return cluster.Start(cfg)
}

// Server warps http.Server.
type Server struct {
	mu         sync.RWMutex
	addrURL    url.URL
	httpServer *http.Server

	rootCancel func()
	stopc      chan struct{}
	donec      chan struct{}
}

var (
	defaultLimitInterval       = 2 * time.Second
	defaultStopRestartInterval = 3 * time.Second

	// for websocket
	globalWebserverPort int

	globalCluster              *cluster.Cluster
	globalClientRequestLimiter ratelimit.RequestLimiter
	globalStopRestartLimiter   ratelimit.RequestLimiter
)

// StartServer starts a backend webserver with stoppable listener.
func StartServer(port int) (*Server, error) {
	globalWebserverPort = port

	stopc := make(chan struct{})
	ln, err := listener.NewListenerStoppable("http", fmt.Sprintf("localhost:%d", port), nil, stopc)
	if err != nil {
		return nil, err
	}

	rootCtx, rootCancel := context.WithCancel(context.Background())
	c, err := startCluster(rootCtx, rootCancel)
	if err != nil {
		return nil, err
	}
	globalCluster = c

	// allow only 1 request for every 2 second
	globalClientRequestLimiter = ratelimit.NewRequestLimiter(rootCtx, defaultLimitInterval)

	// rate-limit more strictly for every 3 second
	globalStopRestartLimiter = ratelimit.NewRequestLimiter(rootCtx, defaultStopRestartInterval)

	mux := http.NewServeMux()
	mux.Handle("/conn", &ContextAdapter{
		ctx:     rootCtx,
		handler: withCache(ContextHandlerFunc(connectHandler)),
	})
	mux.Handle("/ws", &ContextAdapter{
		ctx:     rootCtx,
		handler: withCache(ContextHandlerFunc(wsHandler)),
	})
	mux.Handle("/server-status", &ContextAdapter{
		ctx:     rootCtx,
		handler: withCache(ContextHandlerFunc(serverStatusHandler)),
	})
	mux.Handle("/client-request", &ContextAdapter{
		ctx:     rootCtx,
		handler: withCache(ContextHandlerFunc(clientRequestHandler)),
	})

	addrURL := url.URL{Scheme: "http", Host: fmt.Sprintf("localhost:%d", port)}
	plog.Infof("started server %s", addrURL.String())
	srv := &Server{
		addrURL:    addrURL,
		httpServer: &http.Server{Addr: addrURL.String(), Handler: mux},
		rootCancel: rootCancel,
		stopc:      stopc,
		donec:      make(chan struct{}),
	}

	go func() {
		defer func() {
			if err := recover(); err != nil {
				plog.Errorf("etcd-play error (%v)", err)
				os.Exit(0)
			}
			srv.rootCancel()
			close(srv.donec)
		}()

		if err := srv.httpServer.Serve(ln); err != nil && err != listener.ErrListenerStopped {
			plog.Panic(err)
		}
	}()
	return srv, nil
}

// StopNotify returns receive-only stop channel to notify the server has stopped.
func (srv *Server) StopNotify() <-chan struct{} {
	return srv.stopc
}

// Stop stops the server. Useful for testing.
func (srv *Server) Stop() {
	plog.Warningf("stopping server %s", srv.addrURL.String())
	srv.mu.Lock()
	if srv.httpServer == nil {
		srv.mu.Unlock()
		return
	}
	close(srv.stopc)
	<-srv.donec
	srv.httpServer = nil
	srv.mu.Unlock()
	plog.Warningf("stopped server %s", srv.addrURL.String())

	plog.Warning("stopping cluster")
	globalCluster.Shutdown()
	globalCluster = nil
	plog.Warning("stopped cluster")
}