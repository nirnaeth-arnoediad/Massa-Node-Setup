#!/bin/bash

GREEN='\033[0;32m'
LIGHTBLUE='\033[1;33m'
LIGHTCYAN='\033[1;36m'
LIGHTRED='\033[1;31m'

# Change to the massa-client directory and specify variables

cd /$HOME/massa/massa-client/ # Your path to massa-client
wallet_password=xxxxx # Your wallet password

# Run the wallet_info command and extract the active rolls value

output=$("./massa-client" -p $wallet_password wallet_info)

wallet_address1=$(echo "$output" | awk 'FNR == 2 {print $2}')
active_rolls1=$(echo "$output" | awk 'FNR == 4 {print $2}' | sed 's/.*=//' | sed 's/.$//')
candidate_rolls1=$(echo "$output" | awk 'FNR == 4 {print $4}' | sed 's/.*=//')
candidate_balance1=$(echo "$output" | awk  'FNR == 3 {print $3}' | sed 's/.*=//' | cut -f1 -d".")
possible_rolls1="$((candidate_balance1/100))"

# wallet_address2=$(echo "$output" | awk 'FNR == 6 {print $2}')
# active_rolls2=$(echo "$output" | awk 'FNR == 8 {print $2}' | sed 's/.*=//' | sed 's/.$//')
# candidate_rolls2=$(echo "$output" | awk 'FNR == 8 {print $4}' | sed 's/.*=//')
# candidate_balance2=$(echo "$output" | awk  'FNR == 7 {print $3}' | sed 's/.*=//' | cut -f1 -d".")
# possible_rolls2="$((candidate_balance2/100))"

# wallet_address3=$(echo "$output" | awk 'FNR == 10 {print $2}')
# active_rolls3=$(echo "$output" | awk 'FNR == 12 {print $2}' | sed 's/.*=//' | sed 's/.$//')
# candidate_rolls3=$(echo "$output" | awk 'FNR == 12 {print $4}' | sed 's/.*=//')
# candidate_balance3=$(echo "$output" | awk  'FNR == 11 {print $3}' | sed 's/.*=//' | cut -f1 -d".")
# possible_rolls3="$((candidate_balance3/100))"

roll_cost=100

# Append the cron command result to the cron.log file
echo "" >> /$HOME/rollCheckScript.log
echo -e "${GREEN}$(date): Wallet Address: $wallet_address1" >> /$HOME/rollCheckScript.log
echo "$(date): Active Rolls: $active_rolls1" >> /$HOME/rollCheckScript.log
echo "$(date): Candidate Rolls: $candidate_rolls1" >> /$HOME/rollCheckScript.log
echo "$(date): Candidate Balance: $candidate_balance1" >> /$HOME/rollCheckScript.log
echo "$(date): Possible Rolls: $possible_rolls1" >> /$HOME/rollCheckScript.log
echo "" >> /$HOME/rollCheckScript.log

# echo -e "${LIGHTBLUE}$(date): Wallet Address: $wallet_address2" >> /$HOME/rollCheckScript.log
# echo "$(date): Active Rolls: $active_rolls2" >> /$HOME/rollCheckScript.log
# echo "$(date): Candidate Rolls: $candidate_rolls2" >> /$HOME/rollCheckScript.log
# echo "$(date): Candidate Balance: $candidate_balance2" >> /$HOME/rollCheckScript.log
# echo "$(date): Possible Rolls: $possible_rolls2" >> /$HOME/rollCheckScript.log
# echo "" >> /$HOME/rollCheckScript.log

# echo -e "${LIGHTRED}$(date): Wallet Address: $wallet_address3" >> /$HOME/rollCheckScript.log
# echo "$(date): Active Rolls: $active_rolls3" >> /$HOME/rollCheckScript.log
# echo "$(date): Candidate Rolls: $candidate_rolls3" >> /$HOME/rollCheckScript.log
# echo "$(date): Candidate Balance: $candidate_balance3" >> /$HOME/rollCheckScript.log
# echo "$(date): Possible Rolls: $possible_rolls3" >> /$HOME/rollCheckScript.log
# echo "" >> /$HOME/rollCheckScript.log

# Buy possible rolls all the time

if [[ "$candidate_balance1" -ge "$roll_cost" ]]; then

       "./massa-client" -p $wallet_password buy_rolls $wallet_address1 $possible_rolls1 0.01
       echo -e "${LIGHTCYAN}$(date): $possible_rolls1 Rolls bought for $wallet_address1" >> /$HOME/rollCheckScript.log

fi

# if [[ "$candidate_balance2" -ge "$roll_cost" ]]; then

#        "./massa-client" -p $wallet_password buy_rolls $wallet_address2 $possible_rolls2 0.01
#        echo "$(date): $possible_rolls2 Rolls bought for $wallet_address2" >> /$HOME/rollCheckScript.log

#fi

#if [[ "$candidate_balance3" -ge "$roll_cost" ]]; then

#       "./massa-client" -p $wallet_password buy_rolls $wallet_address3 $possible_rolls3 0.01
#      echo "$(date): $possible_rolls3 Rolls bought for $wallet_address3" >> /$HOME/rollCheckScript.log

#fi
