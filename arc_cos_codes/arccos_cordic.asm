.data
inv_k:       .double 0.607252935008881256169
val_half:    .double 0.5
val_zero:    .double 0.0
val_pi_half: .double 1.5707963267948966
atan_table:
    .double 0.7853981633974483, 0.4636476090008061, 0.2449786631268641
    .double 0.1243549945467614, 0.0624188100023962, 0.0312398334302683
    .double 0.0156237286204768, 0.0078123410601011, 0.0039062301319670
    .double 0.0019531225164788, 0.0009765621895593, 0.0004882812111948
    .double 0.0002441406201494, 0.0001220703118937, 0.0000610351561742
    .double 0.0000305175781155, 0.0000152587890613, 0.0000076293945311
    .double 0.0000038146972656, 0.0000019073486328, 0.0000009536743164

.text
.globl main
main:
    li      a7, 7
    ecall
    fmv.d   fs0, fa0

    fld     fs1, inv_k, t0
    fld     fs2, val_zero, t0
    fld     fs3, val_zero, t0
    fld     ft0, val_half, t0
    li      t1, 1
    fcvt.d.w ft1, t1

    la      s1, atan_table
    li      s0, 0
    li      s2, 21

cordic_loop:
    bge     s0, s2, cordic_done
    flt.d   t2, fs2, fs0
    fmul.d  ft2, fs1, ft1
    fmul.d  ft3, fs2, ft1
    slli    t3, s0, 3
    add     t3, s1, t3
    fld     ft4, 0(t3)
    beqz    t2, rotate_negative
rotate_positive:
    fsub.d  fs1, fs1, ft3
    fadd.d  fs2, fs2, ft2
    fadd.d  fs3, fs3, ft4
    j       loop_end
rotate_negative:
    fadd.d  fs1, fs1, ft3
    fsub.d  fs2, fs2, ft2
    fsub.d  fs3, fs3, ft4
loop_end:
    fmul.d  ft1, ft1, ft0
    addi    s0, s0, 1
    j       cordic_loop

cordic_done:
    # arccos(x) = pi/2 - arcsin(x)
    fld     ft5, val_pi_half, t0
    fsub.d  fs3, ft5, fs3
    fmv.d   fa0, fs3
    li      a7, 3
    ecall
    li      a7, 10
    ecall
