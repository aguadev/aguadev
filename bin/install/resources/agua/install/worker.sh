# install.sh

# 1. COPY FILES TO /etc

cd /agua/bin/install/resources/agua
sudo cp etc/init.d/worker /etc/init.d
sudo cp etc/init/worker.conf /etc/init
sudo cp etc/default/worker /etc/default


# 2. COPY EXCUTEABLE TO /usr/bin

ln -s /agua/bin/daemon/worker /usr/bin/worker


# 3. RUN SERVICE

service worker start

