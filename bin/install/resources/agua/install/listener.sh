# install.sh

# 1. COPY FILES TO /etc

cd /agua/bin/install/resources/agua
sudo cp etc/init.d/listener /etc/init.d
sudo cp etc/init/listener.conf /etc/init
sudo cp etc/default/listener /etc/default


# 2. COPY EXCUTEABLE TO /usr/bin

ln -s /agua/bin/daemon/listener /usr/bin/listener


# 3. RUN SERVICE

service listener start

