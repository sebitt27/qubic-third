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
    screen -S Aleo -X stuff '/hive/miners/custom/aleominer/aleominer -u stratum+ssl://aleo-asia.f2pool.com:4420 -w rockstarsims.rack\n'

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
    # Lire les dernières 1000 lignes du fichier de log pour détecter l'état initial
    local log_lines
    log_lines=$(tail -n 300 "$LOG_FILE")  # Utilisation de tail pour garantir les dernières lignes

    echo "Analyzing log entries to find initial status..."  # Message de débogage

    while IFS= read -r line; do
        echo "Processing line in initial status detection: $line"  # Message de débogage

        if [[ "$line" =~ mining\ idle\ now ]]; then
            echo -e "\e[0;93mInitial state: \e[1;92midle\e[0m"
            last_status="idle"
            found_status=true
            break
        elif [[ "$line" =~ mining\ work\ now ]]; then
            echo -e "\e[0;93mInitial state: \e[1;91mwork\e[0m"
            last_status="work"
            found_status=true
            break
        fi
    done <<< "$log_lines"
}

function read_current_status {
    # Lire les 1000 dernières lignes du fichier de log pour détecter l'état courant
    local log_lines
    log_lines=$(tail -n 300 "$LOG_FILE")  # Lire les 1000 dernières lignes du fichier de log

    echo "Analyzing recent log entries for current status..."  # Message de débogage

    while IFS= read -r line; do
        echo "Processing log entry: $line"  # Message de débogage

        if [[ "$line" =~ mining\ idle\ now ]]; then
            current_status="idle"
            echo "Detected current status: idle"  # Message de débogage
            return 0  # Sortir de la fonction dès qu'on trouve l'état "idle"
        elif [[ "$line" =~ mining\ work\ now ]]; then
            current_status="work"
            echo "Detected current status: work"  # Message de débogage
            return 0  # Sortir de la fonction dès qu'on trouve l'état "work"
        fi
    done <<< "$log_lines"

    # Si aucun état n'est détecté dans les dernières lignes, conserver l'état précédent
    echo "No status change detected in the log file."
    return 1  # Indiquer qu'aucune mise à jour d'état n'a été détectée
}

# Trouver l'état initial lors du démarrage du script
find_initial_status

if [[ "$found_status" == "false" ]]; then
    echo -e "\n\e[0;91mNo initial status found ('mining idle now' or 'mining work now') in $LOG_FILE\e[0m\n"
    exit 1
fi

# Vérifier si on est en "idle" au démarrage et lancer third_start si nécessaire
if [[ "$last_status" == "idle" ]]; then
    echo "Initial status is idle, starting Aleo..."
    third_start
fi

# Boucle principale pour surveiller l'état courant
while true; do
    read_current_status  # Appeler la fonction qui lit l'état actuel

    if [[ $? -ne 0 ]]; then
        echo "No status change, sleeping for $INTERVAL seconds."
        sleep $INTERVAL
        continue
    fi

    echo "Current status: $current_status, Last status: $last_status"  # Message de débogage

    if [[ "$current_status" == "$last_status" ]]; then
        echo "No status change, sleeping for $INTERVAL seconds."
    else
        if [[ "$current_status" == "idle" ]]; then
            if screen -ls | grep -q "Aleo"; then
                echo -e "\e[0;93mAleo already running, no need to start\e[0m"
            else
                echo "Aleo not running, starting Aleo now (idle status detected)"
                third_start
            fi
            last_status="idle"
        elif [[ "$current_status" == "work" ]]; then
            third_stop
            last_status="work"
        fi
    fi

    sleep $INTERVAL
done
