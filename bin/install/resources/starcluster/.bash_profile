# .bash_profile
# User specific aliases and functions
#

#### MOUNTS
rpc () { rpcinfo -p | awk -F " " '{print $3 "\t" $4 "\t" $5}' | sort | uniq | grep -v proto; }

#### STARCLUSTER
alias sc='starcluster -c /nethome/admin/.starcluster/config sshmaster smallcluster'
alias stail=' echo >>  /tmp/starcluster-debug-root.log ; echo >>  /tmp/starcluster-debug-root.log ; date >>  /tmp/starcluster-debug-root.log ; echo >>  /tmp/starcluster-debug-root.log ; tail -f /tmp/starcluster-debug-root.log;'

#### AGUA
PATH=/agua/bin/apps/logic:$PATH
alias flow='/agua/bin/apps/logic/workflow.pl'

### SGE
export SGE_EXECD_PORT=63232;
export SGE_QMASTER_PORT=63231
export SGE_ROOT=/opt/sge6
export PATH=/opt/sge6/bin/lx24-amd64:$PATH

#### ec2
export PATH=/usr/bin:$PATH
export EC2_HOME=/usr/
export JAVA_HOME=/usr
export EC2_PRIVATE_KEY=/agua/conf/admin/.keypairs/private.pem
export EC2_CERT=/agua/conf/admin/.keypairs/public.pem
alias listec2='ls $EC2_HOME/bin/ec2-* | grep -v cmd'

# DATE
alias DATE='date'

# FIX DOS LINE ENDINGS
alias fle="perl -pi -e 's/\r//g' "
alias fle2="perl -pi -e 's/\r/\n/g' "

# turn on color file listing
export CLICOLOR=1

# ALIASES
alias perlenv="perl -e 'foreach my $key(sort keys(%ENV)){print qq|$key = $ENV{$key}\n|;}'"
alias pl='perl Makefile.PL'
alias tx='tar xvfz'
alias mk='make; make install'
alias perl='/usr/bin/perl'
alias q='qstat'
alias sqlite='sqlite3'
alias mod='chmod 755 *'
alias now='date "+DATE: %m/%d/%y%nTIME: %H:%M:%S"'
alias psg='ps aux | grep'
alias llhg='ls -alh | grep'
alias llg='ls -al | grep'
alias lg='ls | grep'
alias xpl='chmod 755 *.pl *.cgi *.t'
alias mq='mysql -u root -p'

alias em='emacs -nw'
alias me='emacs -nw'
alias gobash='emacs -nw ~/.bash_profile'
alias sobash='source ~/.bash_profile'
alias er='tail -f -n 100 /var/log/httpd/error_log'
alias myer='tail -100 /var/log/mysqld.log'
alias html='cd /var/www/html/agua/0.6'
alias cgi='cd /var/www/cgi-bin/agua/0.6'
alias cl='clear; ls; pwd'
alias apps='cd /data/apps'
alias updb='updatedb'

alias l='ls'
alias df='df -ah'
alias rm='rm -i'
alias mv='mv -i'
alias LL='ls -alh'
alias ll='ls -alh'
# -l = list view
# -a = all views, even hidden
# -h = human-readable sizes, e.g. 900B, 15K, 1.2MB

# keeps pico from line wrapping
alias pico="/usr/bin/pico -w"

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi
.