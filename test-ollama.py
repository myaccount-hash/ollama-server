#!/usr/bin/env python3
"""
Ollamaサーバーに対して様々な方法でリクエストを送信するテストスクリプト
使用方法: python3 test-ollama.py [--model モデル名] [--prompt プロンプト] [--port ポート番号]
"""

import argparse
import json
import requests
import sys

# コマンドライン引数の処理
parser = argparse.ArgumentParser(description="Ollamaサーバーへのリクエストテスト")
parser.add_argument("--model", default="tinyllama", help="使用するモデル名 (デフォルト: tinyllama)")
parser.add_argument("--prompt", default="こんにちは、あなたは何ができますか？", help="送信するプロンプト")
parser.add_argument("--port", default="11434", help="APIサーバーのポート番号 (デフォルト: 11434)")
parser.add_argument("--api", choices=["direct", "openai", "both"], default="both", 
                    help="使用するAPI (direct: 直接API, openai: OpenAI互換API, both: 両方)")
args = parser.parse_args()

# サーバー情報
MODEL = args.model
PROMPT = args.prompt
PORT = args.port
API_SERVER_URL = f"http://localhost:{PORT}/api/chat"
OPENAI_BASE_URL = f"http://localhost:{PORT}/v1"

def test_direct_api():
    """Ollamaの直接APIを使用したテスト"""
    print("\n===== 直接APIリクエスト =====")
    print(f"モデル: {MODEL}")
    print(f"プロンプト: {PROMPT}")
    print(f"ポート: {PORT}")
    
    headers = {"Content-Type": "application/json"}
    data = {
        "model": MODEL,
        "messages": [{
            "role": "user",
            "content": PROMPT,
        }]
    }

    try:
        print("リクエスト送信中...")
        response = requests.post(API_SERVER_URL, headers=headers, json=data)
        response.raise_for_status()
        
        # ストリーミングレスポンスを処理
        print("\n応答:")
        full_response = ""
        for line in response.text.splitlines():
            if line.strip():
                try:
                    data = json.loads(line)
                    if "message" in data and "content" in data["message"]:
                        content = data["message"]["content"]
                        print(content, end="", flush=True)
                        full_response += content
                except json.JSONDecodeError:
                    print(f"解析エラー: {line}")
        
        print("\n")
        return True
    except Exception as e:
        print(f"エラーが発生しました: {e}")
        return False

def test_openai_api():
    """OpenAI互換APIを使用したテスト"""
    try:
        from openai import OpenAI
    except ImportError:
        print("\n===== OpenAIクライアント =====")
        print("OpenAIクライアントライブラリがインストールされていません")
        print("インストールするには: pip install openai")
        return False
    
    print("\n===== OpenAIクライアント =====")
    print(f"モデル: {MODEL}")
    print(f"プロンプト: {PROMPT}")
    print(f"ポート: {PORT}")
    
    client = OpenAI(
        base_url=OPENAI_BASE_URL,
        api_key='ollama',  # 必須だが使用されない
    )

    try:
        print("リクエスト送信中...")
        response = client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": "あなたは役立つAIアシスタントです。"},
                {"role": "user", "content": PROMPT}
            ]
        )
        
        print("\n応答:")
        print(response.choices[0].message.content)
        print("\n")
        return True
    except Exception as e:
        print(f"エラーが発生しました: {e}")
        print("注: Ollamaサーバーが完全なOpenAI互換APIをサポートしているか確認してください。")
        return False

def main():
    success = []
    
    # 常に両方のAPIをテスト
    success.append(test_direct_api())
    success.append(test_openai_api())
    
    # 結果表示
    if all(success):
        print("すべてのテストが成功しました！")
    else:
        print("一部のテストが失敗しました。")
        sys.exit(1)

if __name__ == "__main__":
    main() 