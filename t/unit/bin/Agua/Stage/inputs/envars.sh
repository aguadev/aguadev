#!/bin/bash

#### AUTHENTICATION
export ASSIGNEE=ucsc_biofarm
export KEYFILE=/root/annai-cghub.key
export REF_SEQ=/opt/reference/genome.fa.gz
export WORK_DIR=/mnt

#### FILE SYSTEM
export REF_SEQ=/pancanfs/reference/genome.fa.gz
export WORK_DIR=/mnt

#### GLIBC
export PATH=/mnt/data/apps/libs/boost/1.39.0/libs:$PATH

#### ENVIRONMENT VARIABLES
export PATH=/agua/apps/pcap/0.3.0/bin:$PATH
export PATH=/agua/apps/pcap/PCAP-core/install_tmp/bwa:$PATH
export PATH=/agua/apps/pcap/PCAP-core/install_tmp/samtools:$PATH
export PATH=/agua/apps/pcap/PCAP-core/bin:$PATH
export PATH=/agua/apps/pcap/PCAP-core/install_tmp/biobambam/src:$PATH

#### PYTHON PATH
export PYTHONPATH=/usr/local/lib/python2.7/:$PYTHONPATH
export PYTHONPATH=/usr/local/lib/python2.7/lib-dynload:$PYTHONPATH

#### PERL5LIB
export PERL5LIB=
export PERL5LIB=/agua/apps/pcap/0.3.0/lib:$PERL5LIB
export PERL5LIB=/agua/apps/pcap/0.3.0/lib/perl5:$PERL5LIB
export PERL5LIB=/agua/apps/pcap/0.3.0/lib/perl5/x86_64-linux-gnu-thread-multi:$PERL5LIB
export PERL5LIB=/agua/apps/pcap/PCAP-core/lib:$PERL5LIB
export PERL5LIB=/agua/apps/pcap/0.3.0/lib/perl5/x86_64-linux-gnu-thread-multi:$PERL5LIB

#### LD_LIBRARY_PATH
export LD_LIBRARY_PATH=
export LD_LIBRARY_PATH=/mnt/data/apps/libs/boost/1.39.0/libs:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/agua/apps/biobambam/libmaus-0.0.108-release-20140319092837/src/.libs:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/agua/apps/pcap/PCAP-core/install_tmp/libmaus/src/.libs:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/agua/apps/pcap/PCAP-core/install_tmp/snappy/.libs:$LD_LIBRARY_PATH


