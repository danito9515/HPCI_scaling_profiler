# 強スケーリング解析スクリプト

## 概要
このスクリプトは、シミュレーションのスケーリングデータを解析し、可視化するためのものです。特に `timesteps/s`（計算速度）と `number_cpu / MPI_task` の関係をプロットし、理想的なスケーリングとの比較を行います。

## 必要なライブラリ
このスクリプトを実行するには、以下の Python ライブラリが必要です。
- `pandas`
- `matplotlib`
- `numpy`
- `itertools`

以下のコマンドで必要なライブラリをインストールできます：
```sh
pip install pandas matplotlib numpy
```

## データの読み込み
スクリプトは `scaling_analyzer_output.txt` というデフォルトのファイルからデータを読み込みます。

```python
file_name = "scaling_analyzer_output.txt"  # 実際のデータファイル名に置き換え
```

データはスペース区切り (`delim_whitespace=True`) で読み込まれます。

## データ処理
1. `number_cpu / MPI_task` を計算し、新しい列 `cpu_per_mpi` を追加。
2. `atoms` と `number_gpu` ごとにデータをグループ化。
3. `cpu_per_mpi` の昇順に並べ替え。

## グラフのプロット
### 色とマーカーの設定
- `atoms` ごとに異なる色を割り当て。
- `number_gpu` ごとに異なるマーカーを割り当て。

### 実測値のプロット
- `cpu_per_mpi` vs `timesteps/s` を `atoms` ごとに異なる色、`GPU` ごとに異なるマーカーでプロット。

### 理想スケーリング線のプロット
- 最小の `cpu_per_mpi` 値 (`min_cpu_per_mpi`) を基準に、理想スケール (`2x` 増加) を計算。
- 実測値と同じ `cpu_per_mpi` を用いて理想スケーリング曲線を描画。

## 軸設定と凡例
- `x` 軸（`cpu_per_mpi`）と `y` 軸（`timesteps/s`）を対数スケールに設定。
- グリッドを追加（`--` スタイル）。
- `atoms` と `number_gpu` に対応する凡例をグラフ外に配置。
- `tight_layout()` を使用して凡例とグラフが重ならないよう調整。

## 実行方法
スクリプトを実行するには、Python 環境で以下のコマンドを実行してください。
```sh
python scaling_analysis.py
```

## 出力
- `timesteps/s` vs `number_cpu / MPI_task` のグラフを表示。
- 実測値と理想スケーリングを比較可能。

## 参考
- `matplotlib` の `plt.cm.tab10.colors` を使用し、`atoms` ごとに異なる色を割り当て。
- `itertools.cycle()` を利用して `number_gpu` ごとに異なるマーカーを設定。
- `tight_layout()` と `bbox_to_anchor` を活用し、凡例の配置を最適化。


