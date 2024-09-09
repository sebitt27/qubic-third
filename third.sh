#!/bin/bash
# v.2024-09-09
# by blbMS

function screen_ls {
        screen -ls | sed -E "s/Qubic/\x1b[1;31m&\x1b[0m/g; s/CCminer/\x1b[32m&\x1b[0m/g; s/Update/\x1b[36m&\x1b[0m/g; s/Watch/\x1b[33m&\x1b[0m/g; s/block_update/\x1b[1;35m&\x1b[0m/g" | tail -n +2 | head -n -1
}
echo -e "\n\e[1;94mStarting Third miner QUBIC / VERUS \e[0m\n"
screen -X -S Third quit
screen -wipe 1>/dev/null 2>&1
screen -dmS Third 1>/dev/null 2>&1
screen -S Third -X stuff "~/apoolminer/third_miner.sh\n" 1>/dev/null 2>&1
screen_ls
sleep 1
screen -d -r Third
