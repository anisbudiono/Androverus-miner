#!/data/data/com.termux/files/usr/bin/bash
cd "$(dirname "$0")"
termux-wake-lock

BOT_TOKEN=$(cat bot_token.txt)
CHAT_ID=$(cat chat_id.txt)
WORKER=$(cat worker_name.txt)

send_telegram() {
  MSG="$1"
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    -d text="[$WORKER] $MSG" > /dev/null
}

listen_telegram_command() {
  OFFSET_FILE=".tg_offset"
  [ ! -f "$OFFSET_FILE" ] && echo "0" > "$OFFSET_FILE"
  OFFSET=$(cat "$OFFSET_FILE")

  while true; do
    UPDATES=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=30")
    RESULTS=$(echo "$UPDATES" | jq '.result')
    COUNT=$(echo "$RESULTS" | jq 'length')

    if [ "$COUNT" -gt 0 ]; then
      for (( i=0; i<COUNT; i++ )); do
        update=$(echo "$RESULTS" | jq ".[$i]")
        ID=$(echo "$update" | jq '.update_id')
        MESSAGE=$(echo "$update" | jq -r '.message.text')
        SENDER=$(echo "$update" | jq -r '.message.chat.id')

        if [[ "$SENDER" == "$CHAT_ID" ]]; then
          case "$MESSAGE" in
            /switchluckpool)
              echo "config.luckpool.json" > next_pool.flag
              send_telegram "🔁 Berpindah ke Luckpool..."
              ;;
            /switchvipor)
              echo "config.vipor.json" > next_pool.flag
              send_telegram "🔁 Berpindah ke Vipor..."
              ;;
            /status)
              VRSC_PRICE=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=verus-coin&vs_currencies=idr" | jq -r '."verus-coin".idr')
              ACCEPTED=$(grep -c "accepted" miner.log 2>/dev/null || echo 0)
              EST_VRSC=$(echo "$ACCEPTED * 0.00001" | bc -l)
              EST_RP=$(echo "$EST_VRSC * $VRSC_PRICE" | bc -l | xargs printf "%.0f")

              LAST_KHS=$(tac miner.log | grep -m 1 "accepted:" | grep -oP '[0-9.]+(?= kH/s)' || echo 0)
              AVG_SPEED=$(echo "$LAST_KHS / 1000" | bc -l | xargs printf "%.2f")

              PID=$(cat ccminer.pid 2>/dev/null)
              if ps -p "$PID" > /dev/null 2>&1; then
                if grep -q "luckpool" miner.log; then
                  STATUS="Kerja di PT LUCKPOOL"
                elif grep -q "vipor" miner.log; then
                  STATUS="Kerja di PT VIPOR"
                else
                  STATUS="Kerja"
                fi
              else
                STATUS="Sakit tidak kerja"
              fi

              if [ -f mining_start_time.txt ]; then
                START_TIME=$(cat mining_start_time.txt)
                NOW=$(date +%s)
                SECONDS=$((NOW - START_TIME))
                WKT_KERJA=$(printf '%02ij:%02im:%02id' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))
              else
                WKT_KERJA="Unknown"
              fi

              send_telegram "$(printf '👷 Status Karyawan:\nPosisi: %s\nWaktu kerja: %s\nSpeed: %s MH/s\nJumlah Share: %s\nEstimasi Hasil: ~Rp. %s' "$STATUS" "$WKT_KERJA" "$AVG_SPEED" "$ACCEPTED" "$EST_RP")"
              ;;
          esac
        fi
        OFFSET=$((ID + 1))
      done
      echo "$OFFSET" > "$OFFSET_FILE"
    fi
    sleep 2
  done
}

listen_telegram_command
