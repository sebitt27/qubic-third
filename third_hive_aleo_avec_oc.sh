# Récupère le nom d'hôte du PC
hostname=$(hostname)

third_miner="aleominer"
third_cmd="./aleominer -u stratum+ssl://aleo-asia.f2pool.com:4420 -w sebit27.$hostname"

# Scripts d'overclocking à exécuter
ocdebut="/home/user/ocdebut.sh"  # Script à exécuter quand la mining_seed est idle
ocfin="/home/user/ocfin.sh"  # Script à exécuter quand le mining_seed n'est plus idle

# Indicateur pour s'assurer que le script ocdebut n'est exécuté qu'une seule fois
idle_script_executed=false
active_script_executed=false

echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m Starting the monitoring loop..."

while true; do
    now_time=$(date +%s)
    url="http://qubic1.hk.apool.io:8001/api/qubic/epoch_challenge"
    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m Fetching data from URL: $url"

    url_code=$(curl -s -o /dev/null -w '%{http_code}' "$url")
    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m HTTP response code: $url_code"

    if [ -e "$third_miner" ]; then
        echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m $third_miner exists, proceeding with checks..."

        if [ "$url_code" -eq 200 ]; then
            res_url=$(curl -s "$url")
            echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m Response from URL: $res_url"

            mining_time=$(echo "$res_url" | grep -o '"timestamp":[0-9]*' | sed 's/.*"timestamp":\([0-9]*\).*/\1/')
            mining_seed=$(echo "$res_url" | grep -o '"mining_seed":"[^"]*"' | sed 's/.*"mining_seed":"\([^"]*\)".*/\1/')

            echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m Extracted mining_time: $mining_time"
            echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m Extracted mining_seed: $mining_seed"

            if [ -z "$mining_seed" ]; then
                echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[31mERROR\033[0m Failed to check mining seed, will retry after 30 seconds"
                sleep 30
                continue
            elif [ "$mining_seed" = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" ]; then
                # Si le mining_seed indique que le système est en idle, démarrer third_cmd
                echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m Mining seed is idle indicator"

                if ! pgrep -f "aleominer" > /dev/null; then
                    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[32mINFO\033[0m Mining seed indicates idle, running third_cmd"
                    $third_cmd > "idle_miner.log" 2>&1 &
                    disown
                    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m third_cmd started: $third_cmd"
                else
                    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m third_cmd is already running"
                fi

                # Exécuter le script ocdebut une seule fois
                if [ "$idle_script_executed" = false ]; then
                    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[32mINFO\033[0m Running idle bash script ocdebut..."
                    bash "$ocdebut"
                    idle_script_executed=true  # Marque le script ocdebut comme exécuté
                    active_script_executed=false  # Réinitialiser pour permettre ocfin après la sortie de l'idle
                else
                    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m ocdebut script has already been executed"
                fi
            else
                # Si le mining_seed n'est plus celui attendu, arrêter third_cmd (tous les processus aleominer)
                echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[33mINFO\033[0m Mining seed indicates active mining, stopping idle miner"
                if pgrep -f "aleominer" > /dev/null; then
                    pkill -f "aleominer"
                    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[32mINFO\033[0m Idle miner stopped successfully"
                fi
                # Exécuter le script ocfin une seule fois après avoir quitté l'état idle
                if [ "$active_script_executed" = false ]; then
                    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[32mINFO\033[0m Running active mining bash script..."
                    bash "$ocfin"
                    active_script_executed=true  # Marque le script ocfin comme exécuté
                    idle_script_executed=false  # Réinitialiser pour permettre ocdebut lors du prochain idle
                else
                    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[34mDEBUG\033[0m Active mining bash script has already been executed"
                fi
            fi
            sleep 5
        else
            echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[31mERROR\033[0m Failed to connect to the URL, will retry after 30 seconds"
            sleep 30
        fi
    else
        echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[31mERROR\033[0m $third_miner does not exist"
        sleep 5
    fi
done
