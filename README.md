# Nagara

作業用のLo-fi/Chillネットラジオをメニューバーからひっそり流す、macOS常駐アプリ。再生中もCPU約0.5%（実測平均）で動く軽さを重視している。

## 機能

- 再生/停止（メニューバーから2クリック）
- 7局プリセットの切り替え（Lo-fi / Synthwave / Chillstep のジャンル見出し付き）
- 曲名表示（局がICYメタデータを流している場合）
- 小音量域を広く取った音量スライダー（3乗カーブ・会議中のささやき音量向け）
- メディアキー対応（再生中のみ。停止中はNow Playingの座を明け渡し、AirPods接続時の勝手な自動再生を防ぐ）
- ログイン時自動起動（メニューバーアイコンの右クリック → 設定）

## 動作要件

- macOS 14 (Sonoma) 以降
- ビルドに Swift 6.0 以降のツールチェーン（Xcode不要・Command Line Toolsで完結）

## ビルド/インストール

```sh
git clone https://github.com/nagara-app/nagara.git
cd nagara
./build.sh install
```

`/Applications/Nagara.app` にインストールされ、起動する。更新も同じコマンド（`git pull` してから再実行）。

テストは `swift test` で実行できる。

## 使い方

- **左クリック**: 再生メニュー（チャンネル選択・音量・再生/停止ボタン）
- **右クリック**: 設定（ログイン時に起動・終了）
- チャンネル名をクリックすると再生開始。起動時の自動再生はしない

## チャンネル差し替え

`~/.config/nagara/channels.json` を置くとプリセットを上書きできる。形式例:

```json
[
  {"id": "my-station", "name": "My Station", "url": "https://example.com/stream.mp3", "genre": "Lo-fi"}
]
```

- `genre` は省略可。指定すると、連続する同じ `genre` の塊の先頭にメニューの小見出しが付く
- 注意: URLは**httpsのみ**（httpはmacOSのATSによりブロックされる。アプリ側の検証はなし）

## プリセット7局

| ジャンル | ID | 名前 | ひとこと | URL |
|---|---|---|---|---|
| Lo-fi | coderadio | freeCodeCamp Code Radio | 米プログラミング学習非営利の24/7コーディング用BGM | https://coderadio-admin-v2.freecodecamp.org/listen/coderadio/radio.mp3 |
| Lo-fi | fluxfm-chillhop | FluxFM ChillHop | ベルリンの実局のChillhopチャンネル。320kで外れが少ない | https://streams.fluxfm.de/Chillhop/mp3-320/streams.fluxfm.de/ |
| Lo-fi | bigfm-lofi-focus | bigFM LoFi Focus | ドイツ大手若者局の集中用チャンネル | https://stream.bigfm.de/lofifocus/mp3-128/radiobrowser |
| Lo-fi | nia-lofi | NIA Radio Lo-Fi | ニューカレドニアの局。radio-browser人気上位 | https://radio.nia.nc/radio/8020/lofi-hq-stream.aac |
| Synthwave | nightride-chillsynth | Nightride Chillsynth | 落ち着いたSynthwave（chillsynth）のド定番 | https://stream.nightride.fm/chillsynth.mp3 |
| Synthwave | nightride-datawave | Nightride Datawave | さらに静か・アンビエント寄り。夜作業向き | https://stream.nightride.fm/datawave.mp3 |
| Chillstep | 24dubstep-calmflow | 24Dubstep CalmFlow | ポーランドのdubstep専門局の「静か枠」320k | https://stream.24dubstep.pl/listen/chillstep/mp3_best |

## 実測値（再生中）

- CPU: 約0.5%（10秒間隔×3サンプル平均）
- メモリ: RSS 約51MB

## ライセンス

MIT License
