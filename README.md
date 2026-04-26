# Evaluating Arcsin and Arccos Implementations on RV64: A Benchmark of Precision, Speed, and Area

This repository contains a comprehensive benchmarking suite for inverse trigonometric functions (`arcsin` and `arccos`) implemented in pure 64-bit RISC-V assembly (RV64IMAFD). 

The goal of this project is to evaluate the inherent trade-offs between mathematical precision, execution latency (clock cycles), and memory footprint across six distinct algorithmic approaches in hardware.

## 🧮 Algorithms Evaluated
We have implemented and evaluated the following 6 algorithms using IEEE 754 Double Precision Floating-Point arithmetic:

1. **Minimax Polynomial:** Optimized polynomial approximation for minimum maximum error.
2. **Chebyshev Polynomial:** Truncated polynomial series using FMA instructions.
3. **Ramirez (Rational Polynomial):** A high-performance rational polynomial approximation.
4. **Newton-Raphson:** Iterative root-finding method.
5. **CORDIC:** Iterative coordinate rotation using bit-shifts and additions.
6. **Taylor / Maclaurin Series:** Pure mathematical expansion (100 iterations).

## ⚙️ System Model & Methodology
- **Target Architecture:** 64-bit RISC-V (RV64)
- **Simulation Environment:** RARS (RISC-V Assembler and Runtime Simulator)
- **Host System:** HPC Cluster (node43)
- **Benchmarking Script:** Python-driven subprocess orchestration
- **Input Domain:** 200 equidistant data points sampled across the range `[-0.99, 0.99]`.
- **Ground Truth:** Python's native 64-bit `math.asin()` and `math.acos()` functions.

## 📊 Summary of Findings
Below is a high-level summary of the performance vs. precision trade-offs observed during benchmarking. 

| Algorithm | Est. Cycles | Speed Rank | Mean Abs. Error | Max Abs Error | TL;DR Summary |
| :--- | :--- | :---: | :--- | :--- | :--- |
| **Minimax** | ~120 | 1st | 5.0e-3 | 2.1e-2 | Pure speed; flattens max error. |
| **Chebyshev** | ~160 | 2nd | 5.3e-3 | 1.1e-1 | Fast FMA; loses accuracy at edges. |
| **Ramirez** | ~220 | 3rd | 2.9e-5 | 6.3e-5 | **Best overall;** fast & highly stable. |
| **Newton** | 600-850 | 4th | 1.2e-5 | 4.8e-4 | High precision; variable latency. |
| **CORDIC** | ~2,200 | 5th | 6.3e-3 | 9.6e-2 | Hardware-friendly bit-shifts. |
| **Taylor** | ~10.5k | 6th | 1.2e-5 | 1.1e-3 | Too slow; wasteful 100-loop brute force. |

*Note: Execution latency was evaluated by charting absolute execution time and modeling pure pipeline clock cycles.*

## 📂 Project Structure
```text
├── assembly_files/
│   ├── arcsin_taylor.asm
│   ├── arcsin_cordic.asm
│   └── ... (arccos variants)
├── benchmark_runner.py       # Main python orchestration script
├── generate_presentation.py  # Script to convert JSON results to plots & CSVs
├── benchmark_results.json    # Raw output data from the benchmark suite
└── README.md
