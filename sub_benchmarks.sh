#!/bin/bash
#SBATCH --job-name=riscv_bench
#SBATCH --output=bench_%j.out
#SBATCH --error=bench_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --mem=120G
#SBATCH --time=01:00:00
#SBATCH --partition=big_compute
#SBATCH --qos=qos_big_compute

# ── Environment Setup ────────────────────────────────────────────────────────
source ~/.bashrc
conda activate gz2

# ── Load Java ────────────────────────────────────────────────────────────────
# Standard HPC modules
module load java/17 2>/dev/null || module load openjdk/17 2>/dev/null || module load jdk/17 2>/dev/null

echo "=============================="
echo "HPC ENVIRONMENT INFO"
echo "Job ID      : $SLURM_JOB_ID"
echo "Node        : $(hostname)"
echo "Partition   : $SLURM_JOB_PARTITION"
echo "QOS         : qos_big_compute_amd_9655"
echo "Java        : $(which java)"
echo "=============================="

# ── Execution ────────────────────────────────────────────────────────────────
BENCH_DIR="/home/adas/Sai/risc_benchmarks"
export RARS_PATH="${BENCH_DIR}/rars.jar"
cd "${BENCH_DIR}" || exit 1

# Silent install of tqdm if it's missing
pip install tqdm --quiet 2>/dev/null || true

echo "Running Sanity Check..."
python3 sanity_check.py

echo -e "\nStarting Full Benchmark Suite..."
python3 benchmark_runner.py

echo -e "\n=============================="
echo "Job Complete at $(date)"
echo "=============================="
