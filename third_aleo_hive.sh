#!/bin/bash
# v.2024-09-09
# by blbMS

LOG_FILE="/hive/miners/custom/apoolminer_hiveos_autoupdate/qubic.log"
INTERVAL=30             # in sec
found_status=false
last_status=""

# Vérifier si le fichier de log existe et est accessible
if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "\e[0;91mLog file $LOG_FILE does not exist or is not accessible\e[0m"
    exit 1
fi

function screen_ls {
    screen -ls | sed -E "s/Third/\x1b[1;34m&\x1b[0m/g; s/Qubic/\x1b[1;31m&\x1b[0m/g; s/Aleo/\x1b[32m&\x1b[0m/g" | tail -n +2 | head -n -1
}

function third_start {
    echo -e "\e[1;92mQUBIC = IDLE, starting ALEO\e[0m"
    echo "Attempting to close any existing Aleo sessions..."
    screen -X -S Aleo quit

    echo "Cleaning up detached screen sessions..."
    screen -wipe 1>/dev/null 2>&1

    echo "Starting a new screen session named 'Aleo'..."
    screen -dmS Aleo
    sleep 2  # Pause pour permettre à la session de se lancer complètement

    echo "Sending command to Aleo screen session..."
    screen -S Aleo -X stuff '/hive/miners/custom/aleominer/aleominer -u stratum+ssl://aleo-asia.f2pool.com:4420 -w rockstarsim.rack\n'

    # Vérifiez si la session Aleo a bien été créée
    if screen -ls | grep -q "Aleo"; then
        echo -e "\e[0;92mAleo session successfully started\e[0m"
    else
        echo -e "\e[0;91mFailed to start Aleo session\e[0m"
    fi

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
    echo -e "\n\e[0;91mNo initial status found: 'mining idle now' or 'mining work now' in $LOG_FILE\e[0m\n"
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

    # Affichage pour le débogage du statut actuel et précédent
    echo "Current status: $current_status, Last status: $last_status"

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
