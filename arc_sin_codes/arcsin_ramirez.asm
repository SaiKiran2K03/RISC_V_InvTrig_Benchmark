.data
val_one:     .double 1.0
val_half:    .double 0.5
val_pi_half: .double 1.5707963267948966
# Ramirez Coefficients
r0: .double 1.5707288
r1: .double -0.2121144
r2: .double 0.0742610
r3: .double -0.0187293

.text
.globl main
main:
    # 1. SILENT INPUT
    li      a7, 7
    ecall
    fmv.d   fs0, fa0                # fs0 = x

    # 2. HANDLE NEGATIVES (|x|)
    fld     ft0, val_one, t0
    fabs.d  fs1, fs0                # fs1 = abs(x)

    # 3. COMPUTE sqrt(1 - abs(x))
    fsub.d  ft1, ft0, fs1           # 1 - |x|
    fsqrt.d fs2, ft1                # fs2 = sqrt(1 - |x|)

    # 4. POLYNOMIAL: r0 + r1*|x| + r2*|x|^2 + r3*|x|^3
    fld     ft2, r3, t0
    fmul.d  ft2, ft2, fs1           # r3*|x|
    fld     ft3, r2, t0
    fadd.d  ft2, ft2, ft3           # r3*|x| + r2
    fmul.d  ft2, ft2, fs1           # r3*|x|^2 + r2*|x|
    fld     ft3, r1, t0
    fadd.d  ft2, ft2, ft3           # ... + r1
    fmul.d  ft2, ft2, fs1           # ... + r1*|x|
    fld     ft3, r0, t0
    fadd.d  ft2, ft2, ft3           # ft2 = Result P(|x|)

    # 5. arcsin = pi/2 - sqrt(1-|x|) * P(|x|)
    fmul.d  ft4, fs2, ft2           # sqrt * P
    fld     ft5, val_pi_half, t0
    fsub.d  ft6, ft5, ft4           # pi/2 - (sqrt * P)

    # 6. RESTORE SIGN
    li      t1, 0
    fcvt.d.w ft7, t1
    flt.d   t2, fs0, ft7            # is x < 0?
    beqz    t2, skip_neg
    fneg.d  ft6, ft6
skip_neg:
    # 7. SILENT OUTPUT
    fmv.d   fa0, ft6
    li      a7, 3
    ecall
    li      a7, 10
    ecall
