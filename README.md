# Nagara

作業用のLo-fi/Chillネットラジオをメニューバーからひっそり流す、macOS常駐アプリ。再生中もCPU約0.5%（実測平均）で動く軽さを重視している。

## 機能

- 再生/停止（メニューバーから2クリック）
- 5局プリセットの切り替え
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
  {"id": "lautfm-lofi", "name": "laut.fm Lofi", "url": "https://lofi.stream.laut.fm/lofi"}
]
```

注意: URLは**httpsのみ**（httpはmacOSのATSによりブロックされる。アプリ側の検証はなし）。

## プリセット5局

| ID | 名前 | URL |
|---|---|---|
| lautfm-lofi | laut.fm Lofi | https://lofi.stream.laut.fm/lofi |
| coderadio | freeCodeCamp Code Radio | https://coderadio-admin-v2.freecodecamp.org/listen/coderadio/radio.mp3 |
| fluxfm-chillhop | FluxFM ChillHop | https://streams.fluxfm.de/Chillhop/mp3-320/streams.fluxfm.de/ |
| lautfm-lofi-radio | laut.fm Lofi Radio | https://lofi-radio.stream.laut.fm/lofi-radio |
| bigfm-lofi-focus | bigFM LoFi Focus | https://stream.bigfm.de/lofifocus/mp3-128/radiobrowser |

## 実測値（再生中）

- CPU: 約0.5%（10秒間隔×3サンプル平均）
- メモリ: RSS 約51MB

## ライセンス

MIT License
