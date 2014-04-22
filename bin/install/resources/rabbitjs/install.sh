# install.sh

# 1. COPY FILES TO /etc

cd /rabbitjs/bin/install/resources/rabbitjs
sudo cp etc/init.d/rabbitjs /etc/init.d
sudo cp etc/init/rabbitjs.conf /etc/init
sudo cp etc/default/rabbitjs /etc/default


# 2. COPY EXCUTEABLE TO /usr/bin

ln -s /rabbitjs/bin/daemon/rabbitjs /usr/bin/rabbitjs


# 3. RUN SERVICE

service rabbitjs start

