# install.sh

# 1. COPY FILES TO /etc

cd /agua/bin/install/resources/agua
sudo cp etc/init.d/task /etc/init.d
sudo cp etc/init/task.conf /etc/init
sudo cp etc/default/task /etc/default


# 2. COPY EXCUTEABLE TO /usr/bin

ln -s /agua/bin/daemon/task /usr/bin/task


# 3. RUN SERVICE

service task start

