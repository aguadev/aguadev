#!/usr/bin/perl

use strict;
use warnings;

$|++;
use Net::RabbitFoot;

my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
    host => "10.2.24.103",
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

