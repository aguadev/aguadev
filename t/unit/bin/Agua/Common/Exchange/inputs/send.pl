#!/usr/bin/perl

use strict;
use warnings;

$|++;
use Net::RabbitFoot;

my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
    host => 'localhost',
    port => 5672,
    #port => 8080,
    user => 'guest',
    pass => 'guest',
    vhost => '/',
);


my $chan = $conn->open_channel();

$chan->publish(
    exchange => '',
    routing_key => 'hello',
    #routing_key => 'chat',
    body => 'Hello World!',
);

print " [x] Sent 'Hello World!'\n";

$conn->close();

