sudo apt-get update
sudo apt-get install -y python3-pip
pip3 install bitstring
pip3 install cffi
pip3 install numpy
pip3 install pynq
pip3 install packaging

wget https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh
bash Anaconda3-2019.10-Linux-x86_64.sh -b -p $HOME/anaconda
