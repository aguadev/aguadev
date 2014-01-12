#!/usr/bin/env bash

# Bootstraps Puppet and librarian-puppet on CentOS 6.x
# Tested on CentOS 6.4 64bit

set -e

REPO_URL="http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm"

if [ "$EUID" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if which puppet > /dev/null 2>&1; then
  echo "Puppet is already installed."
else
    # Install puppet labs repo
    echo "Configuring PuppetLabs repo..."
    repo_path=$(mktemp)
    wget --output-document="${repo_path}" "${REPO_URL}" 2>/dev/null
    rpm -i "${repo_path}" >/dev/null
    echo "Completed configuring PuppetLabs repo"

    # Install Puppet...
    echo "Installing puppet"
    yum install -y puppet > /dev/null
    echo "Completed puppet installation"
fi

#echo "Installing librarian-puppet"
PUPPET_DIR='/etc/puppet'
if [ `gem query --local | grep librarian-puppet | wc -l` -eq 0 ]; then
  gem install librarian-puppet
	echo "DOING librarian-puppet install --clean"
  cd $PUPPET_DIR && librarian-puppet install --clean
else
	echo "DOING librarian-puppet update"
  cd $PUPPET_DIR && librarian-puppet update
fi
echo "Completed librarian-puppet installation"
