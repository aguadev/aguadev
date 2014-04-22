# install.sh

# 1. COPY FILES TO /etc

cd /agua/bin/install/resources/agua
sudo cp etc/init.d/agua /etc/init.d
sudo cp etc/init/agua.conf /etc/init
sudo cp etc/default/agua /etc/default


# 2. COPY EXCUTEABLE TO /usr/bin

ln -s /agua/bin/daemon/agua /usr/bin/agua


# 3. RUN SERVICE

service agua start

