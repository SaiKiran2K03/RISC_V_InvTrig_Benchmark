#!/bin/bash -l
#SBATCH --job-name=riscv_bench
#SBATCH --output=bench_%j.out
#SBATCH --error=bench_%j.err
#SBATCH --nodes=1
#SBATCH --nodelist=node43
#SBATCH --partition=big_compute_amd_9655
#SBATCH --qos=qos_big_compute_amd_9655
#SBATCH --exclusive
#SBATCH --mem=0
#SBATCH --time=01:00:00

# Activate conda environment (which now has its own Java)
conda activate gz2

BENCH_DIR="/home/adas/Sai/risc_benchmarks"
export RARS_PATH="${BENCH_DIR}/rars.jar"
export JAVA_BIN="$(which java)"

cd "${BENCH_DIR}" || exit 1

echo "=============================="
echo "Hijacked Node : $(hostname)"
echo "Using Java at : $(which java)"
echo "Java Version  : $(java -version 2>&1 | head -n 1)"
echo "=============================="

python3 sanity_check.py
python3 benchmark_runner.py
