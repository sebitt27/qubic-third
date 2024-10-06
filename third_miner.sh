#!/bin/bash
# v.2024-09-09
# by blbMS

LOG_FILE="/var/tmp/screen.miner.log"
INTERVAL=30             # in sec
found_status=false
last_status=""
current_status=""

# Vérification de l'existence du fichier log
if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "\e[0;91mLog file not found: $LOG_FILE\e[0m"
    exit 1
fi

function screen_ls {
    screen -ls | sed -E "s/Third/\x1b[1;34m&\x1b[0m/g; s/miner/\x1b[1;31m&\x1b[0m/g; s/Aleo/\x1b[32m&\x1b[0m/g" | tail -n +2 | head -n -1
}

function third_start {
    echo -e "\e[1;92mQUBIC = IDLE, starting ALEO\e[0m"
    if screen -ls | grep -q "Aleo"; then
        screen -X -S Aleo quit
        screen -wipe 1>/dev/null 2>&1
    fi
    screen -dmS Aleo 1>/dev/null 2>&1
    ALEO="/home/miner/apool2.3/apoolminer_linux_v2.3.0/aleominer -u stratum+ssl://aleo-asia.f2pool.com:4420 -w sebit27"
    screen -S Aleo -X stuff "$ALEO\n" 1>/dev/null 2>&1
    screen_ls
    echo "$(date '+%Y-%m-%d %H:%M:%S')"
}

function third_stop {
    echo -e "\e[1;91mQUBIC = MINING, closing ALEO\e[0m"
    if screen -ls | grep -q "Aleo"; then
        screen -X -S Aleo quit
    fi
    screen_ls
    echo "$(date '+%Y-%m-%d %H:%M:%S')"
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
    done < <(tac "$LOG_FILE" | head -n 1000)  # Limite à 1000 lignes pour optimisation
}

find_initial_status

if [[ "$found_status" == "false" ]]; then
    echo -e "\n\e[0;91mNo initial status found ('mining idle now' or 'mining work now') in $LOG_FILE\e[0m\n"
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
    done < <(tac "$LOG_FILE" | head -n 1000)  # Limite à 1000 lignes pour optimisation

    # Si l'état actuel est le même que l'état précédent, continuer à attendre
    if [[ "$current_status" == "$last_status" ]]; then
        sleep $INTERVAL
        continue
    fi

    if [[ "$current_status" == "idle" && "$last_status" != "idle" ]]; then
        if screen -ls | grep -q "Aleo"; then
            echo -e "\e[0;93mAleo already running\e[0m"
        else
            third_start
        fi
        last_status="idle"
    elif [[ "$current_status" == "work" && "$last_status" != "work" ]]; then
        third_stop
        last_status="work"
    fi

    sleep $INTERVAL
done
