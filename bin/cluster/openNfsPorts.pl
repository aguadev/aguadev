#!/usr/bin/perl -w

#### OPEN THE NFS PORTS ON THE CLUSTER MASTER TO ENABLE
#### MOUNT OF MASTER'S DATA FOLDER ON HEAD INSTANCE
use strict;

my $group = $ARGV[0];
#$group = "\@sc-masters";
$group = "\@sc-smallcluster";

#my $rpcinfo = `rpcinfo -p`;
my $rpcinfo = qq{
   program vers proto   port
    100000    2   tcp    111  portmapper
    100000    2   udp    111  portmapper
    100024    1   udp  60033  status
    100024    1   tcp  43829  status
    100021    1   udp  45242  nlockmgr
    100021    3   udp  45242  nlockmgr
    100021    4   udp  45242  nlockmgr
    100021    1   tcp  51636  nlockmgr
    100021    3   tcp  51636  nlockmgr
    100021    4   tcp  51636  nlockmgr
    100003    2   udp   2049  nfs
    100003    3   udp   2049  nfs
    100003    4   udp   2049  nfs
    100003    2   tcp   2049  nfs
    100003    3   tcp   2049  nfs
    100003    4   tcp   2049  nfs
    100005    1   udp  32767  mountd
    100005    1   tcp  32767  mountd
    100005    2   udp  32767  mountd
    100005    2   tcp  32767  mountd
    100005    3   udp  32767  mountd
    100005    3   tcp  32767  mountd
};
#print "rpcinfo: $rpcinfo\n";

my @lines = split "\n", $rpcinfo;
my $commands = [];
my $seen = {};
foreach my $line ( @lines )
{
    next if $line !~ /^\s*\d+/;
    #print "line: $line\n";
 
    my @elements = split " ", $line;
    my $protocol = $elements[2];
    my $port = $elements[3];
    
    my $signature = "$port$protocol";
    print "signature: $signature\n";
    
    if ( not exists $seen->{$port.$protocol} )
    {
        $seen->{$port.$protocol} = 1;
        push @$commands, "ec2-authorize $group -p $port -P $protocol";
    }
    else
    {
    }
}

foreach my $command ( @$commands )
{
    print "$command\n";
    print `$command`;    
}
