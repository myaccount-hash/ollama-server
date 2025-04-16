#!/bin/bash

# デフォルト値
PORT=11434
USE_GPU=false
IMAGE="shota126/ollama-server:latest"
CONTAINER_NAME="ollama-server"
PULL_IMAGE=true

# ヘルプメッセージ
show_help() {
  echo "使用方法: $0 [オプション]"
  echo "オプション:"
  echo "  -p, --port PORT        使用するポート番号（デフォルト: 11434）"
  echo "  -g, --gpu              GPUを使用する（デフォルト: 使用しない）"
  echo "  -i, --image IMAGE      使用するイメージ名（デフォルト: shota126/ollama-server:latest）"
  echo "  -n, --name NAME        コンテナ名（デフォルト: ollama-server）"
  echo "  --no-pull              イメージを自動的にプルしない"
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
echo "- イメージ: $IMAGE"
echo "- コンテナ名: $CONTAINER_NAME"
echo "- ポート: $PORT"
echo "- GPU使用: $([ "$USE_GPU" = true ] && echo "有効" || echo "無効")"
echo ""

# イメージのプル（ローカルになければ）
if [ "$PULL_IMAGE" = true ]; then
  if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "イメージ $IMAGE がローカルに見つかりません。DockerHubからプルします..."
    if ! docker pull "$IMAGE"; then
      echo "エラー: イメージ $IMAGE のプルに失敗しました。"
      echo "DockerHubにログインしているか確認してください: docker login"
      exit 1
    fi
  else
    echo "イメージ $IMAGE はローカルに存在します。プルをスキップします。"
  fi
fi

# 既存のコンテナを停止・削除
if docker ps -a | grep -q "$CONTAINER_NAME"; then
  echo "既存のコンテナを停止・削除しています..."
  docker stop "$CONTAINER_NAME" >/dev/null
  docker rm "$CONTAINER_NAME" >/dev/null
fi

# コンテナの起動
echo "コンテナを起動しています..."

# GPUを使用するかどうかで起動コマンドを分岐
if [ "$USE_GPU" = true ]; then
  # GPUを使用する場合
  docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "$PORT:11434" \
    -v "$(pwd)/ollama-data:/root/.ollama" \
    -e OLLAMA_HOST=0.0.0.0 \
    -e OLLAMA_ORIGINS="*" \
    --gpus all \
    "$IMAGE"
else
  # GPUを使用しない場合
  docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "$PORT:11434" \
    -v "$(pwd)/ollama-data:/root/.ollama" \
    -e OLLAMA_HOST=0.0.0.0 \
    -e OLLAMA_ORIGINS="*" \
    "$IMAGE"
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
else
  echo "コンテナの起動に失敗しました。"
  echo "ログを確認してください: docker logs $CONTAINER_NAME"
fi 