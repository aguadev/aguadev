#!/bin/bash

done_message () {
    if [ $? == 0 ]; then
        echo " done."
        if [ "x$1" != "x" ]; then
            echo $1;
        fi
    else
        echo " failed.  See setup.log file for error messages." $2
        echo "    Please check INSTALL file for items that should be installed by a package manager"
        exit 1
    fi
}

if [ "$#" -ne "2" ] ; then
	echo "Usage:"
	echo
	echo "$0 installation_path module_file"
	echo
	exit 0;
fi

INST_PATH=$1;
MODULE_FILE=$2;

echo "Installing modules to: $INST_PATH"

# get current directory
INIT_DIR=`pwd`

# cleanup inst_path
mkdir -p $INST_PATH/bin
cd $INST_PATH
INST_PATH=`pwd`
cd $INIT_DIR

# make sure that build is self contained
unset PERL5LIB;
ARCHNAME=`perl -e 'use Config; print $Config{archname};'`;
PERLROOT=$INST_PATH/lib/perl5
PERLARCH=$PERLROOT/$ARCHNAME
export PERL5LIB="$PERLROOT:$PERLARCH";

#create a location to build dependencies
SETUP_DIR=$INIT_DIR/install_tmp
mkdir -p $SETUP_DIR

# re-initialise log file
echo > $INIT_DIR/setup.log;


# log information about this system
(
    echo '============== System information ====';
    set -x;
    lsb_release -a;
    uname -a;
    sw_vers;
    system_profiler;
    grep MemTotal /proc/meminfo;
    set +x;
    echo; echo;
) >>$INIT_DIR/setup.log 2>&1;


#perlmods=( "Module::Build" "File::ShareDir" "File::ShareDir::Install" "Const::Fast" )
#for i in "${perlmods[@]}";
#do

export PERL_MM_USE_DEFAULT=1
export PERL_AUTOINSTALL=--defaultdeps

#printenv

perlmods=$(<$MODULE_FILE)
for i in $perlmods;
do
	echo "[$i]"
  echo -n "Installing build prerequisite $i..."

	echo "/agua/apps/perl/5.18.2/bin/perl /usr/bin/cpanm  --no-interactive --notest -v -l $INST_PATH $i"

  if( perl -I$INST_PATH/lib/perl5 -Mlocal::lib=$INST_PATH -M$i -e 1 >& /dev/null); then
      echo $i already installed.
  else
    (

		echo "INSTALLING"
		echo "/agua/apps/perl/5.18.2/bin/perl /usr/bin/cpanm  --no-interactive --notest -v -l $INST_PATH $i"

      set +e;
#      /agua/apps/perl/5.18.2/bin/perl /usr/bin/cpanm  --configure-args="-y" --install-args  --no-interactive --notest -v -l $INST_PATH $i;
		

	
	if ( /agua/apps/perl/5.18.2/bin/perl /usr/bin/cpanm  --no-interactive --notest -v -l $INST_PATH $i); then
		echo "Standard install succeeded"
	#	else
	#		echo "/agua/apps/perl/5.18.2/bin/perl /usr/bin/cpanm  --configure-args=\"-y\"  --no-interactive --notest -v -l $INST_PATH $i"
	#		if [[ `/agua/apps/perl/5.18.2/bin/perl /usr/bin/cpanm  --configure-args="-y"  --no-interactive --notest -v -l $INST_PATH $i;` -eq 0 ]]; then
	#			echo "Installed with --configure-args"
	#		#      elif [[ `/agua/apps/perl/5.18.2/bin/perl /usr/bin/cpanm  --configure-args="-y" --install-args  --no-interactive --notest -v -l $INST_PATH $i;` ]]; then
	#		#	  echo "Installed with --configure-args=\"-y\" --install-args=\"-y\""
	#			#  else
	#			#	  echo "Failed to install"
	#		
	#		else
	#			echo "Failed to install"
	#		fi

	else
		echo "Failed to install"	
	fi

#      if [ $? == 0 ]; then
#	  echo "Doing cpanm install without --configure-args"
#	  /agua/apps/perl/5.18.2/bin/perl /usr/bin/cpanm   --no-interactive --notest -v -l $INST_PATH $i;
#      fi

      set -e;
#      /agua/apps/perl/5.18.2/bin/perl /usr/bin/cpanm  --configure-args="-y" --install-args="-y"  --no-interactive --notest -v -l $INST_PATH $i;
#      /agua/apps/perl/5.18.2/bin/perl /usr/bin/cpanm  --configure-args="-y"  --no-interactive --notest -v -l $INST_PATH $i;
      echo; echo;
    ) >>$INIT_DIR/setup.log 2>&1;
    done_message "" "Failed during installation of $i.";
  fi
done

echo `perl -e 'use MooX'`
