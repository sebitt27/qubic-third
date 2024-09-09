#!/bin/bash
# v.2024-09-09
LOG_FILE="$HOME/apoolminer/qubic.log"
INTERVAL=30             # in sec
found_status=false
last_status=""

function screen_ls {
    screen -ls | sed -E "s/Third/\x1b[1;34m&\x1b[0m/g; s/Qubic/\x1b[1;31m&\x1b[0m/g; s/CCminer/\x1b[32m&\x1b[0m/g" | tail -n +2 | head -n -1
}

function third_start {
    echo -e "\e[1;92mQUBIC = IDLE, starting VERUS\e[0m"
    screen -X -S CCminer quit
    screen -wipe 1>/dev/null 2>&1
    screen -dmS CCminer 1>/dev/null 2>&1
    VERUS="$HOME/apoolminer/ccminer -c $HOME/apoolminer/ccminer.json"
    screen -S CCminer -X stuff "$VERUS\n" 1>/dev/null 2>&1
    screen_ls
    echo $(date)
}

function third_stop {
    echo -e "\e[1;91mQUBIC = MINING, closing VERUS\e[0m"
    screen -X -S CCminer quit
    screen_ls
    echo $(date)
}

# ALEO  - not working yet
function third_start_A {
    echo -e "\e[1;92mQUBIC = IDLE, starting ALEO\e[0m"
    screen -X -S Aleo quit
    screen -wipe 1>/dev/null 2>&1
    screen -dmS Aleo 1>/dev/null 2>&1
    ALEO="$HOME/apoolminer/apoolminer_aleo -A aleo --account CP_wxxxxxxx --pool aleo1.hk.apool.io:9090 --gpu-off --thread 20 --worker XX"
    screen -S Aleo -X stuff "$ALEO\n" 1>/dev/null 2>&1
    screen_ls
    echo $(date)
}

function third_stop_A {
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
        if screen -ls | grep -q "CCniner"; then
            echo -e "\e[0;93mCCminer already running\e[0m"
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
