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
fi

# Install puppet-module
echo "Installing puppet-module..."
gem install puppet-module

#### INSTALL MODULES
echo "Installing stahnma-epel"
puppet module install stahnma/epel --force
echo "Installing puppetlabs-stdlib"
puppet module install puppetlabs-stdlib --force
echo "Installing puppetlabs-mysql"
puppet module install puppetlabs-mysql --force
echo "Installing puppetlabs-apache"
puppet module install puppetlabs-apache --force
echo "Installing puppetlabs-rabbitmq"
puppet module install puppetlabs-rabbitmq --force
echo "Installing puppetlabs-nodejs"
puppet module install puppetlabs-nodejs --force
echo "Installing puppetlabs-java"
puppet module install puppetlabs-java --force
