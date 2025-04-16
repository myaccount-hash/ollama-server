#!/bin/bash

# スクリプトが失敗したらすぐに停止
set -e

echo "Python仮想環境をセットアップします..."

# 仮想環境が既に存在するか確認
if [ -d "venv" ]; then
    echo "既存のvenv環境が見つかりました。"
    read -p "既存の環境を削除して再作成しますか？ (y/n): " answer
    if [ "$answer" = "y" ]; then
        echo "既存のvenv環境を削除します..."
        rm -rf venv
    else
        echo "既存のvenv環境を使用します。"
    fi
fi

# venv環境が存在しない場合は作成
if [ ! -d "venv" ]; then
    echo "新しいPython仮想環境を作成します..."
    python3 -m venv venv
fi

# 仮想環境をアクティベート
echo "仮想環境をアクティベートします..."
source venv/bin/activate

# pipをアップグレード
echo "pipをアップグレードします..."
pip install --upgrade pip

# 依存パッケージをインストール
echo "requirements.txtから依存パッケージをインストールします..."
pip install -r requirements.txt

echo "セットアップが完了しました！"
echo "仮想環境を有効化するには次のコマンドを実行してください: source venv/bin/activate" 