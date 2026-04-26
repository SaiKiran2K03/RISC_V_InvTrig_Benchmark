.data
val_one:    .double 1.0
val_two:    .double 2.0
val_four:   .double 4.0

.text
.globl main
main:
    # 1. SILENT INPUT (Read Double)
    li      a7, 7
    ecall
    fmv.d   fa0, fa0

    # 2. INITIALIZE VARIABLES
    fmv.d   ft8, fa0                 # sum = x
    fmv.d   ft9, fa0                 # x_power = x
    fmul.d  ft10, fa0, fa0           # x_squared = x^2
    fld     ft11, val_one, t0        # coeff = 1.0

    fld     ft3, val_two, t0
    fld     ft4, val_four, t0
    fld     ft1, val_one, t0

    li      s0, 1                    # n = 1
    li      s1, 100                  # 100 iterations for high precision

taylor_loop:
    bgt     s0, s1, done
    fmul.d  ft9, ft9, ft10           # x_power *= x^2
    fcvt.d.w ft0, s0                 # float(n)
    
    # Calculate numerator: (2n - 1) * 2n
    fmul.d   ft5, ft3, ft0           # 2n
    fsub.d   ft6, ft5, ft1           # 2n - 1
    fmul.d   ft6, ft6, ft5           # (2n - 1) * 2n
    
    # Calculate denominator: 4n^2
    fmul.d   ft7, ft0, ft0           # n^2
    fmul.d   ft7, ft7, ft4           # 4n^2
    
    # Update coefficient
    fmul.d   ft11, ft11, ft6         # coeff *= numerator
    fdiv.d   ft11, ft11, ft7         # coeff /= denominator
    
    # Calculate term: (coeff / (2n + 1)) * x_power
    fadd.d   ft6, ft5, ft1           # 2n + 1
    fdiv.d   ft0, ft11, ft6          # coeff / (2n + 1)
    fmul.d   ft0, ft0, ft9           # term
    
    # Add to sum
    fadd.d   ft8, ft8, ft0           # sum += term
    
    addi    s0, s0, 1
    j       taylor_loop

done:
    # 3. SILENT OUTPUT (Print Double)
    fmv.d   fa0, ft8
    li      a7, 3
    ecall
    li      a7, 10
    ecall
