# Massa-Node-Setup

Massa-Node Sistem Servisi Olarak Kurulumu ve Roll Otomasyonu. Kurulum Ubuntu 22.04 amd64 ve arm64 versiyonları için geçerlidir.

Öncelikle Home lokasyonuna dönelim ve sistemimize uygun en güncel node versiyonunu indirelim ve arşivden çıkartalım. Ardindan arşiv dosyasını silelim. https://github.com/massalabs/massa/releases adresinden kontrol edebilirsiniz.

For amd64
```
cd
wget https://github.com/massalabs/massa/releases/download/MAIN.2.4/massa_MAIN.2.4_release_linux.tar.gz
tar -xvf massa_MAIN.2.4_release_linux.tar.gz
rm massa_MAIN.2.4_release_linux.tar.gz
```

For arm64
```
cd
wget https://github.com/massalabs/massa/releases/download/MAIN.2.4/massa_MAIN.2.4_release_linux_arm64.tar.gz
tar -xvf massa_MAIN.2.4_release_linux_arm64.tar.gz
rm massa_MAIN.2.4_release_linux_arm64.tar.gz
```

Bir defaya mahsus cüzdanımızı import edelim. Clienti ilk çalıştırma esnasında cüzdan şifremizi oluşturalım ve saklayalım.
```
cd massa/massa-client
./massa-client -p şifreniz
wallet_add_secret_keys secret_keyiniz
wallet_info
exit
```

Cüzdan adresimizi roll otomasyonunda kullanmak üzere not alalım ve yine bir defaya mahsus olmak üzere config.toml dosyamızı oluşturalım. Bunun için sunucunun veya ev internetinin public ip'sine ihtiyacımız var. `nano ~/massa/massa-node/config/config.toml` komutu ile dosyamızı oluşturup aşağıdaki kısmı ip'mizi yazarak içerisine yapıştıralım.
```
[protocol]
routable_ip="xx.xx.xx.xx"
```

Massa-Node düzgün çalışmak için `31244` ve `31245` numaralı portların açık olmasına ihtiyaç duyar. Kullandığınız sistemin güvenlik duvarından ve sunucu sağlayıcınızın arayüzünden bu portları açmanız gerekebilir. Bunun için lütfen sağlayıcınızın ve sisteminizin kaynaklarına bakın.

Daha sonrasında service dosyamızı oluşturalım bunun için, `sudo nano /etc/systemd/system/massad.service` komutuyla servis dosyamızı oluşturarak aşağıdaki kısmı; User, WorkingDirectory ve ExecStart değişkenlerini sisteminize göre ayarlayarak yapıştırın (benim sistemimde kullanıcı ismi ubuntu. Bu durumda [USER] yazan yerleri ubuntu ile değiştirmek yeterli oldu). ExecStart satırında node için bir şifre belirlemeniz gerekiyor cüzdan şifresiyile aynı olabilir dilediğiniz bir şifreyi oraya girin ve şifrenizi saklayın.
```
[Unit]
	Description=Massa Node
	After=network-online.target
[Service]
	User=[USER]
	WorkingDirectory=/home/[USER]/massa/massa-node
	ExecStart=/home/[USER]/massa/massa-node/massa-node -p şifreniz
	Restart=on-failure
	RestartSec=3
	LimitNOFILE=65535
[Install]
	WantedBy=multi-user.target
```
Ardından aşağıdaki komutlarla service dosyamızı aktifleştirip çalıştıralım.
```
sudo systemctl daemon-reload
sudo systemctl enable massad.service
sudo systemctl restart massad
```

Logları kontrol etmek için:
```
sudo journalctl -u massad -f -o cat
```

Client üzerinden de in-out connectionları kontrol edelim zamanla artması gerekiyor ayrıca `get_status` komutunun en üstünde node ip değişkeni karşısına kendi ip'miniz gelip gelmediğine de bakalım.
```
cd ~/massa/massa-client
./massa-client -p şifreniz
get_status
```

Clientten ayrılmadan stake komutunu girerek key'imizi kaydedelim. `Keys successfully added!` çıktısını görmemiz gerekiyor.
```
node_start_staking cüzdan_adresi
```

Aşağıdaki komut ile de bakiyenize göre istediğiniz miktarda roll alabilirsiniz.
```
buy_rolls cüzdan_adtesi roll_adedi 0
```

# Node kurulumu tamamlanmıştır. Opsiyonel olarak roll sayısını otomatik kontrol eden bir script hazırladım isteyenler bunu da devreye alabilir. Birçok kez test ettim herhangi bir sorun yaşamadım. Lütfen siz de inceleyin eksik veya yanlış gördüğünüz yerlerde katkıda bulunmaktan çekinmeyin. Script bir probleme yol açarsa sorumluluk size aittir.

Aşağıdaki scriptte massa-client yolu (Your path to massa-client), cüzdan şifresi (Your wallet password), cüzdan adresi (Your wallet address) değişkenlerini kendi sisteminiz göre ayarlayın. Bu kurulumu takip ettiyseniz path değişkenini değiştirmenize gerek yok. `target_roll_amount` değişkeni hedef roll sayısıdır eğer buraya 10 yazarsanız script 10'dan fazla roll almayacaktır ve bir sebeple roll'ler satılırsa tekrar 10 roll alacaktır. Bu değişkene 0 değerini atarsanız script alabildiği kadar roll alacaktır ve bakiye ne zaman 100'ü geçerse veya kilitli coinlerinizin bir miktarının kilidi açılırsa yine alabildiği kadar roll almaya devam edecektir. Script dosyasını oluşturalım ve düzenleyerek aşağıdaki kısmı yapıştıralım `nano ~/rollCheck.sh`
```
#!/bin/bash

GREEN='\033[0;32m'
LIGHTBLUE='\033[1;33m'
LIGHTCYAN='\033[1;36m'
LIGHTRED='\033[1;31m'

# Change to the massa-client directory and specify variables

cd /$HOME/massa/massa-client/ # Your path to massa-client
wallet_password=xxxxxx # Your wallet password

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
```
Kaydedip çıktıktan sonra
```
sudo chmod +x ~/rollCheck.sh
```
komutu ile bu scripti çalıştırılabilir hale getirelim.

Scriptin bir döngü halinde çalışması için bir cronjob oluşturmamız gerekiyor. Scripti home yolunda oluşturduk tam dosya yolunu öğrenmek için scriptin olduğu klasörde `pwd` komutunu kullanabilirsiniz. Cronjob için `crontab -e` komutunu girelim ve en alta aşağıdaki komutu ekleyelim.
```
*/5 * * * * /sizin/dosya/yolunuz/rollCheck.sh >/dev/null 2>&1
```
Buradaki 5 sayısı 5 dakikayı temsil ediyor yani 5 dakikada bir script çalışacak ve kontrol edecek dilerseniz 15 veya 30 dakikalık kontrol döngüleri de oluşturabilirsiniz 5 uygun olur diye düşünüyorum. Script kendi bulunduğu lokasyona rollCheckScript.log isimli bir dosya oluşturacak bu dosyadan hangi saatte ne yaptığını kontrol edebilirsiniz.

Bu işlem de tamamdır `cd` ile home konumuna dönüp `cat rollCheckScript.log` komutu ile script loglarını kontrol edebilirsiniz tabiki döngü süresi kadar beklemek gerekiyor ilk defaya mahsus. Dilerseniz,
```
./rollCheck.sh
```
komutu ile scripti manuel olarak da çalıştırabilirsiniz.

# Dinamik IP

Son olarak eğer evde çalıştırıyorsanız ve ip'niz dinamik ise aşağıdaki scripti oluşturup yine cronjob'a ekleyerek sürekli kontrol yapabilirsiniz değiştikçe yeni ip'yi girecektir.
```
touch checkPublicIP.sh
sudo chmod +x checkPublicIP.sh
nano checkPublicIP.sh
```
dinamikIPScript:
```
#!/usr/bin/env bash
Path=/home/nirnaeth/massa/massa-node/config # Your config.toml path
myIP=$(curl https://ipinfo.io/ip)
nodeIP=$(cat $Path/config.toml | grep "routable_ip" | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|([0-9a-z]{4})(:[0-9a-z]{0,4}){1,7}')
if [ "$myIP" == "$nodeIP" ]
then 
        echo 0
else
        sed -i 's/^routable_ip.*/routable_ip="'"${myIP}"'"/' $Path/config.toml
        echo "$(date): IP Changed! New IP: $myIP" >> /$HOME/IPlogs.log
        sudo systemctl restart massad
        echo "$(date): Node restarted!" >> /$HOME/IPlogs.log
fi
```
