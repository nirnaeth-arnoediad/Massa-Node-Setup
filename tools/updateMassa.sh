#!/bin/bash

architectureSelector=1 #If your system has arm64 architecture set this to 1. If amd64 leave this as 0. This script assumes user using linux based OS.
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
