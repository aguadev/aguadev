#!/usr/bin/env python
import os
import re
import string
import sys
import time
import posixpath
import subprocess

etchosts_template = """127.0.0.1       localhost

# The following lines are desirable for IPv6 capable hosts                     ::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts

"""

from starcluster.clustersetup import ClusterSetup
from starcluster.logger import log
from starcluster import utils

class NullDevice():
    def write(self, s):
        pass
    
class CreateCell (ClusterSetup):
    """
    Configure a custom SGE cell for a StarCluster cluster
    """
    def __init__(self, privatekey, publiccert, cell, execdport, qmasterport, root, slots):
        log.info("Loaded plugin: sge.CreateCell")

        log.debug("sge.CreateCell.__init__    Initialising CreateCell plugin.")
        log.debug("sge.CreateCell.__init__    privatekey %s" % privatekey)
        log.debug("sge.CreateCell.__init__    publiccert %s" % publiccert)
        log.debug("sge.CreateCell.__init__    cell %s" % cell)
        log.debug("sge.CreateCell.__init__    execdport %s" % execdport)
        log.debug("sge.CreateCell.__init__    qmasterport %s" % qmasterport)
        log.debug("sge.CreateCell.__init__    root %s" % root)
        log.debug("sge.CreateCell.__init__    slots %s" % slots)
        
        self.headgroup = "default"
        self.privatekey = privatekey
        self.publiccert = publiccert
        self.cell = cell
        self.execdport = execdport
        self.qmasterport = qmasterport
        self.root = root
        self.slots = slots

        #""" SET HEAD NODE'S ROOT PATH TO SGE BINARIES """
        #rootpath = os.environ['ROOTPATH'];
        #rootpath = re.sub(r'^.', '', rootpath)
        #log.info("rootpath: %s", rootpath)
        #self.rootpath = rootpath
        
        os.environ['SGE_ROOT'] = root
        os.environ['SGE_CELL'] = cell
        os.environ['SGE_QMASTER_PORT'] = qmasterport
        os.environ['SGE_EXECD_PORT'] = execdport

    def run(self, nodes, master, user, user_shell, volumes):
        """
            Mount NFS shares on master and all nodes
        """
    
        #### SET ROOT PATH
        self.masterbinroot = self.getRemoteBinRoot(master)
        self.localbinroot = self.getLocalBinRoot()
        
        ##### OPEN NEW PORTS ON EC2 ON HEAD
        self.openSgePorts()
        
        #### CREATE NEW CELL DIRECTORY ON HEAD AND MASTER/NODES
        self.copyCellOnHead()
        self.copyCell(master)
        
        #### SET MASTER HOSTNAME AS INTERNAL IP
        self.setMasterHostname(master)
        
        #### SET HEADNODE HOSTNAME AS INTERNAL IP
        self.setHeadHostname()
        
        #### SET MASTER act_qmaster AS MASTER INTERNAL IP
        self.setMasterActQmaster(master)
        
        #### SET MASTER INTERNAL IP IN /etc/hosts
        self.setMasterEtcHosts(master)
        
        #### START SGE ON MASTER
        self.restartSge(master)
        
        #### ADD ENVIRONMENT VARIABLES TO /etc/profile ON MASTER/NODES
        for node in nodes:
           self.addEnvarsToProfile(node)
        
        #### SET MASTER AS SUBMIT AND ADMIN HOST
        self.setMasterSubmit(master)
        
        #### SET HEADNODE qmaster_info AS QUICK LOOKUP FOR MASTER INFO
        self.setMasterInfo(master)
        
        #### SET MASTER'S IP ADDRESS IN act_qmaster FILE ON HEAD
        self.updateHeadActQmaster(master)
        
        #### SET HEAD AS SUBMIT AND ADMIN HOST
        self.setHeadSubmit(master)

        #### INSTEAD OF 'master', USE MASTER INTERNAL IP IN @allhosts
        self.addMasterToAllHosts(master)

        ##### RESTART SGE ON MASTER/NODES
        for node in nodes:
            self.restartSge(node)
        
        ####  SCHEDULING INFO
        self.enableSchedulingInfo()
        
        #### ADD threaded PARALLEL ENVIRONMENT ON MASTER
        self.addParallelEnvironment(master)

        #### ADD NODES TO @allhosts GROUP
        for node in nodes:
            if node.alias != "master":
                self.addToAllhosts(node, master)
        
        ##### RESTART SGE ON MASTER/NODES
        for node in nodes:
            self.restartSge(node)
        
        #### REMOVE DEFAULT all.q QUEUE
        self.removeAllq()
        
        log.info("Completed plugin sge")

    def getRemoteBinRoot(self, node):
        """
            Return the CPU architecture-dependent path to the SGE binaries
            NB: Assumes 64-bit system
        """
        log.info("sge.CreateCell.getRemoteBinBoot    Getting root path for node: %s", node.alias)
        response = node.ssh.execute("grep vendor_id	/proc/cpuinfo")
        vendorid = response[0]
        log.debug("sge.CreateCell.getRemoteBinBoot    vendorid: %s", vendorid)
        
        #### ASCERTAIN IF CPU IS INTEL TYPE (ELSE, MUST BE AMD TYPE)
        intel = self.isIntel(vendorid)
        log.debug("sge.CreateCell.getRemoteBinBoot    intel: %s", intel)

        #### GET BIN DIR SUBDIRS
        command = "ls " + self.root + "/bin"
        log.debug("sge.CreateCell.getRemoteBinBoot    command: %s", command)
        files = node.ssh.execute(command)
        log.debug("sge.CreateCell.getRemoteBinBoot    files: %s", files)

        binroot = self.getBinRoot(intel, files);        
        log.info("sge.CreateCell.getRemoteBinBoot    binroot: %s", binroot)    
        if binroot == "":
            log.info("sge.CreateCell.getRemoteBinBoot    sge.CreateCell.getRemoteBinRoot    Can't find root path for vendorid: %s", vendorid)
        
        return binroot

    def getLocalBinRoot(self):
        """
            Return the CPU architecture-dependent path to the SGE binaries
            NB: Assumes 64-bit system
        """
        log.info("sge.CreateCell.setLocalBinBoot    Getting root path on local machine")
        p = os.popen("grep vendor_id	/proc/cpuinfo")
        vendorid = p.read()
        log.debug("sge.CreateCell.setLocalBinBoot    vendorid: %s", vendorid)

        #### ASCERTAIN IF CPU IS INTEL TYPE (ELSE, MUST BE AMD TYPE)
        intel = self.isIntel(vendorid)
        log.debug("sge.CreateCell.setLocalBinBoot    intel: %s", intel)

        #### GET BIN DIR SUBDIRS
        command = "ls " + self.root + "/bin"
        log.debug("sge.CreateCell.setLocalBinBoot    command: %s", command)
        p = os.popen(command)
        filelist = p.read();
        files   = filelist.split("\n");
        log.debug("sge.CreateCell.setLocalBinBoot    files: %s", files)

        binroot = self.getBinRoot(intel, files);        
        log.info("sge.CreateCell.setLocalBinBoot    binroot: %s", binroot)    
        if binroot == "":
            log.info("sge.CreateCell.setLocalBinRoot    Can't find root path for vendorid: %s", vendorid)

        return binroot

    def isIntel(self, vendorid):
        log.info("sge.CreateCell.isIntel    vendorid: %s", vendorid)

        match = re.search('vendor_id\s+:\s+GenuineIntel\s*', vendorid)
        log.info("sge.CreateCell.isIntel     match: %s", match)
        
        if match == None:
            return False
        
        return True

    def getBinRoot(self, intel, files):
        binroot = ""
        for file in files:
            if intel:
                if file == "lx24-x86":
                    binroot = self.root + "/bin/lx24-x86"
                    break
                elif file == "linux-x64":
                    binroot = self.root + "/bin/linux-x64"
                    break
            else:
                if file == "lx24-amd64":
                    binroot = self.root + "/bin/lx24-amd64"
                    break
                elif file == "linux-x64":
                    binroot = self.root + "/bin/linux-x64"
                    break

        #log.info("binroot: %s", binroot)    

        return binroot

    def openSgePorts(self):
        """
            Open the particular SGE qmaster and execd daemon ports for this cluster
        """
        log.info("Opening SGE qmaster and execd ports")
        qmasterport = self.qmasterport
        execdport = self.execdport
        cluster = self.cell

        envars = self.exportEnvironmentVars()
        
        log.debug("sge.CreateCell.openSgePorts    qmasterport; %s", qmasterport)
        log.debug("sge.CreateCell.openSgePorts    execdport; %s", execdport)
        log.debug("sge.CreateCell.openSgePorts    envars; %s", envars)

        #### SET EC2 KEY FILE ENVIRONMENT VARIABLES
        ec2vars = "export EC2_PRIVATE_KEY=" + self.privatekey + "; "
        ec2vars += "export EC2_CERT=" + self.publiccert + "; "
        
        # HEAD NODE (I.E., NOT MASTER OR NODE)
        commands = [
            ec2vars + 'ec2-authorize @sc-' + cluster + ' -p ' + execdport + ' -P tcp',
            ec2vars + 'ec2-authorize @sc-' + cluster + ' -p ' + execdport + ' -P udp',
            ec2vars + 'ec2-authorize @sc-' + cluster + ' -p ' + qmasterport + ' -P tcp',
            ec2vars + 'ec2-authorize @sc-' + cluster + ' -p ' + qmasterport + ' -P udp',
            ec2vars + 'ec2-authorize ' + self.headgroup + ' -p ' + execdport + ' -P tcp',
            ec2vars + 'ec2-authorize ' + self.headgroup + ' -p ' + execdport + ' -P udp',
            ec2vars + 'ec2-authorize ' + self.headgroup + ' -p ' + qmasterport + ' -P tcp',
            ec2vars + 'ec2-authorize ' + self.headgroup + ' -p ' + qmasterport + ' -P udp'
        ]
        
        for command in commands:
            self.runSystemCommand(command);

    def runSystemCommand(self, command):
        log.info(command)
        os.system(command)
        
    def setMasterActQmaster(self, master):
        """
            Set master hostname as INTERNAL IP to disambiguate from other
            cluster 'master' nodes given multiple clusters
        """
        log.info("Setting act_qmaster file contents")

        hostname = self.getHostname(master)
        act_qmaster = self.root + "/" + self.cell + "/common/act_qmaster"
        command = "echo '" + hostname + "' > " + act_qmaster
        log.debug("sge.CreateCell.setMasterActQmaster    command: %s", command)
        master.ssh.execute(command)

    def setMasterHostname(self, master):
        """
            Set master hostname as internal IP to disambiguate
            
            from other 'master' nodes given multiple clusters
        """
        log.info("Setting master hostname")

        hostname = self.getHostname(master)
        command = "hostname " + hostname
        log.info("sge.CreateCell.setMasterHostname    command: %s", command)
        master.ssh.execute(command)
        
        command = "echo '" + hostname + "' > /etc/hostname"
        log.info("sge.CreateCell.setMasterHostname    command: %s", command)
        master.ssh.execute(command)

    def setHeadHostname(self):
        """
            Set master hostname as internal IP to disambiguate
            
            from other 'master' nodes given multiple clusters
        """
        log.info("Setting headnode hostname")

        command = "curl -s http://169.254.169.254/latest/meta-data/local-hostname"
        hostname = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True).stdout.read()
        log.info("sge.CreateCell.setHeadnodeHostname    hostname: %s", hostname)
        
        command = "hostname " + hostname
        log.info("sge.CreateCell.setHeadnodeHostname    command: %s", command)
        os.system(command)
        
        command = "echo '" + hostname + "' > /etc/hostname"
        log.info("sge.CreateCell.setHeadnodeHostname    command: %s", command)
        os.system(command)

    def getHostname(self, master):
        log.info("sge.CreateCell.getHostname    returning hostname: %s", master.private_dns_name)
        return master.private_dns_name
    
    def setMasterEtcHosts (self, master):
        log.info("Adding master hostname to own /etc/hosts")
        
        envars = self.exportEnvironmentVars()
        command = "cat /etc/hosts"  
        log.debug("sge.CreateCell.setMasterEtcHosts     command: %s" % command)
        etchosts = etchosts_template
        
        ip_address  = master.ip_address
        dns_name    = master.dns_name

        insert = master.private_ip_address
        insert += "\t"
        insert += self.getHostname(master)
        insert += "\t"
        insert += "localhost"
        etchosts += insert + "\n"

        log.debug("sge.CreateCell.setMasterEtcHosts    AFTER etchosts: %s", etchosts)

        etchosts_file = master.ssh.remote_file("/etc/hosts")
        print >> etchosts_file, etchosts
        etchosts_file.close()
        
        # DEPRECATED:
        #command = "/etc/init.d/networking restart"
        command = "sh -c \"ifdown eth0 && ifup eth0\""
        log.debug("sge.CreateCell.setMasterEtcHosts    command: %s", command)
        result = master.ssh.execute(command)
        log.debug("sge.CreateCell.setMasterEtcHosts    result: %s", result)

    def setMasterSubmit(self, master):
        hostname = self.getHostname(master)
        envars = self.exportEnvironmentVars()
        
        add_submit      = envars + self.masterbinroot + '/qconf -as ' + hostname
        add_admin       = envars + self.masterbinroot + '/qconf -ah ' + hostname
        log.debug("sge.CreateCell.setMasterSubmit    add_submit: %s", add_submit)
        master.ssh.execute(add_submit)
        log.debug("sge.CreateCell.setMasterSubmit    add_admin: %s", add_admin)
        master.ssh.execute(add_admin)
        
    def addMasterToAllHosts (self, master):
        log.info("sge.CreateCell.addMasterToAllHosts    Replacing 'master' with master INTERNAL IP in @allhosts")
        
        envars = self.exportEnvironmentVars()
        
        command = envars + self.localbinroot + "/qconf -shgrp @allhosts"  
        log.info("sge.CreateCell.addMasterToAllHosts     command: %s" % command)
        
        allhosts_template = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True).stdout.read()
        log.info("sge.CreateCell.addMasterToAllHosts    BEFORE allhosts_template: %s", allhosts_template)

        #### GET hostname
        hostname = self.getHostname(master)       

        #### REMOVE master AND hostname IF EXISTS
        match = "master"
        allhosts_template = string.replace(allhosts_template, "NONE", '')
        allhosts_template = string.replace(allhosts_template, match, '')
        allhosts_template = string.replace(allhosts_template, hostname, '')
        
        #### ADD hostname
        allhosts_template = allhosts_template.strip('\s\n\r')
        allhosts_template += " " + hostname
        #allhosts_template = re.sub('\s+$/s', '', allhosts_template)
        log.info("sge.CreateCell.addMasterToAllHosts    AFTER allhosts_template: %s", allhosts_template)
        filename = "/tmp/" + self.cell + "-allhosts.txt"
        allhosts_file = open(filename, 'w')
        print >> allhosts_file, allhosts_template
        allhosts_file.close()
        log.info("sge.CreateCell.addMasterToAllHosts    printed filename: %s", filename)
        set_command = envars + self.localbinroot + "/qconf -Mhgrp " + filename
        log.info("sge.CreateCell.addMasterToAllHosts    set_command: %s" % set_command)
        os.system(set_command)

    def addToAllhosts(self, node, master):
        """
            Add host to @allhosts group to enable it to be an execution host
        """
        log.info("Add %s to @allhosts group", node.alias)
        
        os.environ['SGE_ROOT'] = self.root
        os.environ['SGE_CELL'] = self.cell
        os.environ['SGE_QMASTER_PORT'] = self.qmasterport
        os.environ['SGE_EXECD_PORT'] = self.execdport
        
        hostname = node.alias
        #if node.alias == "master":
        #    hostname = self.getHostname(master)
        
        command = self.masterbinroot + "/qconf -aattr hostgroup hostlist " + hostname + " @allhosts >> /tmp/allhosts.out; "
        log.info("sge.addToAllhosts    command: %s", command)

        envars = self.exportEnvironmentVars()

        original_stdout = sys.stdout
        sys.stdout = NullDevice()  
        master.ssh.execute(envars + command)
        sys.stdout = original_stdout

    def setHeadSubmit(self, master):
        """
            Add head node to submit hosts and admin hosts lists
        """
        log.info("Adding head node to submit hosts and admin hosts lists")

        #### SET HEAD NODE INTERNAL IP
        self.getHeadIp();

        envars = self.exportEnvironmentVars()
        
        add_submit      = envars + self.masterbinroot + '/qconf -as ' + head_ip
        add_admin       = envars + self.masterbinroot + '/qconf -ah ' + head_ip

        log.debug("sge.CreateCell.setHeadSubmit    %s", add_submit)
        master.ssh.execute(add_submit)
        log.debug("sge.CreateCell.setHeadSubmit    %s", add_admin)
        master.ssh.execute(add_admin)

    def getHeadIp(self):
        log.info("sge.CreateCell.getHeadIp    Getting headnode internal IP")
        p = os.popen('curl -s http://169.254.169.254/latest/meta-data/instance-id');
        instanceid = p.read()
        log.debug("sge.CreateCell.getHeadIp    instanceid: %s" % instanceid)
        command = "ec2-describe-instances -K " + self.privatekey \
            + " -C " + self.publiccert \
            + " " + instanceid
        log.debug("sge.CreateCell.getHeadIp    command: %s" % command)
        p = os.popen(command);
        reservation = p.read()
        log.debug("sge.CreateCell.getHeadIp    reservation: %s" % reservation)

        instance = reservation.split("INSTANCE")[1];
        log.debug("sge.CreateCell.getHeadIp    instance: %s" % instance)
        instanceRow = instance.split('\t')
        self.head_ip = instanceRow[17]
        log.info("sge.CreateCell.getHeadIp    self.head_ip: %s" % self.head_ip)

    def removeAllq (self):
        """
            Delete default 'all.q' queue
        """
        log.info("sge.CreateCell.removeAllq    Removing the default 'all.q' queue")
        envars = self.exportEnvironmentVars()
        
        command = envars + self.localbinroot + "/qconf -dq all.q"
        log.debug("sge.CreateCell.removeAllq     command: %s" % command)
        os.system(command)

    def addEnvarsToProfile(self, node):
        """
            Add environment variables (SGE_CELL, ports, etc.) to /etc/profile
        """
        log.info("Adding environment variables to /etc/profile")
        envars = self.exportEnvironmentVars();
        log.debug("sge.CreateCell.addEnvarsToProfile    envars: echo '%s' >> /etc/profile", envars)
        node.ssh.execute("echo '" + envars + "' >> /etc/profile")
        
    def enableSchedulingInfo(self):
        """
            Enable job scheduling info output for 'qstat -j'
        """
        log.info("Enabling job scheduling info")

        envars = self.exportEnvironmentVars()
        log.debug(envars + self.masterbinroot + "/qconf -ssconf")
        queue_template = subprocess.Popen(envars + self.masterbinroot + "/qconf -ssconf", stdout=subprocess.PIPE, shell=True).stdout.read()
        log.debug("sge.CreateCell.enableSchedulingInfo    BEFORE queue_template: %s", queue_template)

        match = "schedd_job_info                   false"
        insert = "schedd_job_info                   true"
        queue_template = string.replace(queue_template, match, insert)
        log.debug("sge.CreateCell.enableSchedulingInfo    AFTER queue_template: %s", queue_template)

        pid = os.getpid()
        filename = "/tmp/queue-" + str(os.getpid()) + ".txt"
        queue_file = open(filename, 'w')
        print >> queue_file, queue_template
        queue_file.close()
        
        cmd = envars + self.masterbinroot + "/qconf -Msconf " + filename
        log.debug(cmd)
        os.system(cmd)
        remove = "rm -fr " + filename
        log.debug(remove)
        os.system(remove)

    def addParallelEnvironment(self, master):
        """
            Add 'threaded' parallel environment
        """
        log.info("Adding 'threaded' parallel environment")

        sge_pe_template = """
        pe_name           threaded
        slots             %s
        user_lists        NONE
        xuser_lists       NONE
        start_proc_args   /bin/true
        stop_proc_args    /bin/true
        allocation_rule   $pe_slots
        control_slaves    TRUE
        job_is_first_task FALSE
        urgency_slots     min
        accounting_summary FALSE
        """
        
        log.debug("addParallelEnvironment    sge_pe_template: %s", sge_pe_template)
        
        #### PRINT TEMPLATE FILE
        pe_file = master.ssh.remote_file("/tmp/pe.txt")
        print >> pe_file, sge_pe_template % 99999
        pe_file.close()
        
        envars = self.exportEnvironmentVars()
        
        master.ssh.execute(envars + self.masterbinroot + "/qconf -Ap %s &> /tmp/pe.out" % pe_file.name)
        master.ssh.execute(envars + self.masterbinroot + '/qconf -mattr queue pe_list "threaded" all.q &> /tmp/pe2q.out')

    def setHeadSubmit(self, master):
        """
            Add head node to submit and admin hosts lists on master
        """
        log.info("Adding head node to submit hosts and admin hosts lists")

        #### SET HEAD NODE INTERNAL IP
        self.getHeadIp();

        envars = self.exportEnvironmentVars()
        
        add_submit      = envars + self.masterbinroot + '/qconf -as ' + self.head_ip
        add_admin       = envars + self.masterbinroot + '/qconf -ah ' + self.head_ip

        log.info("sge.CreateCell.setHeadSubmit    %s", add_submit)
        master.ssh.execute(add_submit)
        log.info("sge.CreateCell.setHeadSubmit    %s", add_admin)
        master.ssh.execute(add_admin)
        
    def restartSge(self, node):
        """
            Restart SGE qmaster (master) and execd (master + nodes) daemons
        """
        log.info("Restarting SGE qmaster and execd daemons")

        binroot = self.getRemoteBinRoot(node)
        log.info("CreateCell.restartSge    binroot: %s", binroot)

        envars = self.exportEnvironmentVars()
        stop_execd      = envars + binroot + '/qconf -ke all'
        stop_qmaster    = envars + binroot + '/qconf -km'
        start_qmaster   = envars + binroot + '/sge_qmaster'
        start_execd     = envars + binroot + '/sge_execd'
        
        sleep = 1
        log.info("sge.CreateCell.restartSge    Doing RESTART SGE: %s (%s)", node.alias, node.private_ip_address)

        #### KILL ANY LINGERING TERMINATED PROCESSES    
        killall = "/bin/ps aux | grep sgeadmin | cut -c9-14 | xargs -n1 -iPID /bin/kill -9 PID &> /dev/null"
        log.info(killall)
        node.ssh.execute(killall, True, False, True)
        killall = "/bin/ps aux | grep root | grep sge | cut -c9-14 | xargs -n1 -iPID /bin/kill -9 PID &> /dev/null"
        log.info(killall)
        node.ssh.execute(killall, True, False, True)
    
        log.info("sge.CreateCell.restartSge    node.alias: %s", node.alias)
        if node.alias == "master":            
            time.sleep(float(sleep))
            log.info("sge.CreateCell.restartSge    %s", start_qmaster)
            node.ssh.execute(start_qmaster)

        log.info("sge.CreateCell.restartSge    %s", start_execd)
        node.ssh.execute(start_execd)

    def settingsCommand(self):
        target  =   self.root + "/" + self.cell + "/common"
        cmd     =   'cd ' + target + '; '
        cmd     +=  self.exportEnvironmentVars()
        cmd     +=  self.root + '/util/create_settings.sh ' + target
        log.debug("sge.CreateCell.createSettings    cmd: %s", cmd)
        return cmd

    def createSettings(self, node):
        """
            Generate settings.sh file containing SGE_CELL, SGE_ROOT and port info
        """    
        log.info("Generating settings.sh file")
        log.debug("sge.CreateCell.createSettings    CreateCell.createSettings(master)")
        cmd = self.settingsCommand()
        log.debug("sge.CreateCell.createSettings    cmd: %s", cmd)
        node.ssh.execute(cmd)

    def exportEnvironmentVars(self):
        vars    =   'export SGE_ROOT=' + self.root + '; '
        vars    +=  'export SGE_CELL=' + self.cell + '; '
        vars    +=  'export SGE_QMASTER_PORT=' + self.qmasterport + '; '
        vars    +=  'export SGE_EXECD_PORT=' + self.execdport + '; '
        return vars

    def updateHeadIp(self):
        """
            Set hostname as head_ip (in case has changed due to reboot)
        """
        log.info("Updating hostname on head node")

        log.debug("sge.CreateCell.updateHeadIp    self.head_long_ip: %s", self.head_long_ip)
        cmd = "hostname " + self.head_long_ip
        log.debug("sge.CreateCell.updateHeadIp    cmd: %s", cmd)
        os.system(cmd)
    
    def updateHeadActQmaster(self, master):
        """
            Replace 'master' with 'ip-XXX-XXX-XXX-XXX' hostname in act_qmaster file
        """
        log.info("Updating act_qmaster file")
        log.debug("sge.CreateCell.updateHeadActQmaster    CreateCell.updateHeadActQmaster(nodes)")

        target      =   self.root + "/" + self.cell
        act_qmaster =   target + "/common/act_qmaster"
        log.debug("sge.CreateCell.updateHeadActQmaster    act_qmaster: %s", act_qmaster)

        hostname   =   self.getHostname(master)
        log.debug("sge.CreateCell.updateHeadActQmaster    hostname: %s", hostname)

        cmd = "echo '" + hostname + "' > " + act_qmaster
        log.debug("sge.CreateCell.updateHeadActQmaster    cmd: %s", cmd)
        os.system(cmd)

    def setMasterInfo(self, master):
        """
            Set ip, dns name and instance ID in 'qmaster_info' file
        """
        target      =   self.root + "/" + self.cell
        qmaster_info =   target + "/qmaster_info"
        log.info("Setting qmaster_info file: %s", qmaster_info)
        
        instanceid = master.ssh.execute("curl -s http://169.254.169.254/latest/meta-data/instance-id")
        log.info("CreateCell.setMasterInfo    instanceid: %s", instanceid)
        
        cmd = "echo '" \
              + master.private_dns_name + "\t" \
              + master.private_ip_address + "\t" \
              + instanceid[0] + "\t" \
              + master.public_dns_name + "\t" \
              + master.ip_address \
              + "' > " + qmaster_info
        log.info("CreateCell.setMasterInfo    cmd: %s", cmd)
        os.system(cmd)
        
    def copyCellCommands(self):
        source      = self.root + "/default"
        target      = self.root + "/" + self.cell
        return (
            'mkdir ' + target + ' &> /dev/null', 
            'rsync -a ' + source + "/* " + target + " --exclude *tar.gz",
            'chown -R sgeadmin:sgeadmin ' + target
        )

    def copyCellOnHead(self):
        """
            Copy cell dir from default dir
        """
        log.info("Copying cell directory on head node")
        log.debug("sge.CreateCell.copyCellOnHead    CreateCell.copyCellOnHead()")
        commands = self.copyCellCommands()
        log.debug("sge.CreateCell.copyCellOnHead    commands: %s", commands)

        target      = self.root + "/" + self.cell
        log.debug("sge.CreateCell.copyCell    target: %s", target)
        log.debug("sge.CreateCell.copyCellOnHead    os.path.isdir(target): %s", os.path.isdir(target))
        if not os.path.isdir(target):
            for command in commands:
                log.info(command)
                os.system(command)
        
        ##### CREATE NEW settings.sh FILE
        command = self.settingsCommand()
        log.info(command)
        os.system(command)

    def copyCell(self, node):
        """
            Copy cell dir from default dir
        """
        log.info("Copying cell directory on %s", node.alias)
        log.debug("sge.CreateCell.copyCell    CreateCell.copyCell(" + node.alias + ")")
        commands = self.copyCellCommands()
        log.debug("sge.CreateCell.copyCell    commands: %s", commands)

        target      = self.root + "/" + self.cell
        log.debug("sge.CreateCell.copyCell    target: %s", target)
        log.debug("sge.CreateCell.copyCell    os.path.isdir(target): %s", os.path.isdir(target))
        #if not os.path.isdir(target):
        for command in commands:
            log.info(command)
            node.ssh.execute(command, True, False, True)
            
        #### PAUSE TO ALLOW FILE SYSTEM TO CATCH UP
        time.sleep(2)
        
        ##### CREATE NEW settings.sh FILE
        command = self.settingsCommand()
        log.info("Creating settings.sh file")
        log.info(command)
        os.system(command)

    def on_add_node(self, node, nodes, master, user, user_shell, volumes):
        log.info("Doing 'on_add_node' for plugin: sge.CreateCell");
        log.info("Adding %s", node.alias)
        log.debug("sge.CreateCell.on_add_node    CreateCell.on_add_node(self, node, nodes, master, user, user_shell, volumes)")
        log.debug("sge.CreateCell.on_add_node    node.private_dns_name: %s" % node.private_dns_name)

        #### SET HEAD NODE INTERNAL IP
        self.getHeadIp();

        #### ADD ENVIRONMENT VARIABLES TO /etc/profile ON MASTER
        self.addEnvarsToProfile(node)
        
        ##### CREATE NEW CELL DIRECTORY ON HEAD AND MASTER
        self.copyCell(node);

        ##### RESTART SGE ON NODE
        self.restartSge(node)

        #### ADD NODE TO @allhosts GROUP
        self.addToAllhosts(node, master)

        log.info("Completed 'on_add_node' for plugin: sge.CreateCell");

    def on_remove_node(self, node, nodes, master, user, user_shell, volumes):
        log.info("Doing on_remove_node for plugin: sge.CreateCell")
        log.info("Removing %s " % node.alias)
        log.debug("sge.CreateCell.on_remove_node    node.private_dns_name: %s" % node.private_dns_name)

