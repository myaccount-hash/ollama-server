# Ollama Server with Gemma 2 - API Server

このリポジトリは、Dockerを使用してOllamaをAPIサーバーとして構築し、Gemma 2モデルを導入するための構成を提供します。

## 前提条件

- Docker
- Docker Compose

## セットアップ方法

### 方法1: 初期セットアップ（モデルをダウンロードする場合）

初めてOllamaサーバーを構築する場合は、以下の手順でセットアップします。

1. このリポジトリをクローンします。

```bash
git clone <repository-url>
cd ollama-server
```

2. `setup-gemma2.sh`スクリプトを実行して、Ollamaコンテナを起動し、Gemma 2モデルをダウンロードします。

```bash
chmod +x setup-gemma2.sh
./setup-gemma2.sh
```

このスクリプトは以下の処理を行います：
- Dockerコンテナを起動
- Gemma 2モデルをダウンロード
- APIサーバーの動作確認
- 使用方法の説明を表示

### 方法2: カスタムイメージから起動（高速起動）

すでにGemma 2モデルをダウンロード済みのイメージがある場合は、`run-ollama.sh`スクリプトを使用して高速に起動できます。

```bash
chmod +x run-ollama.sh
./run-ollama.sh --image gemma2-ollama:latest
```

オプション:
- `-p, --port PORT`: 使用するポート番号（デフォルト: 11434）
- `-g, --gpu`: GPUを使用する（デフォルト: 使用しない）
- `-i, --image IMAGE`: 使用するイメージ名（デフォルト: gemma2-ollama:latest）
- `-n, --name NAME`: コンテナ名（デフォルト: ollama-server）

例:
```bash
# ポート11435でコンテナを起動
./run-ollama.sh --port 11435

# GPUを使用してコンテナを起動
./run-ollama.sh --gpu
```

## API機能

Ollamaは、HTTP APIでアクセスできるLLMサーバーとして動作します。

### 利用可能なモデルの確認

```bash
curl http://localhost:11434/api/tags
```

### テキスト生成 (Generate API)

単一の入力からテキストを生成します：

```bash
curl -X POST http://localhost:11434/api/generate -d '{
  "model": "gemma2",
  "prompt": "日本の首都は？"
}'
```

### チャット (Chat API)

会話履歴を保持したチャットを行います：

```bash
curl -X POST http://localhost:11434/api/chat -d '{
  "model": "gemma2",
  "messages": [
    {"role": "user", "content": "こんにちは"},
    {"role": "assistant", "content": "こんにちは！どのようにお手伝いできますか？"},
    {"role": "user", "content": "日本の首都について教えてください"}
  ]
}'
```

### 埋め込みベクトル生成 (Embeddings API)

テキストの埋め込みベクトルを生成します：

```bash
curl -X POST http://localhost:11434/api/embeddings -d '{
  "model": "gemma2",
  "prompt": "日本の首都は東京です"
}'
```

## OpenAI互換API

Ollamaは、OpenAI互換の API エンドポイントも提供しています：

```bash
curl -X POST http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma2",
    "messages": [
      {"role": "system", "content": "あなたは役立つアシスタントです。"},
      {"role": "user", "content": "日本の首都は？"}
    ]
  }'
```

## 外部アクセスの設定

デフォルトでは、Ollamaサーバーは外部からのアクセスを許可するように設定されています。環境変数で設定しています：

```
OLLAMA_HOST=0.0.0.0  # すべてのネットワークインターフェースでリッスン
OLLAMA_ORIGINS=*     # すべてのオリジンからのアクセスを許可
```

セキュリティを強化するには、`OLLAMA_ORIGINS`の値を特定のIPアドレスやドメインに制限することをお勧めします。

## 使用方法

### コマンドラインで対話

Gemma 2モデルと対話するには、以下のコマンドを実行します：

```bash
docker exec -it ollama-server ollama run gemma2
```

### APIを使用

APIを通じてGemma 2モデルとやり取りするには、以下のcurlコマンドを使用します：

```bash
curl -X POST http://localhost:11434/api/generate -d '{"model": "gemma2", "prompt": "あなたの質問をここに入力"}'
```

### APIテストスクリプト

このリポジトリには、Ollamaサーバーに対して様々な方法でリクエストを送信するテストスクリプト `test-ollama.py` が含まれています。

使用方法：
```bash
# 仮想環境のセットアップ（初回のみ）
python3 -m venv venv
source venv/bin/activate
pip install requests openai

# スクリプト実行
python3 test-ollama.py [--model モデル名] [--prompt プロンプト] [--api {direct,openai,both}]
```

オプション：
- `--model`: 使用するモデル名（デフォルト: gemma2:2b）
- `--prompt`: 送信するプロンプト（デフォルト: こんにちは、あなたは何ができますか？）
- `--api`: 使用するAPI（direct: 直接API, openai: OpenAI互換API, both: 両方）

例：
```bash
python3 test-ollama.py --model gemma2:2b --prompt "AIの可能性について説明してください" --api direct
```

## ディレクトリ構造

- `docker-compose-custom.yml`: カスタムイメージを使用するためのコンテナ設定ファイル（参照用）
- `run-ollama.sh`: Ollamaコンテナをカスタム設定で起動するスクリプト
- `setup-gemma2.sh`: 初期セットアップスクリプト
- `test-ollama.py`: APIテストスクリプト
- `ollama-data/`: Ollamaのデータディレクトリ（モデルやキャッシュが保存される）

## コンテナの管理

コンテナの管理には以下のスクリプトを使用します：

- コンテナを起動する：`./run-ollama.sh [オプション]`
- コンテナを停止する：`docker stop ollama-server`
- コンテナを削除する：`docker rm ollama-server`
- ログを確認する：`docker logs ollama-server`

詳細なオプションについては、`./run-ollama.sh --help`を参照してください。

## カスタムイメージの作成と利用

### コンテナからイメージを作成

Gemma 2モデルをダウンロード済みのコンテナからイメージを作成することで、再起動時にモデルを再ダウンロードする必要がなくなります。

```bash
# 実行中のコンテナをイメージとして保存
docker commit ollama-server gemma2-ollama:latest

# イメージの確認
docker images | grep gemma2
```

### カスタムイメージの使用

作成したイメージは、以下の方法で使用できます：

1. `run-ollama.sh`スクリプトを使用する方法（推奨）：

```bash
./run-ollama.sh --image gemma2-ollama:latest
```

2. 参照用の`docker-compose-custom.yml`を使用する方法：

```bash
docker compose -f docker-compose-custom.yml up -d
```

### イメージのエクスポートとインポート

別のマシンで使用するためにイメージをファイルとしてエクスポート/インポートできます。

```bash
# イメージをファイルにエクスポート
docker save gemma2-ollama:latest -o gemma2-ollama.tar

# イメージをファイルからインポート
docker load -i gemma2-ollama.tar
```

## GPUサポート

GPUを使用するには、以下のコマンドでコンテナを起動します：

```bash
./run-ollama.sh --gpu
```

これにより、NVIDIA GPUがある環境では自動的にGPUが有効になります。

## 他のPCでの利用方法

このリポジトリで構築したOllamaサーバーのイメージは、DockerHubに公開されており、他のPCで簡単に利用できます。

### 1. 最小限の手順で起動（他のPC）

以下の手順で他のPCでもOllamaサーバーを簡単に起動できます：

1. リポジトリをクローン
```bash
git clone <repository-url>
cd ollama-server
```

2. スクリプトに実行権限を付与
```bash
chmod +x run-ollama.sh
```

3. 実行（ポートのみ指定）
```bash
./run-ollama.sh --port 11434
```

このスクリプトは自動的に以下を実行します：
- DockerHubからイメージをプル（shota126/ollama-server:latest）
- 指定されたポートでコンテナを起動
- APIの動作確認

### 2. GPUを使用する場合

GPUを使用する場合は、単に`--gpu`オプションを追加するだけです：

```bash
./run-ollama.sh --port 11434 --gpu
```

### 3. カスタムイメージを使用する場合

DockerHubの別のイメージを使用する場合は、以下のようにイメージを指定できます：

```bash
./run-ollama.sh --image username/imagename:tag
```

これにより、どのPCでも簡単に同じOllamaサーバー環境を構築できます。

## 参考リンク

- [Ollama公式Docker Hub](https://hub.docker.com/r/ollama/ollama)
- [Ollama API ドキュメント](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Ollama公式ドキュメント](https://github.com/ollama/ollama)
- [Gemma 2モデル情報](https://ollama.com/library/gemma2) 