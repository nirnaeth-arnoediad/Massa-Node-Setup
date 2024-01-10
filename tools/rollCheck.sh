#!/bin/bash

# Change to the massa-client directory and specify variables
cd /$HOME/massa/massa-client/ # Your path to massa-client
wallet_password=12345 # Your wallet password
wallet_address=AU1RdSuQrBKVpoyLNjtccZER3jkmHq3WgNQVHFJNqenUaapJeWW2 # Your wallet address
target_roll_amount=0 # If target roll amount is 0 script try to buy rolls as much as possible
roll_amount_to_buy=0

# Run the wallet_info command and extract the active rolls value
output=$("./massa-client" -p $wallet_password wallet_info)
active_rolls=$(echo "$output" | awk '/Rolls:/{print $2}' | sed 's/.*=//' | sed 's/.$//')
candidate_rolls=$(echo "$output" | awk '/Rolls:/{print $NF}' | cut -d= -f2)
candidate_balance=$(echo "$output" | awk '/Balance:/{print $NF}' | cut -d= -f2 | cut -f1 -d".")
possible_rolls="$((candidate_balance/100))"
roll_cost=100

# Append the cron command result to the cron.log file
echo "" >> /$HOME/rollCheckScript.log
echo "$(date): Active Rolls: $active_rolls" >> /$HOME/rollCheckScript.log
echo "$(date): Candidate Rolls: $candidate_rolls" >> /$HOME/rollCheckScript.log
echo "$(date): Candidate Balance: $candidate_balance" >> /$HOME/rollCheckScript.log
echo "$(date): Possible Rolls: $possible_rolls" >> /$HOME/rollCheckScript.log

# Buy possible rolls all the time
if [[ "$target_roll_amount" -eq 0 ]]; then
	if [[ "$candidate_balance" -ge "$roll_cost" ]]; then

		"./massa-client" -p $wallet_password buy_rolls $wallet_address $possible_rolls 0
		echo "$(date): $possible_rolls Rolls bought!" >> /$HOME/rollCheckScript.log

	fi
fi

# Check roll status with target roll amount
if [[ "$target_roll_amount" -ne 0 ]]; then
	if [[ "$target_roll_amount" -gt "$candidate_rolls" ]]; then
		if [[ "$active_rolls" -eq 0 ]]; then

			# Looks like rolls are sold. Re-buying...
			"./massa-client" -p $wallet_password buy_rolls $wallet_address $target_roll_amount 0
		 	echo "$(date): $target_roll_amount Rolls bought!" >> /$HOME/rollCheckScript.log

		fi

		if [[ "$candidate_rolls" -ne 0 ]]; then

			echo "$(date): Target Roll Amount: $target_roll_amount" >> /$HOME/rollCheckScript.log
		        roll_amount_to_buy="$((target_roll_amount-candidate_rolls))"

			if [[ "$roll_amount_to_buy" -gt "$possible_rolls" ]]; then

				echo "$(date): Target roll amount is too high. Please lower your target acording to your unlocked balance" >> /$HOME/rollCheckScript.log

			else

				# Increase roll amount to reach target.
	   			"./massa-client" -p $wallet_password buy_rolls $wallet_address $roll_amount_to_buy 0
   				echo "$(date): $roll_amount_to_buy Rolls bought!" >> /$HOME/rollCheckScript.log

			fi
		fi
	fi
fi
