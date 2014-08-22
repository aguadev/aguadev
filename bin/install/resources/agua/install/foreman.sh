# install.sh

# 1. COPY FILES TO /etc

cd /agua/bin/install/resources/agua
sudo cp etc/init.d/foreman /etc/init.d
sudo cp etc/init/foreman.conf /etc/init
sudo cp etc/default/foreman /etc/default


# 2. COPY EXCUTEABLE TO /usr/bin

ln -s /agua/bin/daemon/foreman /usr/bin/foreman


# 3. RUN SERVICE

service foreman start

