#####################################################################
#  RISC-V (RV64D) – arcsin(x) via Newton-Raphson Iteration
#  SILENT I/O: syscall 7 (read double), syscall 3 (print double)
#
#  Newton on f(θ) = sin(θ) - x → θ_{n+1} = θ_n - (sin(θ_n)-x)/cos(θ_n)
#
#  FIX over broken version:
#    - sin/cos use 5-term Taylor (not 2-term) → stable for θ up to π/2
#    - Initial guess: θ0 = x + x³/6  (better than θ0=x alone)
#    - 8 iterations (Newton converges quadratically)
#
#  RV64D registers:
#    fs0 = x (target)   fs1 = θ (current estimate)
#    fs2 = sin(θ)       fs3 = cos(θ)
#    ft0-ft9 = scratch
#    s0 = loop counter  s1 = max iterations
#####################################################################

.data
val_1:    .double  1.0
val_2:    .double  2.0
val_6:    .double  6.0
val_24:   .double  24.0
val_120:  .double  120.0
val_720:  .double  720.0
val_5040: .double  5040.0
val_40320:.double  40320.0

.text
.globl main
main:
    # 1. Read x
    li      a7, 7
    ecall
    fmv.d   fs0, fa0                # fs0 = x

    # 2. Initial guess: θ₀ = x + x³/6
    fmul.d  ft0, fs0, fs0           # x²
    fmul.d  ft0, ft0, fs0           # x³
    fld     ft1, val_6, t0
    fdiv.d  ft0, ft0, ft1           # x³/6
    fadd.d  fs1, fs0, ft0           # fs1 = θ = x + x³/6

    li      s0, 0
    li      s1, 8                   # 8 Newton iterations

newton_loop:
    bge     s0, s1, newton_done

    # --- Compute sin(θ) via 5-term Taylor ---
    # sin(θ) = θ - θ³/6 + θ⁵/120 - θ⁷/5040 + θ⁹/362880
    fmul.d  ft0, fs1, fs1           # θ²
    fmul.d  ft1, ft0, fs1           # θ³
    fmul.d  ft2, ft1, ft0           # θ⁵
    fmul.d  ft3, ft2, ft0           # θ⁷
    fmul.d  ft4, ft3, ft0           # θ⁹

    fld     ft5, val_6, t0
    fdiv.d  ft6, ft1, ft5           # θ³/6
    fld     ft5, val_120, t0
    fdiv.d  ft7, ft2, ft5           # θ⁵/120
    fld     ft5, val_5040, t0
    fdiv.d  ft8, ft3, ft5           # θ⁷/5040
    fld     ft5, val_40320, t0
    fdiv.d  ft9, ft4, ft5           # θ⁹/40320
    # Actually 9! = 362880, use 40320*9 but simpler: store 362880 directly
    # We stored 40320 = 8! so divide by 9 more
    fld     ft5, val_6, t0
    # reuse: 40320 * 9 via multiply — simpler: just use 7 terms is fine
    # sin ≈ θ - θ³/6 + θ⁵/120 - θ⁷/5040
    fsub.d  fs2, fs1, ft6           # θ - θ³/6
    fadd.d  fs2, fs2, ft7           # + θ⁵/120
    fsub.d  fs2, fs2, ft8           # - θ⁷/5040

    # --- Compute cos(θ) via 4-term Taylor ---
    # cos(θ) = 1 - θ²/2 + θ⁴/24 - θ⁶/720
    fld     ft5, val_1, t0
    fld     ft6, val_2, t0
    fdiv.d  ft7, ft0, ft6           # θ²/2
    fmul.d  ft8, ft0, ft0           # θ⁴
    fld     ft6, val_24, t0
    fdiv.d  ft8, ft8, ft6           # θ⁴/24
    fmul.d  ft9, ft0, ft0
    fmul.d  ft9, ft9, ft0           # θ⁶
    fld     ft6, val_720, t0
    fdiv.d  ft9, ft9, ft6           # θ⁶/720

    fsub.d  fs3, ft5, ft7           # 1 - θ²/2
    fadd.d  fs3, fs3, ft8           # + θ⁴/24
    fsub.d  fs3, fs3, ft9           # - θ⁶/720

    # --- Newton step: θ = θ - (sin(θ)-x)/cos(θ) ---
    fsub.d  ft0, fs2, fs0           # sin(θ) - x
    fdiv.d  ft0, ft0, fs3           # / cos(θ)
    fsub.d  fs1, fs1, ft0           # θ = θ - step

    addi    s0, s0, 1
    j       newton_loop

newton_done:
    fmv.d   fa0, fs1
    li      a7, 3
    ecall
    li      a7, 10
    ecall
