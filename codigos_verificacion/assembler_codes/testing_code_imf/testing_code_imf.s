.text
    addi        x0, x0, 2047        # x0 = 0 siempre
    addi        x1, x0, 2047        # x1 = 2047
    xori        x2, x1, 1024        # x2 = x1 ^ 1024
    ori         x4, x2, 1563        # x4 = x2 | 1563
    andi        x5, x4, 1333        # x5 = x4 & 1333
    slli        x6, x5, 11          # x6 = x5 << 11
    addi        x7, x0, -78         # x7 = -78
    srai        x7, x7, 4           # x7 = x7 >> 4 (signed)
    srli        x7, x7, 1           # x7 = x7 >> 1 (unsigned)
    beq         x4, x1, label_1     # x4 == x1 -> label_1
label_2:
    sub         x12, x11, x4        # x11 = x11 - x4
    xor         x13, x12, x4        # x13 = x12 ^ x4
    or          x14, x6, x2         # x14 = x6 | x2
    and         x15, x6, x2         # x15 = x6 & x2
    bge         x4, x7, label_3     # x4 >= x7 -> label_3
    addi        x9, x0, 1           # x9 = 1
    sll         x16, x4, x9         # x16 = x4 << x9
    blt         x4, x7, label_4     # x4 < x7 -> label_4
label_1:
    add         x8, x4, x4          # x8 = x4 + x4
    addi        x9, x0, 2           # x9 = 2
    mul         x10, x4, x9         # x10 = x4 * x9
    sll         x11, x4, x9         # x11 = x4 << x9
    bge         x8, x10, label_2    # x8 >= x10 -> label_2
label_4:
    sb          x12, 8(x1)          # M[x1+8][7:0] = x12[7:0] -> sb x1, x12, 8
    sb          x12, 16(x2)         # M[x2+16][7:0] = x7[7:0] -> sb x2, x7, 16
    sll         x7, x7, x9          # x7 = x7 << x9
    sra         x18, x7, x9         # x18 = x7 >> x9 (signed)
    srl         x19, x7, x9         # x19 = x7 >> x9 (unsigned)
    sub         x14, x14, x6        # x14 = x14 - x6
    addi        x14, x14, -899      # x14 = x14 - 900
    sh          x19, 8(x14)         # M[x14+8][15:0] = x19[15:0] -> sb x14, x19, 8
    sw          x11, 16(x14)        # M[x14+16][31:0] = x11[31:0] -> sb x14, x11, 16
    jal         x20, label_5        # x20 = PC + 4, PC = label_5
label_3:
    lbu         x21, 16(x14)        # x21[7:0] = M[x14+16][7:0] -> lb x21, x14, 16 (unsigned)
    lbu         x22, 17(x14)        # x22[7:0] = M[x14+17][7:0] -> lb x22, x14, 17 (unsigned)
    slli        x22, x22, 8         # x22 = x22 << 8
    lbu         x23, 18(x14)        # x23[7:0] = M[x14+18][7:0] -> lb x23, x14, 18 (unsigned)
    slli        x23, x23, 16        # x23 = x23 << 16
    lbu         x24, 19(x14)        # x24[7:0] = M[x14+19][7:0] -> lb x24, x14, 19 (unsigned)
    slli        x24, x24, 24        # x24 = x24 << 24
    add         x25, x21, x22       # x25 = x21 + x22
    add         x25, x25, x23       # x25 = x25 + x23
    add         x25, x25, x24       # x25 = x25 + x24
    bne         x25, x19, label_5   # x25 != x19 -> label_5
    bltu        x7, x25, label_2    # x7 < x25 -> label_2 (unsigned)
    bgeu        x7, x25, label_6    # x7 >= x25 -> label_6 (unsigned)
label_7:
    rem         x25, x25, x23       # x25 = x25 % x23
    remu        x25, x18, x25       # x25 = x25 % x23 (unsigned)
    mulhu       x9, x25, x18        # x9 = x25 * x18 (h) (unsigned)
    mulhsu      x2, x18, x7         # x9 = x18 * x7 (h) (signed*unsigned)
    jal         x0, label_8         # PC = label_8
label_5:
    lb          x21, 16(x14)        # x21[7:0] = M[x14+16][7:0] -> lb x21, x14, 16
    lb          x22, 17(x14)        # x22[7:0] = M[x14+17][7:0] -> lb x22, x14, 17
    lb          x23, 18(x14)        # x23[7:0] = M[x14+18][7:0] -> lb x23, x14, 18
    lb          x24, 19(x14)        # x24[7:0] = M[x14+19][7:0] -> lb x24, x14, 19
    add         x26, x21, x22       # x26 = x21 + x22
    add         x26, x26, x23       # x26 = x26 + x23
    add         x26, x26, x24       # x26 = x26 + x24
    jalr        x20, x20, 0         # x20 = PC + 4, PC = x20 + 0
label_6:
    lui         x30, 500            # x30 = label_7    << 12
    auipc       x31, 500            # x30 = PC + label_7    << 12
    slt         x27, x12, x22       # x27 = x12 < x22 ? 1 : 0
    slti        x28, x12, 100       # x27 = x12 < 100 ? 1 : 0
    add         x27, x27, x28       # x27 = x27 + x28
    sltiu       x28, x12, -10       # x28 = x12 < -10 ? 1 : 0 (unsigned)
    add         x27, x27, x28       # x27 = x27 + x28
    sltu        x28, x18, x7        # x27 = x18 < x7 ? 1 : 0 (unsigned)
    add         x27, x27, x28       # x27 = x27 + x28
    lw          x28, 16(x14)        # x28[31:0] = M[x14+16][31:0] -> lb x28, x14, 16
    add         x28, x28, x27       # x28 = x28 + x27
    lh          x27, 16(x14)        # x27[15:0] = M[x14+16][15:0] -> lb x27, x14, 16
    lhu         x29, 16(x14)        # x29[15:0] = M[x14+16][15:0] -> lb x29, x14, 16
    divu        x27, x27, x29       # x27 = x27 / x29 (unsigned)
    mulh        x1, x23, x27        # x1 = x23 * x27 (h)
    mul         x23, x23, x27       # x1 = x23 * x27
    div         x23, x23, x27       # x1 = x23 / x27
    jal         x20, label_7        # x20 = PC + 4, PC = label_7
label_8:
    flw         f0, 16(x14)         # f0[31:0] = M[x14+16][31:0] -> flw f0, x14, 16
    fmv.w.x     x1, f12             # x12 -> f1 #-----# fmv.w.x     f1, x12
    fadd.s      f2, f0, f1          # f2 = f0 + f1
    fdiv.s      f3, f2, f0          # f3 = f2 / f0
    fsw         f3, 32(x14)         # M[x14+32][31:0] = f3[31:0] -> fsw x14, f3, 32
    flw         f4, 32(x14)         # f4[31:0] = M[x14+32][31:0] -> flw f4, x14, 32
    fsgnjn.s    f4, f4, f0          # f4 = abs(f4) * -sgn(f0)
    remu        x25, x25, x0        # x25 = x25
    fmul.s      f6, f3, f2          # f6 = f3 * f2
    fsgnjn.s    f7, f0, f0          # f4 = abs(f0) * -sgn(f0)
    fsub.s      f8, f6, f7          # f8 = f6 - f7
    fmadd.s     f5, f3, f2, f0      # f5 = f3 * f2 + f0
    fsqrt.s     f9, f7              # f9 = sqrt(f7)
    fsgnj.s     f10, f7, f4         # f10 = abs(f7) * sgn(f4)
    fsgnjx.s    f11, f7, f4         # f11 = f7 * sgn(f4)
    fmsub.s     f12, f4, f3, f10    # f12 = f4 * f3 - f10
    fmin.s      f13, f11, f12       # f13 = min(f11, f12)
    fmax.s      f14, f11, f12       # f13 = max(f11, f12)
    fnmadd.s    f15, f13, f4, f4    # f15 = -f13 * f4 + f10
    fnmsub.s    f16, f13, f4, f5    # f16 = -f13 * f4 - f10
    fmv.x.w     x1, f7              # f7 -> x1
    feq.s       x23, f0, f14        # x23 = (f0 == f14) ? 1 : 0
    flt.s       x24, f0, f14        # x24 = (f0 < f14) ? 1 : 0
    add         x23, x23, x24       # x23 += x24
    fle.s       x24, f11, f14       # x23 = (f0 <= f14) ? 1 : 0
    add         x23, x23, x24       # x23 += x24
    add         x1, x23, x1         # x1 += x23
    fcvt.wu.s   x23, f3             # x23 = uint(f3)
    fsgnjn.s    f3, f3, f3          # f4 = abs(f3) * -sgn(f3)
    fcvt.w.s    x24, f3             # x24 = int(f3)
    add         x23, x24, x23       # x23 += x24 -> x23 = 0
    fcvt.s.w    f17, x7             # f17 = fp(int(x7))
    fclass.s    x24, f8             # x24 = class(f8)
    fcvt.s.wu   f18, x7             # f18 = fp(uint(x7)) ### error en el fp_converter

    addi        x17, x0, 10         # syscall para terminar el programa
    ecall                           # Se ejecuta el syscall