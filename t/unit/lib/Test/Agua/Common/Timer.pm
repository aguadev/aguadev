use MooseX::Declare;

class Test::Agua::Common::Timer with (Agua::Common::Timer, Agua::Common::Util, Agua::Common::Logger) {
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);

# Ints
has 'showlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2);
has 'printlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	5);

# Strings

####///}}}

method BUILD ($hash) {
}

method testDatetimeToMysql {
	diag("getMysqlTime");

	my $tests	=	[
		{
			date		=>	"Fri May  9 14:20:02 PDT 2014",
			expected	=>	"2014-05-09 14:20:02"
		}
	];
	
	foreach my $test ( @$tests ) {
		my $date	=	$test->{date};
		my $expected=	$test->{expected};
		$self->logDebug("expected", $expected);
		
		my $actual	=	$self->datetimeToMysql($date);
		$self->logDebug("actual", $actual);

		ok($actual eq $expected, "correct $expected");
	}
	
}


}   #### Test::Agua::Common::Timer