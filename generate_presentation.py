import json
import os
import csv
import numpy as np
import matplotlib.pyplot as plt

# ── Load Raw Data ─────────────────────────────────────────────────────────────
with open("benchmark_results.json", "r") as f:
    results = json.load(f)

# Create output directory
OUT_DIR = "presentation_assets"
os.makedirs(OUT_DIR, exist_ok=True)

# ── 1. Export Clean CSV for Google Sheets / Excel ──────────────────────────────
def export_csv(func_name):
    # Filter files for the specific function (arcsin or arccos)
    files = [k for k in results.keys() if func_name in k]
    if not files: return
    
    # We assume all files share the same X axis
    x_axis = results[files[0]]["x"]
    
    csv_path = os.path.join(OUT_DIR, f"{func_name}_data.csv")
    with open(csv_path, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        
        # Build Headers
        headers = ["Input (x)"]
        for f in files:
            algo = f.replace(".asm", "").split("_")[1]
            headers.extend([f"{algo}_Error", f"{algo}_Time_ms"])
        writer.writerow(headers)
        
        # Write Rows
        for i, x in enumerate(x_axis):
            row = [x]
            for f in files:
                # Use a try block in case some files failed and have shorter arrays
                try:
                    row.append(results[f]["err"][i])
                    row.append(results[f]["time"][i])
                except IndexError:
                    row.extend(["", ""])
            writer.writerow(row)
            
    print(f"Created Excel-ready file: {csv_path}")

export_csv("arcsin")
export_csv("arccos")

# ── 2. Generate Beautiful Individual PPT Plots ────────────────────────────────
# Presentation styling
plt.rcParams.update({
    "font.size": 14,
    "axes.titlesize": 18,
    "axes.labelsize": 14,
    "lines.linewidth": 2.5,
    "figure.figsize": (10, 6)
})

# Custom colors for each algorithm to keep them consistent
COLORS = {
    "chebyshev": "#e6194b", "cordic": "#3cb44b", "minimax": "#4363d8",
    "newton": "#f58231", "ramirez": "#911eb4", "taylor": "#42d4f4"
}

print("\nGenerating presentation slides...")
for filename, data in results.items():
    if not data["err"]: continue
    
    func = "arcsin" if "arcsin" in filename else "arccos"
    algo = filename.replace(".asm", "").split("_")[1]
    color = COLORS.get(algo, "#000000")
    
    fig, ax = plt.subplots()
    
    # Plot Error (Log Scale)
    ax.plot(data["x"], data["err"], color=color, label=f"{algo.capitalize()} Error")
    ax.fill_between(data["x"], data["err"], 1e-15, color=color, alpha=0.1) # Nice visual shading
    
    ax.set_yscale("log")
    ax.set_ylim(bottom=1e-15, top=1e1) # Lock y-axis so all slides are easily comparable
    
    ax.set_title(f"{func.capitalize()}(x) - {algo.capitalize()} Algorithm", pad=15)
    ax.set_xlabel("Input x")
    ax.set_ylabel("Absolute Error (Log Scale)")
    ax.grid(True, which="major", ls="-", alpha=0.3)
    ax.grid(True, which="minor", ls="--", alpha=0.1)
    
    # Save image
    out_file = os.path.join(OUT_DIR, f"slide_{func}_{algo}.png")
    plt.tight_layout()
    plt.savefig(out_file, dpi=300) # High-res 300 DPI for crisp PPTX viewing
    plt.close()
    
print(f"Done! All presentation assets saved in the '{OUT_DIR}' folder.")
