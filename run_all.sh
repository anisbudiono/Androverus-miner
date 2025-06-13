#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")"
termux-wake-lock

echo "📟 Menjalankan mining dan bot telegram..."

# Jalankan bot dan mining secara paralel
bash bot.sh &
bash start.sh
