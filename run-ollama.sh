#!/bin/bash

# デフォルト値
PORT=11434
USE_GPU=false
IMAGE="ollama/ollama:latest"  # デフォルトを公式イメージに変更
CONTAINER_NAME="ollama-server"
PULL_IMAGE=true
DOCKER_COMPOSE_FILE="docker-compose.yml"  # docker-compose.ymlに変更
MODEL_TO_PULL="tinyllama"  # 自動的にプルするモデル

# ヘルプメッセージ
show_help() {
  echo "使用方法: $0 [オプション]"
  echo "オプション:"
  echo "  -p, --port PORT        使用するポート番号（デフォルト: 11434）"
  echo "  -g, --gpu              GPUを使用する（デフォルト: 使用しない）"
  echo "  -i, --image IMAGE      使用するイメージ名（デフォルト: ollama/ollama:latest）"
  echo "  -n, --name NAME        コンテナ名（デフォルト: ollama-server）"
  echo "  --no-pull              イメージを自動的にプルしない"
  echo "  -m, --model MODEL      自動的にプルするモデル（デフォルト: tinyllama）"
  echo "  -h, --help             このヘルプメッセージを表示"
  echo ""
  echo "例:"
  echo "  $0 --port 11435 --gpu  # ポート11435でGPUを使用してOllamaを起動"
  exit 1
}

# コマンドライン引数の解析
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--port)
      PORT="$2"
      shift 2
      ;;
    -g|--gpu)
      USE_GPU=true
      shift
      ;;
    -i|--image)
      IMAGE="$2"
      shift 2
      ;;
    -n|--name)
      CONTAINER_NAME="$2"
      shift 2
      ;;
    --no-pull)
      PULL_IMAGE=false
      shift
      ;;
    -m|--model)
      MODEL_TO_PULL="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "エラー: 不明なオプション '$1'"
      show_help
      ;;
  esac
done

# 設定の出力
echo "Ollamaコンテナを以下の設定で起動します："
echo "- ポート: $PORT"
echo "- GPU使用: $([ "$USE_GPU" = true ] && echo "有効" || echo "無効")"
echo "- Docker Composeファイル: $DOCKER_COMPOSE_FILE（固定）"
echo "- 自動プルするモデル: $MODEL_TO_PULL"
echo ""

# ポート番号をDocker Composeファイルに反映
if [ "$PORT" != "11434" ]; then
  echo "Docker Composeファイルのポート設定を $PORT に更新しています..."
  # sed を使用してポート番号を置換
  sed -i.bak "s/- \"[0-9]*:11434\"/- \"$PORT:11434\"/" "$DOCKER_COMPOSE_FILE"
  rm -f "${DOCKER_COMPOSE_FILE}.bak"  # バックアップファイルを削除
fi

# GPUフラグが有効の場合、Docker Composeファイルでコメントアウトされたリソース設定を有効化
if [ "$USE_GPU" = true ]; then
  echo "Docker ComposeファイルでGPUサポートを有効化しています..."
  # コメントを解除
  sed -i.bak 's/# deploy:/deploy:/' "$DOCKER_COMPOSE_FILE"
  sed -i.bak 's/#   resources:/  resources:/' "$DOCKER_COMPOSE_FILE"
  sed -i.bak 's/#     reservations:/    reservations:/' "$DOCKER_COMPOSE_FILE"
  sed -i.bak 's/#       devices:/      devices:/' "$DOCKER_COMPOSE_FILE"
  sed -i.bak 's/#         - driver: nvidia/        - driver: nvidia/' "$DOCKER_COMPOSE_FILE"
  sed -i.bak 's/#           count: 1/          count: 1/' "$DOCKER_COMPOSE_FILE"
  sed -i.bak 's/#           capabilities: \[gpu\]/          capabilities: [gpu]/' "$DOCKER_COMPOSE_FILE"
  rm -f "${DOCKER_COMPOSE_FILE}.bak"  # バックアップファイルを削除
fi

# 既存のコンテナを停止・削除
if docker ps -a | grep -q "$CONTAINER_NAME"; then
  echo "既存のコンテナを停止・削除しています..."
  docker stop "$CONTAINER_NAME" >/dev/null
  docker rm "$CONTAINER_NAME" >/dev/null
fi

# Docker Composeでコンテナを起動
echo "Docker Composeを使用してコンテナを起動しています..."
if ! docker-compose -f "$DOCKER_COMPOSE_FILE" up -d; then
  echo "Docker Composeでの起動に失敗しました。エラーを確認してください。"
  exit 1
fi

# 起動確認
if docker ps | grep -q "$CONTAINER_NAME"; then
  echo "コンテナが正常に起動しました！"
  echo "APIエンドポイント: http://localhost:$PORT"
  echo ""
  
  # APIの応答確認
  echo "API応答を確認中..."
  sleep 3
  curl -s "http://localhost:$PORT/api/tags" | jq '.' || echo "APIの確認に失敗しました。コンテナのログを確認してください。"

  # モデルの自動プル
  if [ -n "$MODEL_TO_PULL" ]; then
    echo ""
    echo "モデル $MODEL_TO_PULL を自動的にプルしています..."
    curl -X POST "http://localhost:$PORT/api/pull" -d "{\"name\": \"$MODEL_TO_PULL\"}" || echo "モデルのプルに失敗しました。"
    
    # モデルのプル完了を確認
    echo "モデルのプル完了を確認中..."
    for i in {1..10}; do
      sleep 5
      if curl -s "http://localhost:$PORT/api/tags" | grep -q "$MODEL_TO_PULL"; then
        echo "モデル $MODEL_TO_PULL のプルが完了しました！"
        break
      fi
      if [ $i -eq 10 ]; then
        echo "モデルのプル完了確認がタイムアウトしました。バックグラウンドでダウンロードが継続している可能性があります。"
      fi
    done
  fi
  
  # APIテスト方法のガイダンス表示（簡潔版）
  echo ""
  echo "========================================================"
  echo "📋 APIテスト方法："
  echo "========================================================"
  echo "1. $ ./setup-venv.sh                  # 環境セットアップ"
  echo "2. $ python test-ollama.py            # APIテスト実行"
  echo ""
  echo "他のデバイスからは http://$(hostname -I | awk '{print $1}'):$PORT でアクセス可能"
  echo "========================================================"
else
  echo "コンテナの起動に失敗しました。"
  echo "ログを確認してください: docker-compose -f $DOCKER_COMPOSE_FILE logs"
fi 