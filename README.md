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
- third-miner, in this case ccminer is started as an independent process in screen 'CCminer' for idle time

customization requires some prior programming knowledge

WARNING: All scripts are adapted or changed and many things are set automatically according to my requirements. This can cause irreparable damage to your previous scripts with the same name and also to Ubuntu system scripts. Before running anything, review the contents of the files. If you don't understand something in the files, use google.

I accept no warranties or liabilities on this repo. It is supplied as a service.

Use at your own risk!!! No support!!!
