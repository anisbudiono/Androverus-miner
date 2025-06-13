#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")"
termux-wake-lock

rotate_log() {
  TODAY=$(date +%Y%m%d)
  DAILY_LOG="miner_$TODAY.log"

  if [ -f "miner.log" ]; then
    mv miner.log "$DAILY_LOG"
  fi

  COUNT=$(ls -1 miner_*.log 2>/dev/null | wc -l)
  if [ "$COUNT" -gt 30 ]; then
    TO_DELETE=$((COUNT - 30))
    ls -1t miner_*.log | tail -n "$TO_DELETE" | xargs rm -f
  fi
}

run_ccminer() {
  CONFIG="$1"
  rotate_log
  ./ccminer -c "$CONFIG" > miner.log 2>&1 &
  echo $! > ccminer.pid
  echo $(date +%s) > mining_start_time.txt
}

monitor_miner() {
  CONFIG="$1"
  while sleep 10; do
    PID=$(cat ccminer.pid 2>/dev/null)
    if ! ps -p "$PID" > /dev/null; then
      echo "❌ ccminer berhenti. Ganti pool..."
      return 1
    fi

    if ! grep -q "accepted" miner.log; then
      ELAPSED=$(($(date +%s) - $(stat -c %Y miner.log)))
      if [ "$ELAPSED" -gt 1800 ]; then
        echo "⚠️ Tidak ada hasil mining 30 menit. Ganti pool..."
        kill "$PID" || true
        return 1
      fi
    fi
  done
}

start_mining_loop() {
  POOLS=("config.luckpool.json" "config.vipor.json")
  CURRENT=0

  while true; do
    if [ -f next_pool.flag ]; then
      CONFIG=$(cat next_pool.flag)
      rm -f next_pool.flag
    else
      CONFIG="${POOLS[$CURRENT]}"
    fi

    echo "🚀 Menambang dengan pool: $CONFIG"
    run_ccminer "$CONFIG"
    monitor_miner "$CONFIG"

    if [ ! -f next_pool.flag ]; then
      CURRENT=$(( (CURRENT + 1) % ${#POOLS[@]} ))
    fi

    echo "🔁 Beralih ke pool berikutnya..."
    sleep 5
  done
}

start_mining_loop
