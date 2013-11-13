#!/usr/bin/perl -w

=head2

    APPLICATION         fstab-fix
    
    PURPOSE
    
        REMOVE A LINE ADDED TO /etc/fstab BY cloud-init WHICH
        
        STOPS t1.micro INSTANCES FROM REBOOTING

=cut 

use strict;

my $file = $ARGV[0];
print "No file supplied\n" and exit if not defined $file;

open(FILE, $file) or die "Can't open file: $file\n";
my @lines = <FILE>;
close(FILE) or die "Can't close file: $file\n";

for ( my $i = 0; $i < $#lines + 1; $i++ )
{
    my $line = $lines[$i];
    #next if $line =~ /^#/;
    
    if ( $line =~ /comment=cloudconfig/ )
    {
        splice @lines, $i, 1;
        $i--;
    }
}

open(OUT, ">$file") or die "Can't open file: $file\n";
foreach my $line ( @lines ) {   print OUT $line;    }
close(OUT) or die "Can't close file: $file\n";

print "Completed $0\n";
print `date`;