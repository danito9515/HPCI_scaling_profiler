# Scaling Analyzer Script

## 概要
このスクリプトは、計算シミュレーションのスケーリングデータを解析し、整理するためのものです。
ディレクトリ内の `.log` ファイルから情報を抽出し、異なる条件ごとにソートして複数の出力ファイルを作成します。

## 出力ファイル
| ファイル名 | 内容 |
|------------|------|
| `scaling_analyzer_output.txt` | 全体のデータを整理した結果 |
| `atoms_sorted.txt` | `atoms` (原子数) ごとにソートした結果 |
| `atoms_per_cpu_sorted.txt` | `atoms_per_cpu` ごとにソートした結果 |
| `cpu_gpu_mpi_sorted.txt` | `number_cpu`, `MPI_task`, `number_gpu` が同じデータを抽出し、 `atoms` 昇順でソート |

## 動作手順
1. `.log` ファイルを含む各ディレクトリを検索
2. 各ディレクトリの最新の `.log` ファイルから以下のデータを抽出
   - `timesteps/s`: 計算速度
   - `atoms`: 原子数
   - `number_cpu`: CPU数 (ディレクトリ名から取得)
   - `MPI_task`: MPIタスク数 (`.log` ファイルから取得)
   - `number_gpu`: GPU数 (ディレクトリ名から取得)
   - `atoms_per_cpu`: `atoms / number_cpu` の計算値
3. 取得したデータをソートして複数の出力ファイルに保存

## 詳細な処理内容
### 1. データの取得
- `find` コマンドを使用して、現在のディレクトリ内のサブディレクトリを取得。
- 各ディレクトリ内の最新の `.log` ファイルを特定し、必要なデータを抽出。
- ディレクトリ名から `number_cpu` と `number_gpu` を取得。
- `atoms / number_cpu` を計算。

### 2. データのソートと保存
1. **全体のデータを整理し保存 (`scaling_analyzer_output.txt`)**
   - `atoms` → `number_cpu` → `MPI_task` → `number_gpu` → `atoms_per_cpu` の順にソート
2. **`atoms` が同じデータのみをソート (`atoms_sorted.txt`)**
   - `atoms` が同じデータを抽出し、 `number_cpu` → `MPI_task` → `number_gpu` の順にソート
3. **`atoms_per_cpu` が同じデータのみをソート (`atoms_per_cpu_sorted.txt`)**
   - `atoms_per_cpu` が同じデータを抽出し、 `atoms` → `number_cpu` → `MPI_task` の順にソート
4. **`number_cpu`, `MPI_task`, `number_gpu` が同じデータを抽出 (`cpu_gpu_mpi_sorted.txt`)**
   - `number_cpu`, `MPI_task`, `number_gpu` が同じデータを抽出し、 `atoms` 昇順でソート

## 使用方法
このスクリプトを `bash` で実行すると、自動的に解析が行われ、結果が出力ファイルに保存されます。
```sh
bash scaling_analyzer.sh
```

## 注意点
- `.log` ファイルが存在しないディレクトリはスキップされます。
- `number_cpu` が `0` の場合、計算をスキップしてエラーを回避します。
- ソートされたデータを確認するには、出力ファイルを開いてください。

## 参考
- `awk`, `sort`, `grep`, `find` などのコマンドを活用しています。
- 一時ファイル (`mktemp`) を使用してデータを一時保存し、処理後に削除します。


