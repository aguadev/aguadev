#!/usr/bin/perl

use strict;
use warnings;

$|++;
use Net::RabbitFoot;

my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
    #host => 'localhost',
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

my $channel = $conn->open_channel();

$channel->declare_exchange(
    exchange => 'logs',
    type => 'fanout',
);

my $msg = join(' ', @ARGV) || "info: Hello World!";

$channel->publish(
    exchange => 'logs',
    routing_key => '',
    body => $msg,
);

print " [x] Sent $msg\n";

$conn->close();