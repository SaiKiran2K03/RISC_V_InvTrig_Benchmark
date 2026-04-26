#####################################################################
#  RISC-V (RV64D) – arccos(x) via Newton-Raphson
#  arccos(x) = pi/2 - arcsin(x)
#  SILENT I/O: syscall 7, syscall 3
#####################################################################

.data
val_1:    .double  1.0
val_6:    .double  6.0
val_24:   .double  24.0
val_120:  .double  120.0
val_720:  .double  720.0
val_5040: .double  5040.0
val_2:    .double  2.0
pi_half:  .double  1.5707963267948966

.text
.globl main
main:
    li      a7, 7
    ecall
    fmv.d   fs0, fa0

    # Initial guess: θ₀ = x + x³/6
    fmul.d  ft0, fs0, fs0
    fmul.d  ft0, ft0, fs0
    fld     ft1, val_6, t0
    fdiv.d  ft0, ft0, ft1
    fadd.d  fs1, fs0, ft0

    li      s0, 0
    li      s1, 8

newton_loop:
    bge     s0, s1, newton_done

    fmul.d  ft0, fs1, fs1           # θ²
    fmul.d  ft1, ft0, fs1           # θ³
    fmul.d  ft2, ft1, ft0           # θ⁵
    fmul.d  ft3, ft2, ft0           # θ⁷

    fld     ft5, val_6, t0
    fdiv.d  ft6, ft1, ft5
    fld     ft5, val_120, t0
    fdiv.d  ft7, ft2, ft5
    fld     ft5, val_5040, t0
    fdiv.d  ft8, ft3, ft5

    fsub.d  fs2, fs1, ft6
    fadd.d  fs2, fs2, ft7
    fsub.d  fs2, fs2, ft8

    fld     ft5, val_1, t0
    fld     ft6, val_2, t0
    fdiv.d  ft7, ft0, ft6
    fmul.d  ft8, ft0, ft0
    fld     ft6, val_24, t0
    fdiv.d  ft8, ft8, ft6
    fmul.d  ft9, ft0, ft0
    fmul.d  ft9, ft9, ft0
    fld     ft6, val_720, t0
    fdiv.d  ft9, ft9, ft6

    fsub.d  fs3, ft5, ft7
    fadd.d  fs3, fs3, ft8
    fsub.d  fs3, fs3, ft9

    fsub.d  ft0, fs2, fs0
    fdiv.d  ft0, ft0, fs3
    fsub.d  fs1, fs1, ft0

    addi    s0, s0, 1
    j       newton_loop

newton_done:
    # arccos = pi/2 - arcsin
    fld     ft0, pi_half, t0
    fsub.d  fa0, ft0, fs1
    li      a7, 3
    ecall
    li      a7, 10
    ecall
