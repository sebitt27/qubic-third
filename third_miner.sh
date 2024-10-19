#exécuter le script dans le répertoire ou il y a aleominer pour f2pool installer

third_miner="aleominer"
third_cmd="./aleominer u stratum+ssl://aleo-asia.f2pool.com:4420 -w sebit27.rigseb"

while true; do
    now_time=$(date +%s)
    url="http://qubic1.hk.apool.io:8001/api/qubic/epoch_challenge"
    url_code=$(curl -s -o /dev/null -w '%{http_code}' "$url")
    if [ -e "$third_miner" ]; then
        if [ "$url_code" -eq 200 ]; then
            res_url=$(curl -s "$url")
            mining_time=$(echo "$res_url" | grep -o '"timestamp":[0-9]*' | sed 's/.*"timestamp":\([0-9]*\).*/\1/')
            mining_seed=$(echo "$res_url" | grep -o '"mining_seed":"[^"]*"' | sed 's/.*"mining_seed":"\([^"]*\)".*/\1/')
            if [ -z "$mining_seed" ]; then
                echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[31mERROR\033[0m Failed to check mining seed, will retry after 30 seconds"
                sleep 30
                continue
            elif [ "$mining_seed" = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" ]; then
                # Condition pour stopper tous les processus contenant 'zkminer' dans leur nom
                if pgrep -f "aleominer" > /dev/null; then
                    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[32mINFO\033[0m Mining seed indicates stop, stopping all zkminer processes"
                    pkill -f "aleominer"
                else
                    echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[32mINFO\033[0m No template available, running third_cmd"
                    $third_cmd > "$third_miner.log" 2>&1 &
                    disown
                fi
            fi
            sleep 5
        fi
    else
        echo -e "$(date +"%Y-%m-%d %H:%M:%S")     \033[31mERROR\033[0m $third_miner does not exist"
        sleep 5
    fi
done
