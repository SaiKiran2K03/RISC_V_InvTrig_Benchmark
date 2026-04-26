#!/usr/bin/env python3
"""
benchmark_runner.py — Comprehensive RISC-V Benchmark (Precision, Speed, Size)
"""

import subprocess, math, glob, os, sys, shutil, json, time
from datetime import datetime
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

try:
    from tqdm import tqdm
    HAS_TQDM = True
except ImportError:
    HAS_TQDM = False

# ── Config ───────────────────────────────────────────────────────────────────
RARS_PATH    = os.environ.get("RARS_PATH", "rars.jar")
NUM_POINTS   = 200
TOLERANCE    = 1e-4
TIMEOUT      = 20
LOG_FILE     = "benchmark_progress.log"
RES_JSON     = "benchmark_results.json"
ERR_PNG      = "benchmark_results_error.png"
TIME_PNG     = "benchmark_results_time.png"

def find_java():
    java = os.environ.get("JAVA_BIN")
    if java and os.path.isfile(java): return java
    return shutil.which("java")

JAVA = find_java()

_log_fh = None
def log(msg):
    global _log_fh
    ts = datetime.now().strftime("%H:%M:%S")
    full = f"[{ts}] {msg}"
    print(full, flush=True)
    if _log_fh:
        _log_fh.write(full + "\n")
        _log_fh.flush()

# ── Static Analysis (Size Metrics) ───────────────────────────────────────────
def analyze_asm(filepath):
    """Calculates disk space and executable instruction count."""
    file_size = os.path.getsize(filepath)
    exec_lines = 0
    in_text_section = False
    with open(filepath, 'r') as f:
        for line in f:
            l = line.strip()
            if l == ".text": in_text_section = True
            elif l == ".data": in_text_section = False
            elif in_text_section and l and not l.startswith("#") and not l.startswith(".") and ":" not in l:
                exec_lines += 1
    return file_size, exec_lines

# ── RARS runner (Speed & Precision) ──────────────────────────────────────────
_rars_flags = None

def run_rars(asm_file: str, x: float):
    global _rars_flags
    if JAVA is None: return None, "no_java", 0

    flags_to_try = [_rars_flags] if _rars_flags is not None else ["nc sm", "nc"]
    
    for flags in flags_to_try:
        cmd = f"echo {x:.12f} | {JAVA} -jar {RARS_PATH} {flags} {asm_file}"
        
        start_t = time.perf_counter()
        try:
            proc = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=TIMEOUT)
            end_t = time.perf_counter()
            exec_time_ms = (end_t - start_t) * 1000.0

            for line in proc.stdout.split('\n'):
                line = line.strip()
                if not line: continue
                try:
                    val = float(line)
                    if _rars_flags is None: _rars_flags = flags
                    return val, None, exec_time_ms
                except ValueError: continue
        except subprocess.TimeoutExpired:
            return None, "timeout", 0
        except Exception as e:
            return None, str(e), 0

    return None, "empty", 0

# ── Plotting ──────────────────────────────────────────────────────────────────
PALETTE = ["#e6194b","#3cb44b","#4363d8","#f58231","#911eb4", "#42d4f4","#f032e6","#bfef45","#469990","#9A6324"]

def plot_metric(results: dict, metric_key: str, out_path: str, title: str, ylabel: str, log_scale: bool = False):
    fig, axes = plt.subplots(1, 2, figsize=(18, 7))
    for ax_idx, func in enumerate(["arcsin", "arccos"]):
        ax = axes[ax_idx]
        cidx = 0
        has_data = False
        for fname, data in sorted(results.items()):
            if func not in fname or not data["x"] or not data[metric_key]: continue
            algo = fname.replace(".asm","").split("_",1)[1]
            
            y_data = data[metric_key]
            if metric_key == "time" and len(y_data) > 10:
                y_data = np.convolve(y_data, np.ones(5)/5, mode='same')
                
            ax.plot(data["x"], y_data, label=algo, color=PALETTE[cidx % len(PALETTE)], linewidth=1.8, alpha=0.85)
            cidx += 1
            has_data = True

        if log_scale: ax.set_yscale("log")
        ax.set_title(f"{func}(x)", fontsize=13)
        ax.set_xlabel("Input x", fontsize=11)
        ax.set_ylabel(ylabel, fontsize=11)
        if has_data: ax.legend(loc="upper right" if metric_key == "time" else "upper left", fontsize=9, ncol=2)
        ax.grid(True, which="both", ls="--", alpha=0.4)

    plt.suptitle(title + f"\n{datetime.now().strftime('%Y-%m-%d %H:%M')}", fontsize=14, y=1.01)
    plt.tight_layout()
    plt.savefig(out_path, dpi=150, bbox_inches="tight")
    log(f"Plot saved → {out_path}")

# ── Summary ───────────────────────────────────────────────────────────────────
def print_summary(results: dict, static_info: dict):
    log("\n" + "=" * 90)
    log(f"{'File':<22} | {'Mean Err':>10} | {'Max Err':>10} | {'Mean Latency':>13} | {'Size':>6} | {'Instr'}")
    log("-" * 90)
    for fname, data in sorted(results.items()):
        size_b, instrs = static_info.get(fname, (0,0))
        if not data["err"]:
            log(f"{fname:<22} | {'---':>10} | {'---':>10} | {'---':>13} | {size_b:>5}B | {instrs:>3}")
            continue
        errs, times = data["err"], data["time"]
        mean_err, max_err = np.mean(errs), np.max(errs)
        mean_time = np.mean(times)
        log(f"{fname:<22} | {mean_err:>10.2e} | {max_err:>10.2e} | {mean_time:>10.2f} ms | {size_b:>5}B | {instrs:>3}")
    log("=" * 90)

# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    global _log_fh
    if os.path.exists(LOG_FILE): os.remove(LOG_FILE)
    _log_fh = open(LOG_FILE, "w")

    log("=" * 60)
    log("RISC-V Benchmark Runner (Precision, Speed, Area)")
    log(f"Java : {JAVA or 'NOT FOUND'}")
    log("=" * 60)

    if JAVA is None or not os.path.exists(RARS_PATH):
        log("FATAL: Environment not set up correctly."); sys.exit(1)

    asm_files = sorted(glob.glob("*.asm"))
    static_info = {f: analyze_asm(f) for f in asm_files}
    
    test_points = np.linspace(-0.99, 0.99, NUM_POINTS)
    results = {}

    for asm_file in asm_files:
        log(f"\n>>> {asm_file} (Size: {static_info[asm_file][0]}B, Instrs: {static_info[asm_file][1]})")
        is_acos = "arccos" in asm_file
        errors, times, x_axis = [], [], []

        iterator = tqdm(enumerate(test_points), total=NUM_POINTS, desc=asm_file, leave=True) if HAS_TQDM else enumerate(test_points)

        for i, x in iterator:
            truth = math.acos(x) if is_acos else math.asin(x)
            actual, reason, latency = run_rars(asm_file, x)

            if actual is not None:
                errors.append(abs(actual - truth))
                times.append(latency)
                x_axis.append(x)

        results[asm_file] = {"x": x_axis, "err": errors, "time": times}

    print_summary(results, static_info)
    
    # Dump the new JSON with the time metrics included!
    with open(RES_JSON, "w") as jf:
        json.dump(results, jf, indent=2)
    log(f"\nRaw data saved to {RES_JSON}")

    plot_metric(results, "err", ERR_PNG, "Absolute Error vs Python Math (Lower is Better)", "Log Absolute Error", log_scale=True)
    plot_metric(results, "time", TIME_PNG, "Execution Latency per Input (Lower is Faster)", "Time (Milliseconds)", log_scale=False)
    _log_fh.close()

if __name__ == "__main__":
    main()
