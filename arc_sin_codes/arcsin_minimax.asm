#####################################################################
#  RISC-V (RV64D) – arcsin(x) via Minimax Rational Approximation
#  SILENT I/O: syscall 7 (read double), syscall 3 (print double)
#
#  For |x| <= 0.5:  arcsin(x) = x * P(x²)/Q(x²)
#  For |x| >  0.5:  arcsin(x) = sign*(pi/2 - 2*arcsin(sqrt((1-|x|)/2)))
#  sqrt computed by 6 Newton iterations.
#
#  P(s) = p0 + s*(p1 + s*p2)   (Horner)
#  Q(s) = q0 + s*(q1 + s*q2)
#
#  Saved FP regs: fs0=x(abs), fs1=s=z^2, fs2=two(const), fs3=core
#  s10 = sign flag (0=pos, 1=neg)
#  s11 = range flag (0=direct, 1=reduced)
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
    fmv.d   fs0, fa0                # fs0 = x

    # Load constant 2.0 into fs2 (saved, survives loop)
    fld     fs2, val_two, t0        # fs2 = 2.0

    # Sign extraction
    li      s10, 0
    fld     ft0, val_zero, t0
    flt.d   t1, fs0, ft0
    beqz    t1, sign_done
    li      s10, 1
    fneg.d  fs0, fs0                # fs0 = |x|
sign_done:

    # Range check: is |x| > 0.5?
    fld     ft0, val_half, t0
    flt.d   t1, ft0, fs0            # t1 = (0.5 < |x|)
    beqz    t1, use_direct
    li      s11, 1

    # --- Range reduction ---
    fld     ft1, val_one, t0
    fsub.d  ft1, ft1, fs0           # 1 - |x|
    fdiv.d  ft1, ft1, fs2           # t = (1-|x|)/2

    # sqrt(t): z = 0.5 initial guess, 6 Newton iterations
    fld     ft2, val_half, t0       # z = 0.5
    li      s0, 0
    li      s1, 6
sqrt_loop:
    bge     s0, s1, sqrt_done
    fdiv.d  ft3, ft1, ft2           # t/z
    fadd.d  ft2, ft2, ft3           # z + t/z
    fdiv.d  ft2, ft2, fs2           # (z + t/z) / 2.0   (fs2 = 2.0)
    addi    s0, s0, 1
    j       sqrt_loop
sqrt_done:
    fmv.d   fs0, ft2                # fs0 = z = sqrt((1-|x|)/2)
    j       compute_rational

use_direct:
    li      s11, 0

compute_rational:
    fmul.d  fs1, fs0, fs0           # fs1 = s = z^2

    # P(s) via Horner: p0 + s*(p1 + s*p2)
    fld     ft0, p2, t0
    fmul.d  ft0, ft0, fs1
    fld     ft1, p1, t0
    fadd.d  ft0, ft0, ft1
    fmul.d  ft0, ft0, fs1
    fld     ft1, p0, t0
    fadd.d  ft0, ft0, ft1           # ft0 = P(s)

    # Q(s) via Horner: q0 + s*(q1 + s*q2)
    fld     ft2, q2, t0
    fmul.d  ft2, ft2, fs1
    fld     ft3, q1, t0
    fadd.d  ft2, ft2, ft3
    fmul.d  ft2, ft2, fs1
    fld     ft3, q0, t0
    fadd.d  ft2, ft2, ft3           # ft2 = Q(s)

    # arcsin_core = z * P(s) / Q(s)
    fdiv.d  ft0, ft0, ft2           # P/Q
    fmul.d  fs3, ft0, fs0           # fs3 = z * P/Q = arcsin_core

    # Reconstruct if range-reduced
    beqz    s11, apply_sign
    fmul.d  fs3, fs3, fs2           # 2 * arcsin_core
    fld     ft1, pi_half, t0
    fsub.d  fs3, ft1, fs3           # pi/2 - 2*arcsin_core

apply_sign:
    beqz    s10, output_val
    fneg.d  fs3, fs3

output_val:
    fmv.d   fa0, fs3
    li      a7, 3
    ecall
    li      a7, 10
    ecall
