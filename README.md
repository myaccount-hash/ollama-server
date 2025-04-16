# Ollama Server - APIサーバー

このリポジトリは、Dockerを使用してOllamaをAPIサーバーとして構築するためのシンプルな構成を提供します。

## クイックスタート

```bash
# 1. このリポジトリをクローン
git clone https://github.com/myaccount-hash/ollama-server.git
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

### 仮想環境のセットアップとテスト実行

```bash
# 仮想環境をセットアップ
./setup-venv.sh

# スクリプト実行後に自動的にアクティベートされます
# もし新しいターミナルでアクティベートする場合は
source venv/bin/activate  # または ./activate-venv.sh

# APIテスト実行
python test-ollama.py [オプション]
```

オプション:
- `--model`: モデル名（デフォルト: tinyllama）
- `--prompt`: プロンプト
- `--port`: ポート番号

## Pythonでの使用例

### 直接APIを使用する場合

```python
import requests

def query_ollama(prompt, model="tinyllama"):
    url = "http://localhost:11434/api/chat"
    headers = {"Content-Type": "application/json"}
    data = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}]
    }
    
    response = requests.post(url, headers=headers, json=data)
    return response.text

# 使用例
result = query_ollama("こんにちは、今日の天気を教えてください")
print(result)
```

### OpenAI互換APIを使用する場合

```python
from openai import OpenAI

# クライアント初期化
client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama"  # 任意の値でOK
)

# モデル呼び出し
response = client.chat.completions.create(
    model="tinyllama",
    messages=[
        {"role": "system", "content": "あなたは役立つAIアシスタントです。"},
        {"role": "user", "content": "こんにちは、自己紹介をしてください"}
    ]
)

print(response.choices[0].message.content)
``` 