import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import itertools

# データの読み込み（ファイル名を適宜変更）
file_name = "scaling_analyzer_output.txt"  # 実際のデータファイル名に置き換え
df = pd.read_csv(file_name, delim_whitespace=True)

# number_cpu / MPI_task の計算
df["cpu_per_mpi"] = df["number_cpu"] / df["MPI_task"]

# atoms_per_cpu と number_gpu ごとにデータをグループ化
grouped = df.groupby(["atoms_per_cpu", "number_gpu"])

# 色とマーカーのリスト（matplotlib のデフォルトカラーとマーカーを使用）
colors = itertools.cycle(plt.cm.tab10.colors)  # 10色のカラーマップ
markers = itertools.cycle(["o", "s", "D", "^", "v", "p", "*", "X"])  # 8種類のマーカー

# atoms_per_cpu ごとに異なる色を割り当てる
atoms_per_cpu_colors = {atoms_per_cpu: next(colors) for atoms_per_cpu in df["atoms_per_cpu"].unique()}

# プロット設定
plt.figure(figsize=(10, 6))

# プロット用の凡例を管理
legend_handles = []

for (atoms_per_cpu, gpu), group in grouped:
    # number_cpu / MPI_task でソート
    group = group.sort_values("cpu_per_mpi")

    # 色とマーカーの決定
    color = atoms_per_cpu_colors[atoms_per_cpu]  # atoms_per_cpu に対して一意の色を使用
    marker = next(markers)  # number_gpu ごとに異なるマーカーを使用

    # **プロット**
    handle, = plt.plot(
        group["cpu_per_mpi"], group["timesteps/s"], 
        marker=marker, linestyle="-", color=color, label=f"atoms_per_cpu={atoms_per_cpu}, GPU={gpu}"
    )
    
    # 凡例管理（同じ `atoms_per_cpu` の `GPU` 変化のみで異なるマーカーを使用）
    legend_handles.append((handle, f"atoms_per_cpu={atoms_per_cpu}, GPU={gpu}"))

# 軸ラベルとスケール設定
plt.xlabel("number_cpu / MPI_task")
plt.ylabel("timesteps/s")
plt.xscale("log")  # 横軸を対数スケール
plt.yscale("log")  # 縦軸も対数スケール（スケールが広いため）
plt.grid(True, which="both", linestyle="--", alpha=0.7)
plt.title("Scaling Analysis: timesteps/s vs number_cpu/MPI_task (atoms_per_cpu & GPU fixed)")

# **凡例（グラフの外側に配置）**
plt.legend([h[0] for h in legend_handles], [h[1] for h in legend_handles], 
           loc='upper left', bbox_to_anchor=(1.05, 1), borderaxespad=0.)

# **レイアウト調整（凡例がグラフと重ならないように）**
plt.tight_layout(rect=[0, 0, 0.8, 1])  # 右側に余白を確保

# グラフを表示
plt.show()

