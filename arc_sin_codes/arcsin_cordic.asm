.data
# CORDIC Gain Inverse (1/K) where K approx 1.64676
inv_k:       .double 0.607252935008881256169
val_half:    .double 0.5
val_zero:    .double 0.0

# Atan table: atan(2^-i) for i = 0 to 20
atan_table:
    .double 0.7853981633974483    # i=0
    .double 0.4636476090008061    # i=1
    .double 0.2449786631268641    # i=2
    .double 0.1243549945467614    # i=3
    .double 0.0624188100023962    # i=4
    .double 0.0312398334302683    # i=5
    .double 0.0156237286204768    # i=6
    .double 0.0078123410601011    # i=7
    .double 0.0039062301319670    # i=8
    .double 0.0019531225164788    # i=9
    .double 0.0009765621895593    # i=10
    .double 0.0004882812111948    # i=11
    .double 0.0002441406201494    # i=12
    .double 0.0001220703118937    # i=13
    .double 0.0000610351561742    # i=14
    .double 0.0000305175781155    # i=15
    .double 0.0000152587890613    # i=16
    .double 0.0000076293945311    # i=17
    .double 0.0000038146972656    # i=18
    .double 0.0000019073486328    # i=19
    .double 0.0000009536743164    # i=20

.text
.globl main
main:
    # 1. SILENT INPUT
    li      a7, 7
    ecall
    fmv.d   fs0, fa0                # fs0 = target x

    # 2. INITIALIZE CORDIC
    fld     fs1, inv_k, t0          # x = 1/K
    fld     fs2, val_zero, t0       # y = 0
    fld     fs3, val_zero, t0       # z (angle) = 0
    fld     ft0, val_half, t0       # multiplier to simulate shift (2^-i)
    fld     ft1, val_half, t0       # ft1 will track 2^-i, starts at 2^0=1.0 (set below)
    li      t1, 1
    fcvt.d.w ft1, t1                # ft1 = 1.0 (2^0)

    la      s1, atan_table          # Base address of atan table
    li      s0, 0                   # i = 0
    li      s2, 21                  # Number of iterations

cordic_loop:
    bge     s0, s2, cordic_done

    # Decision: is current y < target x?
    flt.d   t2, fs2, fs0
    
    # Calculate shifts: x_shift = x * 2^-i, y_shift = y * 2^-i
    fmul.d  ft2, fs1, ft1           # x_shift
    fmul.d  ft3, fs2, ft1           # y_shift
    
    # Load atan(2^-i)
    slli    t3, s0, 3
    add     t3, s1, t3
    fld     ft4, 0(t3)              # ft4 = current_atan

    beqz    t2, rotate_negative

rotate_positive:
    fsub.d  fs1, fs1, ft3           # x = x - y_shift
    fadd.d  fs2, fs2, ft2           # y = y + x_shift
    fadd.d  fs3, fs3, ft4           # z = z + atan
    j       loop_end

rotate_negative:
    fadd.d  fs1, fs1, ft3           # x = x + y_shift
    fsub.d  fs2, fs2, ft2           # y = y - x_shift
    fsub.d  fs3, fs3, ft4           # z = z - atan

loop_end:
    fmul.d  ft1, ft1, ft0           # 2^-i = 2^-i * 0.5
    addi    s0, s0, 1
    j       cordic_loop

cordic_done:
    # 3. SILENT OUTPUT
    fmv.d   fa0, fs3
    li      a7, 3
    ecall
    li      a7, 10
    ecall
