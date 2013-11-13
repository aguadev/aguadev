#!/usr/bin/perl -w

use strict;

my $a = $ARGV[0];
my $b = $ARGV[1];
my $c = $ARGV[2];


print "A: $a\n";
print "B: $b\n";
print "C: $c\n";

for ( my $i = 0; $i < 10; $i++ )
{
    print "$i: Sleeping 1 second\n";    
    sleep(1);
}

print "Completed $0\n";
exit;
