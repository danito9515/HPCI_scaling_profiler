import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import itertools

# データの読み込み
file_name = "scaling_analyzer_output.txt"  # 実際のデータファイル名に置き換え
df = pd.read_csv(file_name, sep='\s+')

# 数値型に変換
numeric_columns = ["ns/day", "atoms", "number_cpu", "MPI_task", "number_gpu", "atoms_per_cpu"]
df[numeric_columns] = df[numeric_columns].apply(pd.to_numeric, errors='coerce')

# NaN を含む行を削除
df = df.dropna(subset=["ns/day", "MPI_task", "number_cpu", "atoms_per_cpu", "number_gpu"])

# MPI_task がゼロの行を削除
df = df[df["MPI_task"] > 0]

# cpu_per_mpi の計算
df["cpu_per_mpi"] = df["number_cpu"] / df["MPI_task"]

# atoms_per_cpu と number_gpu ごとにデータをグループ化
grouped = df.groupby(["atoms_per_cpu", "number_gpu"])

# 色とマーカーの設定
unique_atoms_per_cpu = sorted(df["atoms_per_cpu"].unique())
unique_number_gpu = sorted(df["number_gpu"].unique())
colors = itertools.cycle(plt.cm.tab10.colors)
markers = itertools.cycle(["o", "s", "D", "^", "v", "p", "*", "X"])

# atoms_per_cpu ごとに異なる色を設定
atoms_per_cpu_colors = {atoms_per_cpu: next(colors) for atoms_per_cpu in unique_atoms_per_cpu}

# number_gpu ごとに異なるマーカーを設定
gpu_markers = {gpu: next(markers) for gpu in unique_number_gpu}

# プロット設定
plt.figure(figsize=(10, 6))

# 凡例管理
legend_handles = []
legend_labels = []

for (atoms_per_cpu, gpu), group in sorted(grouped, key=lambda x: (x[0][0], x[0][1])):
    group = group.sort_values("cpu_per_mpi")
    
    # cpu_per_mpi ごとに平均と標準偏差を計算
    grouped_mean_std = group.groupby("cpu_per_mpi")["ns/day"].agg(["mean", "std"]).reset_index()
    
    # 色とマーカーの決定
    color = atoms_per_cpu_colors[atoms_per_cpu]
    marker = gpu_markers[gpu]
    
    # 平均値とエラーバーをプロット
    handle = plt.errorbar(
        grouped_mean_std["cpu_per_mpi"], grouped_mean_std["mean"], yerr=grouped_mean_std["std"],
        fmt=marker, linestyle="-", color=color, label=f"atoms_per_cpu={atoms_per_cpu}, GPU={gpu}", capsize=3
    )
    
    # 理想スケーリング線の計算
    min_cpu_per_mpi = grouped_mean_std["cpu_per_mpi"].min()
    min_ns_day = grouped_mean_std.loc[grouped_mean_std["cpu_per_mpi"] == min_cpu_per_mpi, "mean"].values[0]
    
    ideal_x = np.array(grouped_mean_std["cpu_per_mpi"])
    ideal_y = min_ns_day * (ideal_x / min_cpu_per_mpi)
    
    # 理想スケーリング線のプロット
    plt.plot(ideal_x, ideal_y, linestyle="--", color=color, alpha=0.7)
    
    legend_handles.append(handle)
    legend_labels.append(f"atoms_per_cpu={atoms_per_cpu}, GPU={gpu}")

# 軸ラベルとスケール設定
plt.xlabel("number_cpu / MPI_task")
plt.ylabel("ns/day")
plt.xscale("log")
plt.yscale("log")
plt.grid(True, which="both", linestyle="--", alpha=0.7)
plt.title("Strong Scaling Analysis: ns/day vs number_cpu/MPI_task with Ideal Scaling")

# 凡例（小さい順にソート）
plt.legend(legend_handles, legend_labels, loc='upper left', bbox_to_anchor=(1.05, 1), borderaxespad=0.)

# レイアウト調整
plt.tight_layout(rect=[0, 0, 0.8, 1])

# グラフを表示
plt.show()
