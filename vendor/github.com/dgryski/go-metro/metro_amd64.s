// Generated by PeachPy 0.2.0 from metro.py


// func Hash64(buffer_base uintptr, buffer_len int64, buffer_cap int64, seed uint64) uint64
TEXT ·Hash64(SB),4,$0-40
	MOVQ seed+24(FP), CX
	MOVQ buffer_base+0(FP), AX
	MOVQ buffer_len+8(FP), BX
	MOVQ $3603962101, DX
	IMULQ DX, CX
	MOVQ $5961697176435608501, DX
	ADDQ DX, CX
	CMPQ BX, $32
	JLT after32
	MOVQ CX, DX
	MOVQ CX, DI
	MOVQ CX, SI
	MOVQ CX, BP
loop_begin:
		MOVQ 0(AX), R8
		MOVQ $3603962101, R9
		IMULQ R9, R8
		ADDQ R8, DX
		RORQ $29, DX
		ADDQ SI, DX
		MOVQ 8(AX), R8
		MOVQ $2729050939, R9
		IMULQ R9, R8
		ADDQ R8, DI
		RORQ $29, DI
		ADDQ BP, DI
		MOVQ 16(AX), R8
		MOVQ $1654206401, R9
		IMULQ R9, R8
		ADDQ R8, SI
		RORQ $29, SI
		ADDQ DX, SI
		MOVQ 24(AX), R8
		MOVQ $817650473, R9
		IMULQ R9, R8
		ADDQ R8, BP
		RORQ $29, BP
		ADDQ DI, BP
		ADDQ $32, AX
		SUBQ $32, BX
		CMPQ BX, $32
		JGE loop_begin
	MOVQ DX, R8
	ADDQ BP, R8
	MOVQ $3603962101, R9
	IMULQ R9, R8
	ADDQ DI, R8
	RORQ $37, R8
	MOVQ $2729050939, R9
	IMULQ R9, R8
	XORQ R8, SI
	MOVQ DI, R8
	ADDQ SI, R8
	MOVQ $2729050939, R9
	IMULQ R9, R8
	ADDQ DX, R8
	RORQ $37, R8
	MOVQ $3603962101, R9
	IMULQ R9, R8
	XORQ R8, BP
	MOVQ DX, R8
	ADDQ SI, R8
	MOVQ $3603962101, R9
	IMULQ R9, R8
	ADDQ BP, R8
	RORQ $37, R8
	MOVQ $2729050939, R9
	IMULQ R9, R8
	XORQ R8, DX
	MOVQ DI, R8
	ADDQ BP, R8
	MOVQ $2729050939, BP
	IMULQ BP, R8
	ADDQ SI, R8
	RORQ $37, R8
	MOVQ $3603962101, SI
	IMULQ SI, R8
	XORQ R8, DI
	XORQ DI, DX
	ADDQ DX, CX
after32:
	CMPQ BX, $16
	JLT after16
	MOVQ 0(AX), DX
	MOVQ $1654206401, DI
	IMULQ DI, DX
	ADDQ CX, DX
	ADDQ $8, AX
	SUBQ $8, BX
	RORQ $29, DX
	MOVQ $817650473, DI
	IMULQ DI, DX
	MOVQ 0(AX), DI
	MOVQ $1654206401, SI
	IMULQ SI, DI
	ADDQ CX, DI
	ADDQ $8, AX
	SUBQ $8, BX
	RORQ $29, DI
	MOVQ $817650473, SI
	IMULQ SI, DI
	MOVQ DX, SI
	MOVQ $3603962101, BP
	IMULQ BP, SI
	RORQ $21, SI
	ADDQ DI, SI
	XORQ SI, DX
	MOVQ DI, SI
	MOVQ $817650473, BP
	IMULQ BP, SI
	RORQ $21, SI
	ADDQ DX, SI
	XORQ SI, DI
	ADDQ DI, CX
after16:
	CMPQ BX, $8
	JLT after8
	MOVQ 0(AX), DX
	MOVQ $817650473, DI
	IMULQ DI, DX
	ADDQ DX, CX
	ADDQ $8, AX
	SUBQ $8, BX
	MOVQ CX, DX
	RORQ $55, DX
	MOVQ $2729050939, DI
	IMULQ DI, DX
	XORQ DX, CX
after8:
	CMPQ BX, $4
	JLT after4
	XORQ DX, DX
	MOVL 0(AX), DX
	MOVQ $817650473, DI
	IMULQ DI, DX
	ADDQ DX, CX
	ADDQ $4, AX
	SUBQ $4, BX
	MOVQ CX, DX
	RORQ $26, DX
	MOVQ $2729050939, DI
	IMULQ DI, DX
	XORQ DX, CX
after4:
	CMPQ BX, $2
	JLT after2
	XORQ DX, DX
	MOVW 0(AX), DX
	MOVQ $817650473, DI
	IMULQ DI, DX
	ADDQ DX, CX
	ADDQ $2, AX
	SUBQ $2, BX
	MOVQ CX, DX
	RORQ $48, DX
	MOVQ $2729050939, DI
	IMULQ DI, DX
	XORQ DX, CX
after2:
	CMPQ BX, $1
	JLT after1
	MOVBQZX 0(AX), AX
	MOVQ $817650473, BX
	IMULQ BX, AX
	ADDQ AX, CX
	MOVQ CX, AX
	RORQ $37, AX
	MOVQ $2729050939, BX
	IMULQ BX, AX
	XORQ AX, CX
after1:
	MOVQ CX, AX
	RORQ $28, AX
	XORQ AX, CX
	MOVQ $3603962101, AX
	IMULQ AX, CX
	MOVQ CX, AX
	RORQ $29, AX
	XORQ AX, CX
	MOVQ CX, ret+32(FP)
	RET