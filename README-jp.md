ProbeDeformer for iOS
=============
2D 画像を Dual Complex Numbers（反可換二重複素数）で滑らかに変形するための iOS アプリです。

- ライセンス: MIT License
- 動作環境: iOS 13.0 以降, Swift 5+, Xcode 12+
- 依存関係: Eigen（C++ ヘッダライブラリ）

![Video](https://github.com/shizuo-kaji/iPad-ProbeDeformer/blob/master/DCN-ouchi.gif?raw=true)

使い方
-----
上部メニュー

- Image: フォトライブラリから画像を読み込む
- Clear: 全ての制御点をクリアして初期状態に戻す

下部メニュー

- Help: ヘルプ画面（簡易）
- Img|Cam: 「画像」入力と「カメラ」入力を切り替え
- Euc|Har|BiH: 重み方式の選択（Euc: ユークリッド距離の逆二乗, Har: Harmonic, BiH: bi-harmonic）
  - 解析用途では基本的に Euc を使用してください
- DCN|MLS_RIGID|MLS_SIM: 変形方式の選択（推奨: DCN）
- Undo: 直前の操作を取り消す（不安定な場合あり）
- Save: 現在の画像をフォトライブラリに保存し、同時に制御点・解析情報をアプリ内に保存
- Load: 保存済みの制御点情報を読み出す
- Preset: プリセット画像を順に切り替え
- rem: 変形は保持したまま制御点のみ全削除
- 対称スイッチ: 右半分の変形を左半分にも適用（対称変形モード）
- スライダ: 制御点の見かけの大きさを一括変更（左端で非表示）

タッチ操作

- ダブルタップ: 制御点の追加・削除
- ドラッグ: 制御点の移動
- ピンチ: 制御点の影響半径（強さ）の変更
- 二本指回転: 制御点の回転

ヒント: ドラッグ/ピンチを制御点の無い場所で行うと、全ての制御点に一括で適用されます。

データの取り出し（解析用）

- Finder の「ファイル共有」（旧 iTunes のファイル共有）で、保存された CSV / TSV を取り出せます。
- これらのファイルには、制御点の初期位置と変形後の位置などが記録されています。
- ファイル名は保存時刻に基づき自動生成されます。

研究
-----
詳細は以下の論文をご参照ください：

- G. Matsuda, S. Kaji, H. Ochiai, "Anti-commutative Dual Complex Numbers and 2D Rigid Transformation".
  Mathematical Progress in Expressive Image Synthesis I, pp.131–138, Springer, 2014.
  http://link.springer.com/book/10.1007/978-4-431-55007-5
- 更新版: http://arxiv.org/abs/1601.01754

ビルド手順（サブモジュール初期化）
-----
```bash
git submodule update --init --recursive
```

既知の注意
-----
- Undo はまれに不安定な場合があります。
- カメラ使用時はカメラの権限が必要です。
