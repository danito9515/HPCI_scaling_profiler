#!/bin/bash

# 出力ファイルの定義
output_file="scaling_analyzer_output.txt"
atoms_sorted_file="atoms_sorted.txt"
atoms_per_cpu_sorted_file="atoms_per_cpu_sorted.txt"
cpu_gpu_mpi_sorted_file="cpu_gpu_mpi_sorted.txt"

# 見出しを出力
echo "DIR_NAME        timesteps/s   atoms   number_cpu   MPI_task   number_gpu   atoms_per_cpu" > "$output_file"
echo "DIR_NAME        timesteps/s   atoms   number_cpu   MPI_task   number_gpu   atoms_per_cpu" > "$atoms_sorted_file"
echo "DIR_NAME        timesteps/s   atoms   number_cpu   MPI_task   number_gpu   atoms_per_cpu" > "$atoms_per_cpu_sorted_file"
echo "DIR_NAME        timesteps/s   atoms   number_cpu   MPI_task   number_gpu   atoms_per_cpu" > "$cpu_gpu_mpi_sorted_file"

# 一時ファイルを作成（ソート用）
temp_file=$(mktemp)

# `find` を使ってディレクトリを安全に取得
find . -maxdepth 1 -type d | while read -r done_LMPjob; do
    # ルートディレクトリ `.` をスキップ
    [[ "$done_LMPjob" == "." ]] && continue

    cd "$done_LMPjob" || continue  # ディレクトリが存在しない場合はスキップ

    # 最新の .log ファイルを取得
    LOG_FILE=$(ls -lt *.log 2>/dev/null | grep ^- | awk '{print $9}' | head -1)

    # `.log` ファイルが存在しない場合はスキップ
    [[ -z "$LOG_FILE" ]] && cd ../ && continue

    # データ抽出
    calculation_speed=$(grep "Performance:" "$LOG_FILE" | awk '{print $4}')
    number_atoms=$(grep "Loop" "$LOG_FILE" | awk '{print $12}')
    path=$(pwd)
    dir_name=$(basename "$path")
    number_cpu=$(echo "$dir_name" | sed -E 's/.*cpu([0-9]+).*/\1/')
    number_gpu=$(echo "$dir_name" | sed -E 's/.*gpu([0-9]+).*/\1/' | tail -n 1)
    MPI_task=$(grep "MPI tasks" "$LOG_FILE" | awk '{print $5}')

    # `atoms / number_cpu` を計算（エラー回避のため `number_cpu` が 0 の場合はスキップ）
    [[ -z "$number_cpu" || "$number_cpu" -eq 0 ]] && cd ../ && continue
    atoms_per_cpu=$((number_atoms / number_cpu))

    # ソート用の一時ファイルにデータを書き込む
    printf "%-15s %-12s %-8s %-10s %-10s %-10s %-10s\n" \
        "$dir_name" "$calculation_speed" "$number_atoms" "$number_cpu" "$MPI_task" "$number_gpu" "$atoms_per_cpu" >> "$temp_file"

    cd ../
done

# **(1) 全体のソート (atoms → number_cpu → MPI_task → number_gpu → atoms_per_cpu)**
sort -k3,3n -k4,4n -k5,5n -k6,6n "$temp_file" >> "$output_file"

# **(2) `atoms` が同じデータのみをソートして出力**
awk '
    NR == 1 { print; next }  # 1行目（ヘッダー）はそのまま出力
    { count[$3]++; data[$3] = data[$3] "\n" $0 } 
    END { for (a in count) if (count[a] > 1) print data[a] | "sort -k3,3n -k4,4n -k5,5n -k6,6n" } 
' "$temp_file" >> "$atoms_sorted_file"

# **(3) `atoms / number_cpu` が同じデータのみをソートして出力**
awk '
    NR == 1 { print; next }  # 1行目（ヘッダー）はそのまま出力
    { count[$7]++; data[$7] = data[$7] "\n" $0 } 
    END { for (apc in count) if (count[apc] > 1) print data[apc] | "sort -k7,7n -k3,3n -k4,4n -k5,5n" } 
' "$temp_file" >> "$atoms_per_cpu_sorted_file"

# **(4) `number_cpu`、`MPI_task`、`number_gpu` が同じデータを抽出し、`atoms` 昇順でソート**
awk '
    NR == 1 { print; next }  # 1行目（ヘッダー）はそのまま出力
    { key = $4 OFS $5 OFS $6; count[key]++; data[key] = data[key] "\n" $0 }
    END { for (k in count) if (count[k] > 1) print data[k] | "sort -k4,4n -k5,5n -k6,6n -k3,3n" }
' "$temp_file" >> "$cpu_gpu_mpi_sorted_file"

# 一時ファイルを削除
rm "$temp_file"
