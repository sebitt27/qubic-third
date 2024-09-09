# qubic-third
## starts third-miner at qubic mining idle time - epoch 125
Basics:
- it is based on the miner's 'apool.io' output: 'qubic.log'
- apoolminer is launched in the 'Qubic' screen and is not a requirement for operation
- condition is 'qubic.log' in folder '~/apoolminer/'
- the program checks the $INTERVAL entry if the status has changed (idle or work)
- copy both files to a folder like apoolminer '~/apoolminer/'
- switching between qubic and third-miner is in the 'Third' screen
- the third-miner used is Verus (VRSC), copy 'ccminer' and 'config.json' (in this case I renamed it to 'ccminer.json') to a folder like apoolminer '~/apoolminer/'
