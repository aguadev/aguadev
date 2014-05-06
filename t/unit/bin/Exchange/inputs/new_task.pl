#!/usr/bin/perl

use strict;
use warnings;

$|++;
use Net::RabbitFoot;

#my $host    =   "127.0.0.1";
#my $host    =   "172.16.230.1"; 
#my $host    =   "172.17.42.1";
my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
    #host => 'localhost',

    #host => $host,
    #port => 5672,
    #user => 'guest',
    #pass => 'guest',
    #vhost => '/',

    host => "172.17.42.1",
    port => 5672,
    user => 'rabbituser',
    pass => 'runrabit%2',
    vhost => 'rabbitvhost',
);


my $chan = $conn->open_channel();

$chan->declare_queue(
    queue => 'task_queue',
    durable => 1,
);

my $msg = join(' ', @ARGV) || "Hello World!";

$chan->publish(
    exchange => '',
    routing_key => 'task_queue',
    body => $msg,
);

print " [x] Sent '$msg'\n";

$conn->close();
