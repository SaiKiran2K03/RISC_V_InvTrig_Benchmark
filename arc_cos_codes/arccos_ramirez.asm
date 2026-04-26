.data
val_one:     .double 1.0
val_pi_half: .double 1.5707963267948966
r0: .double 1.5707288
r1: .double -0.2121144
r2: .double 0.0742610
r3: .double -0.0187293

.text
.globl main
main:
    li      a7, 7
    ecall
    fmv.d   fs0, fa0
    fld     ft0, val_one, t0
    fabs.d  fs1, fs0
    fsub.d  ft1, ft0, fs1
    fsqrt.d fs2, ft1
    fld     ft2, r3, t0
    fmul.d  ft2, ft2, fs1
    fld     ft3, r2, t0
    fadd.d  ft2, ft2, ft3
    fmul.d  ft2, ft2, fs1
    fld     ft3, r1, t0
    fadd.d  ft2, ft2, ft3
    fmul.d  ft2, ft2, fs1
    fld     ft3, r0, t0
    fadd.d  ft2, ft2, ft3
    fmul.d  ft4, fs2, ft2
    fld     ft5, val_pi_half, t0
    fsub.d  ft6, ft5, ft4
    li      t1, 0
    fcvt.d.w ft7, t1
    flt.d   t2, fs0, ft7
    beqz    t2, apply_arccos
    fneg.d  ft6, ft6
apply_arccos:
    fsub.d  ft6, ft5, ft6           # arccos(x) = pi/2 - arcsin(x)
    fmv.d   fa0, ft6
    li      a7, 3
    ecall
    li      a7, 10
    ecall
