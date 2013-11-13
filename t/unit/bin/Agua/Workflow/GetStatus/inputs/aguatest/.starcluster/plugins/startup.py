#!/usr/bin/env python
import os
import re
import string
import sys
import time
import posixpath
import subprocess


from starcluster.clustersetup import ClusterSetup
from starcluster.logger import log
from starcluster import utils

class NullDevice():
    def write(self, s):
        pass
    
class StartUp (ClusterSetup):

    """
    Configure startup scripts for master node and install perl modules
    """

    def __init__(self, root, privatekey, publiccert, cell, installdir, headnodeid, version):
        log.info("Running startup plugin")

        log.debug("StartUp.__init__    Initialising StartUp plugin.")
        log.debug("StartUp.__init__    root %s" % root)
        log.debug("StartUp.__init__    privatekey %s" % privatekey)        
        log.debug("StartUp.__init__    publiccert %s" % publiccert)        
        log.debug("StartUp.__init__    cell %s" % cell)
        log.debug("StartUp.__init__    installdir %s" % installdir)
        log.debug("StartUp.__init__    headnodeid %s" % headnodeid)
        log.debug("StartUp.__init__    version %s" % version)

        #### CONSTANTS
        self.resetdir = "/reset"
        log.debug("StartUp.__init__    self.resetdir %s" % self.resetdir)

        #### VARIABLES
        self.root = root
        self.privatekey = privatekey
        self.publiccert = publiccert
        self.cell = cell
        self.installdir = installdir
        self.headnodeid = headnodeid

    def run(self, nodes, master, user, user_shell, volumes):
        """
            Configure startup:
            
            -   Copy privatekey and publiccert to master directory: /reset
                
                (required later by resetMaster.pl to determine headnode IP)

            -   Copy resetMaster.pl script to master

            -   Edit /etc/rc.local to run resetMaster.pl at boot/restart


            resetMaster runs at boot and does the following:
            
             1. UPDATE MASTER IP:
                   MASTER HOSTNAME
                   MASTER IP AND DNS NAME IN /etc/hosts
             2. UPDATE SGE:
                   MASTER act_qmaster ON MASTER
                   HEADNODE act_qmaster ON HEADNODE
                   UPDATE MASTER DNSNAME IN SUBMIT/ADMIN HOSTS LIST
                   RESTART SGE
             4. UPDATE MOUNTS:
                   HEADNODE /etc/exports
                   MASTER /etc/fstab
                   RESTART HEADNODE AND MASTER NFS DAEMONS
                   MOUNT FILESYSTEMS ON MASTER
        """

        log.info("Running plugin: startup.StartUp")
        log.debug("StartUp.run    StartUp.run(nodes, master, user, user_shell, volumes")

        #### COPY resetMaster.pl TO MASTER
        self.copyScript(master)
        
        #### COPY KEYS TO MASTER
        self.copyKeys(master)

        #### ADD ENTRY IN MASTER /etc/rc.local TO RUN STARTUP SCRIPT
        self.editStartupScript("/etc/rc.local", master)
        
        log.info("Completed plugin startup")

    def editStartupScript(self, file, master):
        """
            Add entry in /etc/rc.local to run masterRestart.pl on boot
        """
        log.info("Adding entry to /etc/rc.local to run masterRestart on boot")
        log.debug("startup.StartUp.editStartupScript    self.installdir: %s ", self.installdir)
        if ( file == None or file == "" ):
            file = "/etc/rc.local"
        log.debug("startup.StartUp.editStartupScript    file: %s ", file)

        #### SET RUN resetMaster.pl COMMAND
        command = self.resetdir + "/resetMaster.pl " \
            + " --cell " + self.cell \
            + " --headnodeid " + self.headnodeid \
            + " --cgiscript " + "/cgi-bin/agua/reset.cgi"
        log.debug("startup.StartUp.editStartupScript    command: %s ", command)
        
        #### PRINT COMMAND TO FILE
        infilehandle = master.ssh.remote_file(file, 'r')
        contents = infilehandle.read()
        log.debug("startup.StartUp.editStartupScript    contents: %s ", contents)
        contents = string.replace(contents, "exit 0", "")
        contents = string.replace(contents, command, "")
        contents += command + "\n"
        contents += "\nexit 0\n"
        log.debug("startup.StartUp.editStartupScript    printing to %s contents: %s ", file, contents)

        outfilehandle = master.ssh.remote_file(file, 'w')
        outfilehandle.write(contents)
        outfilehandle.close()

    def copyScript(self, master):
        """
            Copy resetMaster.pl script to master
        """
        log.info("Copying key files to master")
        
        command = "mkdir -p " + self.resetdir
        log.info("startup.StartUp.copyScript    command: %s", command)
        master.ssh.execute(command)
        
        sourcefile = self.root + "/bin/scripts/resetMaster.pl"
        targetfile = self.resetdir + "/resetMaster.pl"
        sourcefile = self.root + "/bin/scripts/resetMaster.pl"
        targetfile = self.resetdir + "/resetMaster.pl"
        self.uploadToMaster(master, sourcefile, targetfile)

    def copyKeys(self, master):
        """
            Edit /etc/rc.local to run resetMaster.pl at boot/restart
        """
        log.info("Copying private key file to master")
        sourcefile = self.privatekey
        targetfile = self.resetdir + "/private.pem"
        self.uploadToMaster(master, sourcefile, targetfile)
        master.ssh.execute("chmod 600 " + targetfile)

        log.info("Copying public cert file to master")
        sourcefile = self.publiccert
        targetfile = self.resetdir + "/public.pem"
        self.uploadToMaster(master, sourcefile, targetfile)
        master.ssh.execute("chmod 600 " + targetfile)

    def uploadToMaster(self, master, sourcefile, targetfile):
        """
            Set headnode instance ID for later IP lookup
        """
        log.info("startup.uploadToMaster.editStartupScript    sourcefile: %s ", sourcefile)
        log.info("startup.uploadToMaster.editStartupScript    targetfile: %s ", targetfile)

        infilehandle = open(sourcefile, 'r')
        contents = infilehandle.read()
        outfilehandle = master.ssh.remote_file(targetfile, 'w')
        outfilehandle.write(contents)
        outfilehandle.close()

