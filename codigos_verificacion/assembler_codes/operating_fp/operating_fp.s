.data

    begin_msg:      .word   0xBBBBBBBB
    end_msg:        .word   0xEEEEEEEE

.text

main:
    lw      a0, 0(x0)#begin_msg
    li      x17, 1  # syscall 1: PrintInt
	ecall
get_fps:
    fmv.w.x x0, ft0 # ft0=0 por algún motivo en rars los operandos deben estar al revés solo para esta instrucción
    li      x17, 6  # syscall 1: GetFp
    ecall
    fadd.s  ft1, fa0, ft0   # ft1 operando 1
    li      x17, 6  # syscall 1: GetFp
    ecall
    fadd.s  ft2, fa0, ft0   # ft2 operando 2
operations:
    fmul.s      ft3, ft1, ft2           # ft3  = ft1*ft2
    fadd.s      ft4, ft1, ft2           # ft4  = ft1+ft2
    fsub.s      ft5, ft3, ft4           # ft5  = ft3-ft4
    fdiv.s      ft6, ft4, ft1           # ft6  = ft4/ft1
    fsqrt.s     ft7, ft3                # ft7  = sqrt(ft3)
    fmadd.s     ft8, ft3, ft6, ft1      # ft8  = ft3*ft6+ft1
    fmsub.s     ft9, ft3, ft6, ft1      # ft9  = ft3*ft6-ft1
    fnmadd.s    ft10, ft3, ft6, ft1     # ft10 = -ft3*ft6+ft1
    fnmsub.s    ft11, ft3, ft6, ft1     # ft11 = -ft3*ft6-ft1
printing_res:
    fadd.s  fa0, ft0, ft3
    li      x17, 2  # syscall 2: PrintFp
	ecall
    fadd.s  fa0, ft0, ft4
    li      x17, 2  # syscall 2: PrintFp
	ecall
    fadd.s  fa0, ft0, ft5
    li      x17, 2  # syscall 2: PrintFp
	ecall
    fadd.s  fa0, ft0, ft6
    li      x17, 2  # syscall 2: PrintFp
	ecall
    fadd.s  fa0, ft0, ft7
    li      x17, 2  # syscall 2: PrintFp
	ecall
    fadd.s  fa0, ft0, ft8
    li      x17, 2  # syscall 2: PrintFp
	ecall
    fadd.s  fa0, ft0, ft9
    li      x17, 2  # syscall 2: PrintFp
	ecall
    fadd.s  fa0, ft0, ft10
    li      x17, 2  # syscall 2: PrintFp
	ecall
    fadd.s  fa0, ft0, ft11
    li      x17, 2  # syscall 2: PrintFp
	ecall
done:
    lw      a0, 4(x0)#end_msg
    li      x17, 1  # syscall 1: PrintInt
	ecall
	li      x17, 10 # syscall 10: Exit
	ecall
