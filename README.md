# Massa-Node-Setup

Massa-Node Sistem Servisi Olarak Kurulumu ve Roll Otomasyonu. Kurulum Ubuntu 22.04 amd64 ve arm64 versiyonları için geçerlidir.

Öncelikle Home lokasyonuna dönelim ve sistemimize uygun en güncel node versiyonunu indirelim ve arşivden çıkartalım. Ardindan arşiv dosyasını silelim. https://github.com/massalabs/massa/releases adresinden kontrol edebilirsiniz.
```
For amd64
cd
wget https://github.com/massalabs/massa/releases/download/MAIN.2.0/massa_MAIN.2.0_release_linux.tar.gz
tar -xvf massa_MAIN.2.0_release_linux.tar.gz
rm massa_MAIN.2.0_release_linux.tar.gz

For arm64
cd
wget https://github.com/massalabs/massa/releases/download/MAIN.2.0/massa_MAIN.2.0_release_linux_arm64.tar.gz
tar -xvf massa_MAIN.2.0_release_linux_arm64.tar.gz
rm massa_MAIN.2.0_release_linux_arm64.tar.gz
```

Bir defaya mahsus cüzdanımızı import edelim. Clienti ilk çalıştırma esnasında cüzdan şifremizi oluşturalım ve saklayalım.
```
cd massa/massa-client
./massa-client -p şifreniz
wallet_add_secret_keys secret_keyiniz
wallet_info
exit
```

Cüzdan adresimizi roll otomasyonunda kullanmak üzere not alalım ve yine bir defaya mahsus olmak üzere config.toml dosyamızı oluşturalım. Bunun için sunucunun veya ev internetinin public ip'sine ihtiyacımız var. `sudo nano ~/massa/massa-node/config/config.toml` komutu ile dosyamızı oluşturup aşağıdaki kısmı ip'mizi yazarak içerisine yapıştıralım.
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

# Güncelleme
Bunun için basit bir script hazırladım. Script içerisinde iki değişken mevcut birincisi `architectureSelector` `0` değerini atarsanız `amd64` versiyonu için `1` değerini atarsanız `arm64` için güncelleme yapar. Diğer değişken ise versiyon değişkeni. En güncel versiyonu https://github.com/massalabs/massa/releases adresinde bulabilirsiniz yeşil `latest` yazısının yanındaki release başlığını script içerisinde `releaseVersionTag` karşısına yazın. Şuan için en güncel versiyon `MAIN.2.0`. Aşağıdaki komutlarla script dosyasını oluşturun ve içeriği yapıştırın.
```
touch updateMassa.sh
sudo chmod +x updateMassa.sh
nano updateMassa.sh
```
updateMassa.sh
```
#!/bin/bash

architectureSelector=0 #If your system has arm64 architecture set this to 1. If amd64 leave this as 0. This script assumes user using linux based OS.
releaseVersionTag=MAIN.2.0 #Enter latest version. You can check and copy latest version tag at https://github.com/massalabs/massa/releases
sudo systemctl stop massad
cd
mkdir massa-update-temporary-folder
cd massa-update-temporary-folder
if [[ "$architectureSelector" -eq 1 ]]; then
        wget https://github.com/massalabs/massa/releases/download/${releaseVersionTag}/massa_${releaseVersionTag}_release_linux_arm64.tar.gz
        tar -xvf massa_${releaseVersionTag}_release_linux_arm64.tar.gz
else
        wget https://github.com/massalabs/massa/releases/download/${releaseVersionTag}/massa_${releaseVersionTag}_release_linux.tar.gz
        tar -xvf massa_${releaseVersionTag}_release_linux.tar.gz
fi
cd massa/massa-node
cp massa-node ~/massa/massa-node/
cd ..
cd massa-client
cp massa-client ~/massa/massa-client/
cd
sudo rm -rf massa-update-temporary-folder
sudo systemctl restart massad
sudo journalctl -u massad -f -o cat
```
Ne zaman bir güncelleme gelirse `./updateMassa.sh` komutu ile node güncelleyebilirsiniz bu komut node'u durdurur güncellemeyi yapar ve geri çalıştırır. Sadece bu kurulum ile uyumludur.


# Node kurulumu tamamlanmıştır. Opsiyonel olarak roll sayısını otomatik kontrol eden bir script hazırladım isteyenler bunu da devreye alabilir. Birçok kez test ettim herhangi bir sorun yaşamadım. Lütfen siz de inceleyin eksik veya yanlış gördüğünüz yerlerde katkıda bulunmaktan çekinmeyin. Script bir probleme yol açarsa sorumluluk size aittir.

Aşağıdaki scriptte massa-client yolu (Your path to massa-client), cüzdan şifresi (Your wallet password), cüzdan adresi (Your wallet address) değişkenlerini kendi sisteminiz göre ayarlayın. Bu kurulumu takip ettiyseniz path değişkenini değiştirmenize gerek yok. `target_roll_amount` değişkeni hedef roll sayısıdır eğer buraya 10 yazarsanız script 10'dan fazla roll almayacaktır ve bir sebeple roll'ler satılırsa tekrar 10 roll alacaktır. Bu değişkene 0 değerini atarsanız script alabildiği kadar roll alacaktır ve bakiye ne zaman 100'ü geçerse veya kilitli coinlerinizin bir miktarının kilidi açılırsa yine alabildiği kadar roll almaya devam edecektir. Script dosyasını oluşturalım ve düzenleyerek aşağıdaki kısmı yapıştıralım `sudo nano ~/rollCheck.sh`
```
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
sudo touch checkPublicIP.sh
sudo chmod +x checkPublicIP.sh
sudo nano checkPublicIP.sh
```
dinamikIPScript:
```
#!/usr/bin/env bash
Path=/home/nirneth/massa/massa-node/config
myIP=$(curl -s ident.me)
nodeIP=$(cat $Path/config.toml | grep "routable_ip" | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|([0-9a-z>
if [ $myIP == $nodeIP ]
then 
        echo 0
else
        sed -i 's/^routable_ip.*/routable_ip="'"${myIP}"'"/' $Path/config.toml
        echo "$(date): IP Changed! New IP: $myIP" >> /$HOME/log/cron.log
        sudo systemctl restart massad
        echo "$(date): Node restarted!" >> /$HOME/log/cron.log
```
