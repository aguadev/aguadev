#!/usr/bin/env bash
#
# This bootstraps Puppet on Ubuntu 12.04 LTS.
#
set -e

# Load up the release information
. /etc/lsb-release

REPO_DEB_URL="http://apt.puppetlabs.com/puppetlabs-release-${DISTRIB_CODENAME}.deb"

#--------------------------------------------------------------------
# NO TUNABLES BELOW THIS POINT
#--------------------------------------------------------------------
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# Do the initial apt-get update
echo "Initial apt-get update..."
apt-get update >/dev/null

# Install wget if we have to (some older Ubuntu versions)
echo "Installing wget..."
apt-get install -y wget >/dev/null

# Install gem
echo "Installing gem..."
apt-get install -y rubygems >/dev/null


if which puppet > /dev/null 2>&1; then
  echo "Puppet is already installed."
else

	# Install puppet
	echo "Installing puppet-module..."
	gem install puppet

	## Install the PuppetLabs repo
	#echo "Configuring PuppetLabs repo..."
	#repo_deb_path=$(mktemp)
	#wget --output-document="${repo_deb_path}" "${REPO_DEB_URL}" 2>/dev/null
	#dpkg -i "${repo_deb_path}" >/dev/null
	#apt-get update >/dev/null
	#
	## Install Puppet
	#echo "Installing Puppet..."
	#apt-get install -y puppet >/dev/null
	#echo "Completed puppet installation"
fi

# Install puppet-module
echo "Installing puppet-module..."
gem install puppet-module

echo "Installing librarian-puppet"
PUPPET_DIR='/etc/puppet'
if [ `gem query --local | grep librarian-puppet | wc -l` -eq 0 ]; then
	echo "gem install librarian-puppet"
	gem install librarian-puppet
	echo "cd $PUPPET_DIR; librarian-puppet install --clean"
	cd $PUPPET_DIR && librarian-puppet install --clean
else
	echo "cd $PUPPET_DIR; librarian-puppet update"
	cd $PUPPET_DIR && librarian-puppet update
fi
echo "Completed librarian-puppet installation"

# Install RubyGems for the provider
echo "Installing RubyGems..."
apt-get install -y rubygems >/dev/null
gem install --no-ri --no-rdoc rubygems-update
update_rubygems >/dev/null
