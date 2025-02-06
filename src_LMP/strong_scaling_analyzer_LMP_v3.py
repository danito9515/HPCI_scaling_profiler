import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import itertools

# データの読み込み（ファイル名を適宜変更）
file_name = "scaling_analyzer_output.txt"  # 実際のデータファイル名に置き換え
df = pd.read_csv(file_name, delim_whitespace=True)

# number_cpu / MPI_task の計算
df["cpu_per_mpi"] = df["number_cpu"] / df["MPI_task"]

# atoms と number_gpu ごとにデータをグループ化
grouped = df.groupby(["atoms", "number_gpu"])

# 色とマーカーのリスト（matplotlib のデフォルトカラーとマーカーを使用）
colors = itertools.cycle(plt.cm.tab10.colors)  # 10色のカラーマップ
markers = itertools.cycle(["o", "s", "D", "^", "v", "p", "*", "X"])  # 8種類のマーカー

# atoms ごとに異なる色を割り当てる
atoms_colors = {atoms: next(colors) for atoms in df["atoms"].unique()}

# プロット設定
plt.figure(figsize=(10, 6))

# プロット用の凡例を管理
legend_handles = []

for (atoms, gpu), group in grouped:
    # number_cpu / MPI_task でソート
    group = group.sort_values("cpu_per_mpi")

    # 色とマーカーの決定
    color = atoms_colors[atoms]  # atoms ごとに異なる色を使用
    marker = next(markers)  # number_gpu ごとに異なるマーカーを使用

    # **実測値のプロット**
    handle, = plt.plot(
        group["cpu_per_mpi"], group["timesteps/s"], 
        marker=marker, linestyle="-", color=color, label=f"atoms={atoms}, GPU={gpu}"
    )

    # **理想スケーリング線の計算**
    min_cpu_per_mpi = group["cpu_per_mpi"].min()  # 最小の CPU/MPI 値
    min_timestep_s = group.loc[group["cpu_per_mpi"] == min_cpu_per_mpi, "timesteps/s"].values[0]  # 最小点のtimesteps/s

    ideal_x = np.array(group["cpu_per_mpi"])  # X 軸: 実際のデータの x 値を使う
    ideal_y = min_timestep_s * (ideal_x / min_cpu_per_mpi)  # Y 軸: 理想スケール（2倍ずつ増加）

    # **理想スケーリング線のプロット**
    plt.plot(ideal_x, ideal_y, linestyle="--", color=color, alpha=0.7)

    # 凡例管理（同じ `atoms` の `GPU` 変化のみで異なるマーカーを使用）
    legend_handles.append((handle, f"atoms={atoms}, GPU={gpu}"))

# 軸ラベルとスケール設定
plt.xlabel("number_cpu / MPI_task")
plt.ylabel("timesteps/s")
plt.xscale("log")  # 横軸を対数スケール
plt.yscale("log")  # 縦軸も対数スケール（スケールが広いため）
plt.grid(True, which="both", linestyle="--", alpha=0.7)
plt.title("Strong Scaling Analysis: timesteps/s vs number_cpu/MPI_task with Ideal Scaling")

# **凡例（グラフの外側に配置）**
plt.legend([h[0] for h in legend_handles], [h[1] for h in legend_handles], 
           loc='upper left', bbox_to_anchor=(1.05, 1), borderaxespad=0.)

# **レイアウト調整（凡例がグラフと重ならないように）**
plt.tight_layout(rect=[0, 0, 0.8, 1])  # 右側に余白を確保

# グラフを表示
plt.show()

