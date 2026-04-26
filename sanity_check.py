#!/usr/bin/env python3
"""
sanity_check.py — 5-point test on every .asm file in current directory.
FAIL (wrong answer) is acceptable — only ERROR (no output) needs fixing.
"""

import subprocess, math, glob, os, sys, shutil

# ── Auto-detect rars.jar ──────────────────────────────────────────────────────
RARS_PATH = os.environ.get("RARS_PATH", "rars.jar")
TEST_INPUTS = [-0.9, -0.5, 0.0, 0.5, 0.9]
TOLERANCE   = 1e-4
TIMEOUT     = 20

# ── Auto-detect java ──────────────────────────────────────────────────────────
def find_java():
    # 1. explicit env var
    java = os.environ.get("JAVA_BIN")
    if java and os.path.isfile(java):
        return java
    # 2. which java
    java = shutil.which("java")
    if java:
        return java
    # 3. common HPC module paths
    for candidate in [
        "/usr/lib/jvm/java-17-openjdk-amd64/bin/java",
        "/usr/lib/jvm/java-11-openjdk-amd64/bin/java",
        "/usr/local/bin/java",
    ]:
        if os.path.isfile(candidate):
            return candidate
    return None

JAVA = find_java()

def run_rars(asm_file, x):
    if JAVA is None:
        return None, "no_java"
    if not os.path.exists(RARS_PATH):
        return None, "no_rars"
    # Try both flag styles RARS uses
    for flags in ["nc sm", "nc"]:
        cmd = f"echo {x:.10f} | {JAVA} -jar {RARS_PATH} {flags} {asm_file}"
        try:
            proc = subprocess.run(cmd, shell=True, capture_output=True,
                                  text=True, timeout=TIMEOUT)
            for line in proc.stdout.split('\n'):
                line = line.strip()
                if not line:
                    continue
                try:
                    return float(line), None
                except ValueError:
                    continue
        except subprocess.TimeoutExpired:
            return None, "timeout"
        except Exception as e:
            return None, str(e)
    return None, "empty"

# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    print(f"Java : {JAVA or 'NOT FOUND'}")
    print(f"RARS : {RARS_PATH} ({'found' if os.path.exists(RARS_PATH) else 'NOT FOUND'})")
    print()

    if JAVA is None:
        print("ERROR: java not found. Set JAVA_BIN=/path/to/java or load java module.")
        sys.exit(1)
    if not os.path.exists(RARS_PATH):
        print(f"ERROR: {RARS_PATH} not found. Set RARS_PATH env var.")
        sys.exit(1)

    # Quick java+rars smoke test
    try:
        smoke = subprocess.run(
            f"{JAVA} -jar {RARS_PATH} --help",
            shell=True, capture_output=True, text=True, timeout=10
        )
        if smoke.returncode not in (0, 1):   # RARS returns 1 on --help
            print(f"WARNING: RARS smoke test returned {smoke.returncode}")
            print("stderr:", smoke.stderr[:200])
    except Exception as e:
        print(f"WARNING: smoke test failed: {e}")

    asm_files = sorted(glob.glob("*.asm"))
    if not asm_files:
        print("No .asm files found.")
        sys.exit(1)

    HDR = f"{'X Value':<8} | {'Algorithm':<14} | {'Function':<8} | {'Expected':>10} | {'Actual':>10} | Status"
    SEP = "-" * 85
    print(HDR); print(SEP)

    pass_c = fail_c = err_c = 0

    for asm_file in asm_files:
        base  = asm_file.replace(".asm", "")
        parts = base.split("_", 1)
        if len(parts) != 2:
            continue
        func_type, algo_name = parts

        for x in TEST_INPUTS:
            expected = math.acos(x) if func_type == "arccos" else math.asin(x)
            actual, err_reason = run_rars(asm_file, x)

            if actual is None:
                status = f"ERROR ({err_reason})"
                actual_str = "N/A"
                err_c += 1
            else:
                diff = abs(actual - expected)
                if diff < TOLERANCE:
                    status = "PASS";  pass_c += 1
                else:
                    status = f"FAIL ({diff:.2e})"; fail_c += 1
                actual_str = f"{actual:.6f}"

            print(f"{x:<8.4f} | {algo_name:<14} | {func_type:<8} | "
                  f"{expected:>10.6f} | {actual_str:>10} | {status}")

    print(SEP)
    total = pass_c + fail_c + err_c
    print(f"\nSummary: {pass_c}/{total} PASS | {fail_c} FAIL (expected) | {err_c} ERROR")
    if err_c == 0:
        print("✓ No errors — ready for full benchmark.")
    else:
        print("✗ ERRORs present — java/rars not working on this node.")

if __name__ == "__main__":
    main()
