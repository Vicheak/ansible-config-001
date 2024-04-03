sudo apt install software-properties-common -y
sudo echo -e "\n" | sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt install python3-pip -y
sudo pip install ansible 
export PATH=$PATH:/usr/bin
ansible --version

