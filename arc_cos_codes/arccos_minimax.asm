#####################################################################
#  RISC-V (RV64D) – arccos(x) via Minimax Rational Approximation
#  arccos(x) = pi/2 - arcsin(x)
#  Same range reduction + rational as arcsin_minimax.asm
#  SILENT I/O: syscall 7 (read double), syscall 3 (print double)
#####################################################################

.data
p0:      .double  1.0
p1:      .double -0.2145988016
p2:      .double  0.0889789874
q0:      .double  1.0
q1:      .double -0.3255658186
q2:      .double  0.1471039133
pi_half: .double  1.5707963267948966
val_one: .double  1.0
val_half:.double  0.5
val_two: .double  2.0
val_zero:.double  0.0

.text
.globl main
main:
    li      a7, 7
    ecall
    fmv.d   fs0, fa0

    fld     fs2, val_two, t0

    li      s10, 0
    fld     ft0, val_zero, t0
    flt.d   t1, fs0, ft0
    beqz    t1, sign_done
    li      s10, 1
    fneg.d  fs0, fs0
sign_done:

    fld     ft0, val_half, t0
    flt.d   t1, ft0, fs0
    beqz    t1, use_direct
    li      s11, 1

    fld     ft1, val_one, t0
    fsub.d  ft1, ft1, fs0
    fdiv.d  ft1, ft1, fs2

    fld     ft2, val_half, t0
    li      s0, 0
    li      s1, 6
sqrt_loop:
    bge     s0, s1, sqrt_done
    fdiv.d  ft3, ft1, ft2
    fadd.d  ft2, ft2, ft3
    fdiv.d  ft2, ft2, fs2
    addi    s0, s0, 1
    j       sqrt_loop
sqrt_done:
    fmv.d   fs0, ft2
    j       compute_rational

use_direct:
    li      s11, 0

compute_rational:
    fmul.d  fs1, fs0, fs0

    fld     ft0, p2, t0
    fmul.d  ft0, ft0, fs1
    fld     ft1, p1, t0
    fadd.d  ft0, ft0, ft1
    fmul.d  ft0, ft0, fs1
    fld     ft1, p0, t0
    fadd.d  ft0, ft0, ft1

    fld     ft2, q2, t0
    fmul.d  ft2, ft2, fs1
    fld     ft3, q1, t0
    fadd.d  ft2, ft2, ft3
    fmul.d  ft2, ft2, fs1
    fld     ft3, q0, t0
    fadd.d  ft2, ft2, ft3

    fdiv.d  ft0, ft0, ft2
    fmul.d  fs3, ft0, fs0           # arcsin_core

    beqz    s11, apply_sign
    fmul.d  fs3, fs3, fs2           # 2*arcsin_core
    fld     ft1, pi_half, t0
    fsub.d  fs3, ft1, fs3           # pi/2 - 2*arcsin_core

apply_sign:
    beqz    s10, to_arccos
    fneg.d  fs3, fs3                # arcsin(x) with sign

to_arccos:
    # arccos(x) = pi/2 - arcsin(x)
    fld     ft0, pi_half, t0
    fsub.d  fa0, ft0, fs3
    li      a7, 3
    ecall
    li      a7, 10
    ecall
