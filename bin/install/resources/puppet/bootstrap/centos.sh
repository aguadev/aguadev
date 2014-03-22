#!/usr/bin/env bash

# Bootstraps Puppet and librarian-puppet on CentOS 6.x
# Tested on CentOS 6.4 64bit

set -e

REPO_URL="http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm"

if [ "$EUID" -ne "0" ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

# Install gem
echo "Installing gem..."
yum install -y rubygems >/dev/null

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

#### INSTALL MODULES
echo "Installing stahnma-epel"
puppet module install stahnma/epel --force
echo "Installing ripienaar/concat"
puppet module install ripienaar-concat
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
