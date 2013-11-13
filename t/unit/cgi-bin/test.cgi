#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

=head2

	APPLICATION 	test.cgi
	
	PURPOSE
	
		RESPOND TO XMLHTTPRequest QUERIES FOR TESTING PURPOSES.
		
		REPLIES BY REPEATING THE response CGI PARAMETER GIVEN TO
		
		IT BY THE CALLER.

=cut

use strict;

#### PRINT HEADER WITH TEXT MIME TYPE
print "Content-type: text/html\n\n";

#### FLUSH STDOUT SO THE MIME TYPE GETS OUT BEFORE ANY ERRORS
$| = 1;

#### GET INPUT
my $input = $ARGV[0];
$input = $ENV{'QUERY_STRING'} if not defined $input;
print "project.cgi    input: $input\n" if $DEBUG;

#### REPLY WITH response PARAM OF REQUEST
my ($response) = $input =~ /response=([^&]+)/;
$response =~ s/%27/"/g;
$response =~ s/%22/"/g;
$response =~ s/%20/ /g;

print "response: $response\n" if $DEBUG;
if ( $input =~ /&delay=/ ) {
    my ($delay) = $input =~ /delay=(\d+)/;
    print "test.cgi    sleeping $delay seconds\n" if $DEBUG;
    sleep($delay) if defined $delay and $delay
}

print $response;
