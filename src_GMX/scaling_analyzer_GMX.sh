#!/bin/bash

# 出力ファイルの定義
output_file="scaling_analyzer_output.txt"
atoms_sorted_file="atoms_sorted.txt"
atoms_per_cpu_sorted_file="atoms_per_cpu_sorted.txt"
cpu_gpu_mpi_sorted_file="cpu_gpu_mpi_sorted.txt"

# 見出しを出力
header="ns/day  atoms   number_cpu   MPI_task   number_gpu   atoms_per_cpu             DIR_NAME "
echo "$header" > "$output_file"
echo "$header" > "$atoms_sorted_file"
echo "$header" > "$atoms_per_cpu_sorted_file"
echo "$header" > "$cpu_gpu_mpi_sorted_file"

# 一時ファイルを作成（ソート用）
temp_file=$(mktemp)

# `find` を使ってディレクトリを安全に取得
find . -maxdepth 1 -type d | while read -r done_LMPjob; do
    # ルートディレクトリ `.` をスキップ
    [[ "$done_LMPjob" == "." ]] && continue

    cd "$done_LMPjob" || continue  # ディレクトリが存在しない場合はスキップ

    # 最新の .log ファイルを取得
    LOG_FILE=$(ls -lt gmx_tmp_mdrun.log 2>/dev/null | grep ^- | awk '{print $9}' | head -1)

    # `.log` ファイルが存在しない場合はスキップ
    [[ -z "$LOG_FILE" ]] && cd ../ && continue

    # タイムステップを取得
    time_step=$(grep "dt" "$LOG_FILE" | grep = | head -n 1 | awk '{print $3/1000}')

    # 計算速度の計算
    calculation_speed=$(grep Performance "$LOG_FILE" | awk '{print $2}')

    # データ抽出
    number_atoms=$(grep Atoms "$LOG_FILE" | awk '{print $3}')
    path=$(pwd)
    dir_name=$(basename "$path")
    
    # CPU数を抽出
    number_cpu=$(echo "$dir_name" | grep -oP '(?<=cpu)\d+' | head -n 1)
    
    # GPU数を抽出（最後の `gpu` の後の数値を取得）
    number_gpu=$(echo "$dir_name" | grep -oP '(?<=gpu)\d+' | tail -n 1)

    # MPI プロセス数を取得
    MPI_task=$(grep "MPI" "$LOG_FILE" | grep "process" | awk '{print $2}')

    # `atoms / number_cpu` を計算（エラー回避のため `number_cpu` が 0 の場合はスキップ）
    [[ -z "$number_cpu" || "$number_cpu" -eq 0 ]] && cd ../ && continue
    atoms_per_cpu=$((number_atoms / number_cpu))

    # ソート用の一時ファイルにデータを書き込む
    printf " %-12s %-8s %-10s %-10s %-12s %-15s %-10s\n" \
        "$calculation_speed" "$number_atoms" "$number_cpu" "$MPI_task" "$number_gpu" "$atoms_per_cpu" "$dir_name" >> "$temp_file"

    cd ../
done

# **(1) 全体のソート (number_cpu → MPI_task → number_gpu → atoms)**
sort -k4,4n -k5,5n -k6,6n -k3,3n "$temp_file" >> "$output_file"

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
