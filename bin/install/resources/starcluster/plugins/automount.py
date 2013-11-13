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

class NfsShares (ClusterSetup):
    """
    Automatically mounts external NFS shares on StarCluster nodes
    """
    def __init__(self, privatekey, publiccert, interval, sourcedirs, mountpoints, portmapport, nfsport, mountdport, cluster):
        log.info("Loaded plugin: automount.NfsShares")
        log.debug("automount.NfsShares.__init__    Initialising AutoMount plugin.")
        log.debug("automount.NfsShares.__init__    privatekey %s" % privatekey)
        log.debug("automount.NfsShares.__init__    publiccert %s" % publiccert)        
        log.debug("automount.NfsShares.__init__    interval %s" % interval)
        log.debug("automount.NfsShares.__init__    sourcedirs %s" % sourcedirs)
        log.debug("automount.NfsShares.__init__    mountpoints %s" % mountpoints)
        log.debug("automount.NfsShares.__init__    portmapport %s" % portmapport)
        log.debug("automount.NfsShares.__init__    nfsport %s" % nfsport)
        log.debug("automount.NfsShares.__init__    mountdport %s" % mountdport)
        log.debug("automount.NfsShares.__init__    cluster %s" % cluster)
        
        self.privatekey     =   privatekey
        self.publiccert     =   publiccert
        self.portmapport    =   portmapport
        self.nfsport        =   nfsport
        self.mountdport     =   mountdport
        self.cluster        =   cluster

        # set default interval
        if not interval: interval = 10
        self.interval = interval
        self.sourcedirs = sourcedirs.split(",")
        self.mountpoints = mountpoints.split(",")
        
        if len(self.sourcedirs) != len(self.mountpoints):
            log.info("automount.NfsShares.__init__    length of sourcedirs (" 
                + len(self.sourcedirs) 
                + ") is not the same as length of mountpoints ("
                + len(self.mountpoints)
                + ")"
                )
            sys.exit(0)

    def run(self, nodes, master, user, user_shell, volumes):
        """
            Mount NFS shares on master and all nodes
        """
        log.info("Running plugin automount")
        log.debug("automount.NfsShares.run    automount.NfsShares.run(nodes, master, user, user_shell, volumes)")

        #### OPEN NFS-RELATED PORTS FOR THIS CLUSTER
        self.openNfsPorts("default")
        self.openNfsPorts('@sc-' + self.cluster)

        #### SET HEAD NODE INTERNAL IP
        self.getHeadIp();

        #### FIX mountd PORT ON head AND MASTER/NODES
        mountdport = "32767"
        for node in nodes:
            self.setMountdOnNode(node, mountdport)
        
        self.setMountdOnHead(mountdport)
        self.restartServicesOnHead()

        #### MOUNT ON ALL NODES
        for node in nodes:
            self.mount(node)

        log.info("Completed plugin automount")

    def openNfsPorts(self, group):
        """
            Open (fixed) NFS-related ports (portmap, nfs and mountd)
        """
        portmapport = self.portmapport
        nfsport     = self.nfsport
        mountdport  = self.mountdport
        
        log.info("Opening NFS-related ports for group: %s", group)
        log.debug("automount.openNfsPorts    group; %s", group)
        log.debug("automount.openNfsPorts    portmapport; %s", portmapport)
        log.debug("automount.openNfsPorts    nfsport; %s", nfsport)
        log.debug("automount.openNfsPorts    mountdport; %s", mountdport)
        
        permissions = [
            dict(group=group, port=nfsport, type="tcp"),
            dict(group=group, port=nfsport, type="udp"),
            dict(group=group, port=portmapport, type="tcp"),
            dict(group=group, port=portmapport, type="udp"),
            dict(group=group, port=mountdport, type="tcp"),
            dict(group=group, port=mountdport, type="udp")
        ]

        #### OPEN PORTS FROM HEAD NODE (NO SSH FROM MASTER)
        commands = self.setPortCommands(group, permissions)
        for command in commands:
            self.runSystemCommand(command);

    def setPortCommands(self, group, permissions):
        groupPermissions = self.getGroupPermissions(group)
        log.debug("automount.NfsShares.setPortCommands    groupPermissions: %s", groupPermissions)

        #### FILTER OUT EXISTING PERMISSIONS
        permissions = self.filterPermissions(permissions, groupPermissions)

        #### SET EC2 KEY FILE ENVIRONMENT VARIABLES
        ec2vars = self.getEC2Vars()        
        
        commands = []
        for permission in permissions:
            command = ec2vars + 'ec2-authorize ' + permission['group'] + ' -p ' + permission['port'] + ' -P ' + permission['type']
            commands.append(command)

        return commands

    def getGroupPermissions(self, group):
        ec2vars = self.getEC2Vars()
        ec2dgrp = self.runSystemCommand(ec2vars + 'ec2dgrp ' + group)
        permissions = ec2dgrp.split("\n")
        permissions[:1] = []
        return permissions
        
    def filterPermissions(self, permissions, groupPermissions):
        log.info("Filtering to exclude existing permissions")

        missing = []
        for i, v in enumerate(permissions):
            found = 0
            for index, value in enumerate(groupPermissions):
                if value == '': break
                elements = value.split("\t")
                type = elements[4]
                port = elements[5]
                if type == '' or value == '': break
                if type == v['type'] and port == v['port']:
                    found = 1
                    break
 
            if found == 0:    
                missing.append(v)
                
        return missing

    def getEC2Vars(self):
        ec2vars = "export EC2_PRIVATE_KEY=" + self.privatekey + "; "
        ec2vars += "export EC2_CERT=" + self.publiccert + "; "
        
        return ec2vars

    def runSystemCommand(self, command):
        log.debug(command)

        return subprocess.Popen(command, stdout=subprocess.PIPE, shell=True).stdout.read()

    def getHeadIp(self):
        log.info("automount.NfsShares.getHeadIp    Getting headnode internal IP")
        p = os.popen('curl -s http://169.254.169.254/latest/meta-data/instance-id');
        instanceid = p.read()
        log.debug("automount.NfsShares.getHeadIp    instanceid: %s" % instanceid)
        command = "ec2-describe-instances -K " + self.privatekey \
            + " -C " + self.publiccert \
            + " " + instanceid
        log.debug("automount.NfsShares.getHeadIp    command: %s" % command)
        p = os.popen(command);
        reservation = p.read()
        log.debug("automount.NfsShares.getHeadIp    reservation: %s" % reservation)

        instance = reservation.split("INSTANCE")[1];
        log.debug("automount.NfsShares.getHeadIp    instance: %s" % instance)
        instanceRow = instance.split('\t')
        self.head_ip = instanceRow[17]
        log.debug("automount.NfsShares.getHeadIp    self.head_ip: %s" % self.head_ip)

    def mount(self, node):
        """
            Mount shares from head node on master and exec nodes
        """
        log.info("Mounting shared from head node to %s", node.alias)
        log.debug("automount.NfsShares.mount    node.private_dns_name: %s" % node.private_dns_name)
        log.debug("automount.NfsShares.mount    self.head_ip: %s" % self.head_ip)

        #### INSERT MOUNT POINT ENTRIES INTO /etc/fstab ON NODE
        log.debug("automount.NfsShares.on_add_node    Doing self._addToFstab")
        for i in range(len(self.sourcedirs)):
            self._addToFstab(node, self.sourcedirs[i], self.head_ip, self.mountpoints[i], self.interval)

        #### INSERT ENTRIES FOR MASTER/NODES INTO /etc/exports ON HEAD NODE
        log.debug("automount.NfsShares.mount    Doing self._addToExports")
        for i in range(len(self.sourcedirs)):
            self._addToExports(node, self.sourcedirs[i])
        
        #### MOUNT THE SHARES
        for i in range(len(self.sourcedirs)):
            self.mountShares(node, self.sourcedirs[i], self.head_ip, self.mountpoints[i], self.interval)

    def _addToFstab(self, node, sourcedir, sourceip, mountpoint, interval):            
        """
            Add entries to /etc/fstab on master/exec nodes
        """
        log.info("Adding /etc/fstab entry (%s on %s)", mountpoint, node.alias)
        insert = self.head_ip + ":" + sourcedir + "  " + mountpoint + "  nfs  nfsvers=3,defaults 0 0"
        cmd = "echo '" + insert + "' >> /etc/fstab ;"
        log.debug(cmd)
        node.ssh.execute(cmd)
        
    def _addToExports(self, node, sourcedir):
        """
            Add entries to /etc/exports on head node
        """
        log.info("Adding /etc/exports entry (%s to %s)", sourcedir, node.alias)
        insert = sourcedir + "  " + node.private_ip_address + "(async,no_root_squash,no_subtree_check,rw)"

        f = open("/etc/exports", 'rb')
        contents = f.read()
        f.close()
        insert = sourcedir + "  " + node.private_ip_address + "(async,no_root_squash,no_subtree_check,rw)\n"
        contents = string.replace(contents, insert,"")
        contents += insert
        f = open("/etc/exports", 'w')
        f.write(contents)
        f.close()        
        os.system("exportfs -ra")
        os.system("service portmap restart")
        os.system("service nfs restart")
        
    def _removeFromExports(self, node, sourcedir):
        """
            Remove entries from /etc/exports on head node
        """
        log.info("Removing from /etc/exports entry (%s to %s)", sourcedir, node.alias)
        f = open("/etc/exports", 'rb')
        contents = f.read()
        f.close()
        insert = sourcedir + "  " + node.private_ip_address + "(async,no_root_squash,no_subtree_check,rw)\n"
        contents = string.replace(contents, insert,"")
        f = open("/etc/exports", 'w')
        f.write(contents)
        f.close()        

    def setMountdOnNode(self, node, mountdport):
        """
            Fix mountd port to same number on all hosts - head, master and exec nodes
        """
        log.info("Setting mountd port on %s", node.alias)
        cmd = self.mountdCommand(mountdport)
        log.debug("Doing node.ssh.execute: " + cmd)
        node.ssh.execute(cmd)

    def setMountdOnHead(self, mountdport):
        cmd = self.mountdCommand(mountdport)
        log.debug("Doing os.system: " + cmd)
        os.system(cmd)

    def restartServicesOnNode(self, node):
        node.ssh.execute("service portmap restart")
        node.ssh.execute("service nfs restart")

    def restartServicesOnHead(self):
        os.system("service portmap restart")
        os.system("service nfs restart")
        
    def mountdCommand(self, mountdport):
        """
            LATER: DETERMINE COMMAND USING uname -a ON NODE
            E.G.: centos
            nfsconfig = "/etc/sysconfig/nfs"
            insert = "MOUNTD_PORT=" + mountdport
        """
        #### ubuntu
        nfsconfig = "/etc/default/nfs-kernel-server"
        insert = "RPCMOUNTDOPTS=\"--port " + mountdport + " --manage-gids\""
        return "echo '" + insert + "' >> "  + nfsconfig + ";"        

    def mountShares(self, node, sourcedir, sourceip, mountpoint, interval):
        """
            Mount the shares on the local filesystem - wait <interval> seconds between tries
        """
        log.info("Mounting NFS shares on %s", node.alias)
        cmd = "mount -t nfs " + sourceip + ":" + sourcedir + " " + mountpoint
        log.info(cmd)
        
        if not node.ssh.isdir(mountpoint): node.ssh.makedirs(mountpoint)
        
        # TRY REPEATEDLY TO MOUNT
        file_list = []
        while not file_list:
            log.debug("automount.NfsShares.mountShares    cmd: %s" % cmd)
            node.ssh.execute(cmd)
            file_list = node.ssh.ls(mountpoint)
            if file_list: break
            log.debug("Sleeping  %s seconds" % interval)
            time.sleep(float(interval))

    def on_add_node(self, node, nodes, master, user, user_shell, volumes):
        log.info("Doing 'on_add_node' for plugin: automount.NfsShares");
        log.info("Adding node %s", node.alias)
        log.debug("automount.NfsShares.on_add_node    ")
        log.debug("automount.NfsShares.on_add_node    node.private_dns_name: %s" % node.private_dns_name)

        #### SET HEAD NODE INTERNAL IP
        self.getHeadIp();

        #### INSERT MOUNT POINT ENTRIES INTO /etc/fstab ON NODE
        log.debug("automount.NfsShares.on_add_node    Doing self._addToFstab")
        for i in range(len(self.sourcedirs)):
            self._addToFstab(node, self.sourcedirs[i], self.head_ip, self.mountpoints[i], self.interval)
        
        #### INSERT EXPORT ENTRIES FOR NODE INTO /etc/exports ON HEAD NODE
        log.debug("automount.NfsShares.on_add_node    Doing self._addToExports")
        for i in range(len(self.sourcedirs)):
            self._addToExports(node, self.sourcedirs[i])

        #### FIX mountd PORT ON head AND MASTER/
        mountdport = "32767"
        self.setMountdOnNode(node, mountdport)
        self.setMountdOnHead(mountdport)
        self.restartServicesOnHead()

        #### MOUNT THE SHARES
        for i in range(len(self.sourcedirs)):
            self.mountShares(node, self.sourcedirs[i], self.head_ip, self.mountpoints[i], self.interval)
        log.info("Completed 'on_add_node' for plugin: automount.NfsShares");

    def on_remove_node(self, node, nodes, master, user, user_shell, volumes):
        log.info("Doing on_remove_node for plugin: automount.NfsShares")
        log.info("Removing %s " % node.alias)
        log.debug("automount.NfsShares.on_remove_node    Removing %s from cluster" % node.alias)
        log.debug("automount.NfsShares.on_remove_node    node.private_dns_name: %s" % node.private_dns_name)

        # REMOVE ENTRIES FROM /etc/exports ON HEAD NODE
        for i in range(len(self.sourcedirs)):
            self._removeFromExports(node, self.sourcedirs[i])

        # RESTART NFS ON HEAD
        log.info("automount.NfsShares.on_remove_node    Restarting NFS on head node")
        os.system("service portmap restart")
        os.system("service nfs restart")

