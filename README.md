# Ollama Server - APIサーバー

このリポジトリは、Dockerを使用してOllamaをAPIサーバーとして構築するためのシンプルな構成を提供します。

## クイックスタート

```bash
# 1. このリポジトリをクローン
git clone <repository-url>
cd ollama-server

# 2. 実行権限を付与
chmod +x run-ollama.sh setup-venv.sh

# 3. Ollamaサーバーを起動
./run-ollama.sh
```

## 主なコンポーネント

- `run-ollama.sh`: Docker Composeを使用してOllamaコンテナを自動的に起動し、tinyllamaモデルをプル
- `setup-venv.sh`: Python仮想環境のセットアップ（APIテスト用）
- `test-ollama.py`: Ollamaサーバー動作確認用テストスクリプト

## スクリプト実行オプション

### run-ollama.sh

```bash
./run-ollama.sh [オプション]
```

オプション:
- `-p, --port PORT`: ポート番号（デフォルト: 11434）
- `-g, --gpu`: GPU有効化
- `-m, --model MODEL`: 自動プルするモデル（デフォルト: tinyllama）

### test-ollama.py

```bash
source venv/bin/activate  # 仮想環境を有効化
python test-ollama.py [オプション]
```

オプション:
- `--model`: モデル名（デフォルト: tinyllama）
- `--prompt`: プロンプト
- `--port`: ポート番号 