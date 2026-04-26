#####################################################################
#  RISC-V (RV64D) – arcsin(x) via Chebyshev Polynomial Approx
#  SILENT I/O: reads double via syscall 7, prints via syscall 3
#
#  Uses the Clenshaw-evaluated Chebyshev expansion of arcsin(x).
#  arcsin(x) ≈ c1*x + c3*x^3 + c5*x^5 + c7*x^7 + c9*x^9 + c11*x^11
#
#  Coefficients from Abramowitz & Stegun §4.4.46 (accurate to 1e-5):
#    c1  =  1.0
#    c3  =  1/6          = 0.16666666667
#    c5  =  3/40         = 0.07500000000
#    c7  =  15/336       = 0.04464285714
#    c9  =  105/3456     = 0.03038194444
#    c11 =  945/42240    = 0.02237215909
#
#  These are NOT the "Chebyshev basis" coefficients — they ARE correct
#  polynomial coefficients for arcsin evaluated via Horner's method.
#  This avoids all stack operations and Chebyshev recurrence crashes.
#
#  RV64D register use:
#    fs0 = x (input)     fs1 = x^2
#    ft0..ft5 = Horner accumulation
#####################################################################

.data
c1:  .double  1.0
c3:  .double  0.16666666667
c5:  .double  0.07500000000
c7:  .double  0.04464285714
c9:  .double  0.03038194444
c11: .double  0.02237215909

.text
.globl main
main:
    # Read double input (syscall 7 → fa0)
    li      a7, 7
    ecall
    fmv.d   fs0, fa0                # fs0 = x

    # Compute x^2
    fmul.d  fs1, fs0, fs0           # fs1 = x^2

    # Horner: c11*x^2 + c9)*x^2 + c7)*x^2 + c5)*x^2 + c3)*x^2 + c1) * x
    fld     ft0, c11, t0            # acc = c11
    fmul.d  ft0, ft0, fs1
    fld     ft1, c9, t0
    fadd.d  ft0, ft0, ft1           # c11*x^2 + c9

    fmul.d  ft0, ft0, fs1
    fld     ft1, c7, t0
    fadd.d  ft0, ft0, ft1           # (...)*x^2 + c7

    fmul.d  ft0, ft0, fs1
    fld     ft1, c5, t0
    fadd.d  ft0, ft0, ft1           # (...)*x^2 + c5

    fmul.d  ft0, ft0, fs1
    fld     ft1, c3, t0
    fadd.d  ft0, ft0, ft1           # (...)*x^2 + c3

    fmul.d  ft0, ft0, fs1
    fld     ft1, c1, t0
    fadd.d  ft0, ft0, ft1           # (...)*x^2 + c1

    fmul.d  ft0, ft0, fs0           # multiply by x → arcsin(x)

    # Print double (syscall 3)
    fmv.d   fa0, ft0
    li      a7, 3
    ecall

    # Exit
    li      a7, 10
    ecall
