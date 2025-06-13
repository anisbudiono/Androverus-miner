#!/data/data/com.termux/files/usr/bin/bash
set -e
termux-wake-lock
pkg update -y && pkg upgrade -y

echo "📦 Menginstal dependensi..."
pkg install -y git jq curl bc termux-api

echo "🌐 Meng-clone repo mining..."
rm -rf androverus-miner
git clone https://github.com/anisbudiono/androverus-miner.git
cd androverus-miner

echo "🧾 Silakan isi data konfigurasi bot:"
read -p "🔑 Masukkan BOT TOKEN Telegram: " BOT_TOKEN
read -p "🆔 Masukkan CHAT ID Telegram: " CHAT_ID
read -p "👷 Nama Worker: " WORKER

echo "$BOT_TOKEN" > bot_token.txt
echo "$CHAT_ID" > chat_id.txt
echo "$WORKER" > worker_name.txt

echo "✅ Konfigurasi disimpan!"

echo "🚀 Menjalankan mining + bot Telegram..."
bash run_all.sh
