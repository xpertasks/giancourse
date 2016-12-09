# V1.03 8/12/2016 BP
# This will install minimum software for the Labs organized during GIAN course about MT
# Send instructions:
#cat ~/installSmtLabs.sh | mail -s '~/installSmtLabs.sh' bruno.pouliquen@wipo.int


sudo apt-get install -y cmake git subversion libboost-all-dev liblzma-dev libbz2-dev zlib1g-dev automake libxml2-dev libsparsehash-dev
# libsparsehash-dev: required by amunmt

# Remove some games / useless packages on Ubuntu (just to save space)
sudo apt remove aisleriot gnome-mahjongg gnome-mines gnome-sudoku
sudo apt remove remmina rhythmbox simple-scan libreoffice*

sudo apt-get autoremove

# Cheese libreoffice* remmina rhythmbox simplescan 
# optional
sudo apt-get install -y fonts-indic htop mailutils pigz parallel 
sudo apt-get install -y mailutils
sudo apt-get install -y python-pip

sudo apt-get install -y maven openjdk-8-jdk-headless  # Maven+java8 are needed to compile Joshua


# mailutils # Usefull to automatically send mails
# pigz  # faster "zip" tool
# parallel # to run commands in parallel
# emacs24 # one text editor...
# Maven required by Joshua


# fonts-indic # install fonts for telugu etc.
# htop # to watch processes running
pip install numpy numexpr cython tables theano ipdb

cd
# Nematus: NMT training
git clone https://github.com/rsennrich/nematus.git
# Moses: PBSMT training and decoding
git clone https://github.com/moses-smt/mosesdecoder
# AmuNMT: NMT decoding
git clone https://github.com/emjotde/amunmt.git
# Joshua: PBSMT (tree-based) training and decoding 
git clone https://github.com/apache/incubator-joshua joshua

# Indic corpora (~40'000 sentence parallel corpus, 6 indic language - English) 
wget http://homepages.inf.ed.ac.uk/miles/data/indic/indic-corpora.tar.gz

# TER (Translation error rate): MT evaluation
wget http://www.cs.umd.edu/~snover/tercom/tercom-0.7.25.tgz
# Meteor: MT evaluation 
wget http://www.cs.cmu.edu/~alavie/METEOR/download/meteor-1.5.tar.gz

# BPE scripts: (reduce vocabulory space)
git clone https://github.com/rsennrich/subword-nmt.git

cd
# Note that, if you want to use python 3, please change the following lines by
# sudo apt-get install -y python3-pip
# pip3 install jupyter

pip install jupyter
jupyter notebook


cd joshua
export JOSHUA=$(pwd)
# add this to your ~/.bashrc, too
echo "export JOSHUA=$JOSHUA" >> ~/.bashrc
 
# compile Joshua, run tests, and build the jar file
mvn package
#sudo apt-get install -y openjdk-8-jdk-headless
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> ~/.bashrc

source ~/.bashrc
  
# Download dependencies used for building and running models
bash download-deps.sh

cd nematus
sudo chown -R smt  /usr/local/lib/python2.7/dist-packages/
sudo chown -R smt  /usr/local/bin
python setup.py install

cd ~
cd mosesdecoder
./bjam -j 2 -a --with-mm


cd
cd amunmt
mkdir build
cd build
cmake ..
make -j 1

exit

########## CDEC ###########
git clone https://github.com/redpony/cdec.git
cd cdec
cmake -G 'Unix Makefiles'
wget http://data.cdec-decoder.org/cdec-spanish-demo.tar.gz
tar xzvf cdec-spanish-demo.tar.gz
cd cdec-spanish-demo/


# ---- experiments with indic corpora ---
cd
#wget http://homepages.inf.ed.ac.uk/miles/data/indic/indic-corpora.tar.gz
tar -xvzf indic-corpora.tar.gz
cd ~/parallel-corpora

# Launch Moses training on one language:
bash ~/Icon2016/labs/trainMoses.sh hi en


# tensorflow playground:
cd
git clone https://github.com/tensorflow/playground.git
cd playground
sudo sudo apt-get install -y npm
sudo apt-get install -y npm
sudo apt-get install -y nodejs-legacy
npm install
npm run serve-watch

# You can then look playground tensor flow locally on http://127.0.0.1:8081


# -------------------------------- install hindi corp --- train Moses model --
# Optional: Getting a hindi-English MT out of a bigger corpus (278'000 sentences)
cd
wget 'https://lindat.mff.cuni.cz/repository/xmlui/bitstream/handle/11858/00-097C-0000-0023-625F-0/hindencorp05.plaintext.gz'

# create a new directory
mkdir ~/hindencorp.en-hi
# Separate a trainset/devset/testset: we "shuffle" the lines
zcat ./hindencorp05.plaintext.gz  | shuf > ~/hindencorp.en-hi/corpus.txt
cd ~/hindencorp.en-hi
head -271885 ./corpus.txt > traincorpus
head -272885 ./corpus.txt|tail -1000 > devcorpus
tail -1000 ./corpus.txt > testcorpus

# Separate training corpus into English and Hindi
# Fourth column is the English text
cut -f 4 ./traincorpus | /home/smt/mosesdecoder/scripts/tokenizer/tokenizer.perl -l en ./traincorpus |~/mosesdecoder/scripts/tokenizer/lowercase.perl> trainset.en
# Fifth column is the Hindi text
cut -f 5 ./traincorpus | /home/smt/mosesdecoder/scripts/tokenizer/tokenizer.perl -l hi ./traincorpus |~/mosesdecoder/scripts/tokenizer/lowercase.perl> trainset.hi

# Separate testing corpus into English and Hindi
# Fourth column is the English text
cut -f 4 ./testcorpus | /home/smt/mosesdecoder/scripts/tokenizer/tokenizer.perl -l en ./testcorpus |~/mosesdecoder/scripts/tokenizer/lowercase.perl> testset.en
# Fifth column is the Hindi text
cut -f 5 ./testcorpus | /home/smt/mosesdecoder/scripts/tokenizer/tokenizer.perl -l hi ./testcorpus |~/mosesdecoder/scripts/tokenizer/lowercase.perl> testset.hi

# clean training and discard sentences longer than 40 words
/home/smt/mosesdecoder/scripts/training/clean-corpus-n.perl  trainset en hi tclean 1 40

/home/smt/mosesdecoder/bin/lmplz -o 3  -S 80% -T /tmp < ./tclean.en >text.en.arpa
~/mosesdecoder/scripts/training/train-model.perl --external-bin-dir ~/joshua/bin -root-dir . --corpus ./tclean --f hi --e en -lm 0:3:`pwd`/text.en.arpa
~/mosesdecoder/bin/moses -f model/moses.ini < testset.hi > output.en
/home/smt/mosesdecoder/scripts/generic/multi-bleu.perl ./testset.en < output.hi



# Char rnn simple:
cd
mkdir min-char-rnn
cd min-char-rnn
wget https://gist.githubusercontent.com/karpathy/d4dee566867f8291f086/raw/119a6930b670bced5800b6b03ec4b8cb6b8ff4ec/min-char-rnn.py
# Create English input (take English text from hinencorp)
cut -f 4  ../hindencorp.en-hi/corpus.txt|perl -pe 'print lc($_)' |sort -u > input.txt
python min-char-rnn.py

#### Char rnn with torch:
cd
git clone https://github.com/karpathy/char-rnn.git
cd char-rnn/
curl -s https://raw.githubusercontent.com/torch/ezinstall/master/install-deps | bash


cd
sudo apt-get install -y luarocks
git clone https://github.com/torch/distro.git ~/torch --recursive
cd ~/torch
yes | ./install.sh
source ~/.bashrc
export PATH="$PATH:/home/smt/torch/install/bin"
bash install-deps
luarocks install nn
luarocks install nngraph
luarocks install optim
 
cd ~/char-rnn
mkdir data/english
cut -f 4  ../hindencorp.en-hi/corpus.txt|perl -pe 'print lc($_)' |sort -u > data/english/input.txt

th train.lua -gpuid -1 -data_dir data/english -eval_val_every 1 -max_epoch 5

#### JOSHUA
echo "-- Trying to install Joshua --"

# Follow instructions given on page https://cwiki.apache.org/confluence/display/JOSHUA/Getting+Started
cd

#git clone https://github.com/apache/incubator-joshua joshua


# Download hadoop for Joshua to be able to run
cd
wget http://mirror.easyname.ch/apache/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz

tar xvzf hadoop-2.7.3.tar.gz
cd hadoop*
sudo ln -s /usr/local/hadoop /home/smt/hadoop-2.7.3
sudo ln -s /usr/local/bin/hadoop /home/smt/hadoop-2.7.3/bin/hadoop
hadoop fs -mkdir /home/smt/hadoopFS




# Install Indic NLP tools
git clone https://github.com/anoopkunchukuttan/indic_nlp_library.git
