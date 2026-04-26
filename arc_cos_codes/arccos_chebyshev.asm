#####################################################################
#  RISC-V (RV64D) – arccos(x) via Chebyshev Polynomial Approx
#  arccos(x) = pi/2 - arcsin(x)
#  SILENT I/O: syscall 7 (read double), syscall 3 (print double)
#####################################################################

.data
c1:      .double  1.0
c3:      .double  0.16666666667
c5:      .double  0.07500000000
c7:      .double  0.04464285714
c9:      .double  0.03038194444
c11:     .double  0.02237215909
pi_half: .double  1.5707963267948966

.text
.globl main
main:
    li      a7, 7
    ecall
    fmv.d   fs0, fa0

    fmul.d  fs1, fs0, fs0

    fld     ft0, c11, t0
    fmul.d  ft0, ft0, fs1
    fld     ft1, c9, t0
    fadd.d  ft0, ft0, ft1

    fmul.d  ft0, ft0, fs1
    fld     ft1, c7, t0
    fadd.d  ft0, ft0, ft1

    fmul.d  ft0, ft0, fs1
    fld     ft1, c5, t0
    fadd.d  ft0, ft0, ft1

    fmul.d  ft0, ft0, fs1
    fld     ft1, c3, t0
    fadd.d  ft0, ft0, ft1

    fmul.d  ft0, ft0, fs1
    fld     ft1, c1, t0
    fadd.d  ft0, ft0, ft1

    fmul.d  ft0, ft0, fs0           # ft0 = arcsin(x)

    # arccos(x) = pi/2 - arcsin(x)
    fld     ft2, pi_half, t0
    fsub.d  ft0, ft2, ft0

    fmv.d   fa0, ft0
    li      a7, 3
    ecall
    li      a7, 10
    ecall

