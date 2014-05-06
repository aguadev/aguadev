# install.sh

# 1. COPY FILES TO /etc

cd /agua/bin/install/resources/agua
sudo cp etc/init.d/master /etc/init.d
sudo cp etc/init/master.conf /etc/init
sudo cp etc/default/master /etc/default


# 2. COPY EXCUTEABLE TO /usr/bin

ln -s /agua/bin/daemon/master /usr/bin/master


# 3. RUN SERVICE

service master start

