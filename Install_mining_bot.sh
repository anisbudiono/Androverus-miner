#!/data/data/com.termux/files/usr/bin/bash
set -e
cd "$(dirname "$0")"
termux-wake-lock

pkg update -y && pkg upgrade -y
pkg install -y git clang build-essential curl jq termux-api

echo "⛏️ Mengunduh dan menyusun ccminer..."
git clone https://github.com/veruscoin/ccminer.git ccminer-source
cd ccminer-source && make -j$(nproc) && cp ccminer .. && cd .. && rm -rf ccminer-source
chmod +x ccminer

# Buat konfigurasi Luckpool
cat > config.luckpool.json <<EOF
{
  "url": "stratum+tcp://ap.luckpool.net:3956",
  "user": "RV1xxxxxxxxxxxxxxxxxx.luck",
  "pass": "x"
}
EOF

# Buat konfigurasi Vipor
cat > config.vipor.json <<EOF
{
  "url": "stratum+tcp://vipor.net:3032",
  "user": "RV1xxxxxxxxxxxxxxxxxx.vipor",
  "pass": "x"
}
EOF

# Input Token dan Chat ID
read -p "🔐 Masukkan Bot Token Telegram: " BOT
echo "$BOT" > bot_token.txt
read -p "🆔 Masukkan Chat ID Telegram: " CHAT
echo "$CHAT" > chat_id.txt
read -p "👷 Nama Worker (mis. andro1): " WORKER
echo "$WORKER" > worker_name.txt

# Unduh skrip lain dari GitHub
curl -O https://raw.githubusercontent.com/anisbudiono/androverus-miner/main/start.sh
curl -O https://raw.githubusercontent.com/anisbudiono/androverus-miner/main/bot.sh
curl -O https://raw.githubusercontent.com/anisbudiono/androverus-miner/main/run_all.sh

chmod +x *.sh

echo -e "\n✅ Instalasi selesai. Jalankan:\n./run_all.sh"
