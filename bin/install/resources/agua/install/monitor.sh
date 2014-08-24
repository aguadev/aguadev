# install.sh

# 1. COPY FILES TO /etc

cd /agua/bin/install/resources/agua
sudo cp etc/init.d/monitor /etc/init.d
sudo cp etc/init/monitor.conf /etc/init
sudo cp etc/default/monitor /etc/default


# 2. COPY EXCUTEABLE TO /usr/bin

ln -s /agua/bin/daemon/monitor /usr/bin/monitor


# 3. RUN SERVICE

service monitor start

