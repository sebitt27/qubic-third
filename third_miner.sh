#!/bin/bash
# v.2024-09-09
# by blbMS

LOG_FILE="/var/tmp/miner/custom_apoolminer_linux_v2.3.0/qubic.log"
INTERVAL=30             # in sec
found_status=false
last_status=""

function screen_ls {
    screen -ls | sed -E "s/Third/\x1b[1;34m&\x1b[0m/g; s/miner/\x1b[1;31m&\x1b[0m/g; s/Aleo/\x1b[32m&\x1b[0m/g" | tail -n +2 | head -n -1
}

function third_start {
    echo -e "\e[1;92mQUBIC = IDLE, starting ALEO\e[0m"
    screen -X -S Aleo quit
    screen -wipe 1>/dev/null 2>&1
    screen -dmS Aleo 1>/dev/null 2>&1
    ALEO="/home/miner/apool2.3/apoolminer_linux_v2.3.0/aleominer -u stratum+tcp://aleo-asia.f2pool.com:4400 -w sebit27"
    screen -S Aleo -X stuff "$ALEO\n" 1>/dev/null 2>&1
    screen_ls
    echo $(date)
}

function third_stop {
    echo -e "\e[1;91mQUBIC = MINING, closing ALEO\e[0m"
    screen -X -S Aleo quit
    screen_ls
    echo $(date)
}

function find_initial_status {
    while IFS= read -r line; do
        if echo "$line" | grep -q "mining idle now"; then
            echo -e "\e[0;93mInitial state: \e[1;92midle\e[0m"
            last_status="idle"
            found_status=true
            break
        elif echo "$line" | grep -q "mining work now"; then
            echo -e "\e[0;93mInitial state: \e[1;91mwork\e[0m"
            last_status="work"
            found_status=true
            break
        fi
    done < <(tac "$LOG_FILE")
}

find_initial_status
if [[ "$found_status" == false ]]; then
    echo -e "\n\e[0;91mNo initial status found 'mining idle now' or 'mining work now' v $LOG_FILE\e[0m\n"
    exit 1
fi

while true; do
    while IFS= read -r line; do
        if echo "$line" | grep -q "mining idle now"; then
            current_status="idle"
            break
        elif echo "$line" | grep -q "mining work now"; then
            current_status="work"
            break
        fi
    done < <(tac "$LOG_FILE")

    if [[ "$current_status" == "idle" && "$last_status" != "idle" ]]; then
        if screen -ls | grep -q "Aleo"; then
            echo -e "\e[0;93mAleo already running\e[0m"
        else
            third_start
            last_status="idle"
        fi
    elif [[ "$current_status" == "work" && "$last_status" != "work" ]]; then
        third_stop
        last_status="work"
    fi
    sleep $INTERVAL
done
