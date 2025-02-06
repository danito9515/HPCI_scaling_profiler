# LAMMPS（LMP）ジョブスクリプト説明書

## 概要
このスクリプトは、LAMMPS（Large-scale Atomic/Molecular Massively Parallel Simulator）を異なる計算ノードとプロセス数の組み合わせで実行するためのジョブスクリプトを自動生成します。

## スクリプトの機能
1. **ジョブスクリプトのテンプレートを元にジョブスクリプトを生成**
2. **CPUとGPUの異なるノードタイプに対応**
3. **異なるプロセス数、ノード数、入力ファイルに対してスクリプトを生成**
4. **CPU用とGPU用のジョブスクリプトを分けて保存**

## 実行環境
- **計算ノードの種類**
  - CPUノード: `cpu_4`, `cpu_8`, `cpu_16`, `cpu_40`, `cpu_80`, `cpu_160`
  - GPUノード: `gpu_h`, `gpu_1`, `node_o`, `node_q`, `node_h`, `node_f`
- **使用するLMP入力ファイル**
  - `in_128000atm`
  - `in_256000atm`
  - `in_32000atm`
  - `in_64000atm`
- **プロセス数の設定**
  - `1, 2, 4, 8, 16, 24, 40, 48, 80, 96, 160, 192`
- **ノード数の設定**
  - `1, 2`

## 動作の詳細
1. **ディレクトリ作成**
   - `gpu_performance_test`（GPUジョブ用）
   - `cpu_performance_test`（CPUジョブ用）

2. **各ノードタイプに応じたリソース割り当て**
   - CPUノードは`num_cores`を設定
   - GPUノードは`num_gpu`と`num_cores`を設定

3. **ジョブスクリプトの作成**
   - 各ノードタイプ、ノード数、入力ファイル、プロセス数の組み合わせに対し、ジョブスクリプトを生成
   - 変数を置換してスクリプトを作成

4. **ジョブスクリプトの保存**
   - GPUノードの場合は`gpu_performance_test`ディレクトリへ
   - CPUノードの場合は`cpu_performance_test`ディレクトリへ

## 生成されるジョブスクリプトの命名規則
`LMPjob_<プロセス数>np_<コア数>cpu_<GPU数>gpu_<入力ファイル>.sh`

### 例:
```
LMPjob_8np_32cpu_1gpu_in_128000atm.sh
```
- `8np` → プロセス数 8
- `32cpu` → CPUコア数 32
- `1gpu` → GPU数 1
- `in_128000atm` → 使用するLMP入力ファイル

## 実行方法
1. スクリプトを実行
   ```bash
   ./script.sh
   ```
2. 生成されたジョブスクリプトを確認
   ```bash
   ls cpu_performance_test/
   ls gpu_performance_test/
   ```
3. 必要に応じてジョブを投入
   ```bash
   qsub gpu_performance_test/LMPjob_8np_32cpu_1gpu_in_128000atm.sh
   ```

## 注意点
- CPUノードとGPUノードで設定が異なるため、`num_cores` や `num_gpu` の値を適宜確認してください。
- `jobscript_LMP_template.sh` の内容を適切に記述し、必要な変数の置換が正しく行われるようにしてください。
- `bc` コマンドを使用して数値計算を行うため、環境によっては `bc` が必要になります。

## まとめ
このスクリプトは、LAMMPSの計算ジョブを効率的に管理するために設計されています。異なる計算環境でのパフォーマンステストや最適な設定を探るのに便利です。


