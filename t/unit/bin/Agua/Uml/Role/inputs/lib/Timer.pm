package Timer;
use strict;

sub datetime {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
   
    $min = sprintf "%02d", $min;

    my $ampm = "AM";
    if ($hour > 12) 
    {
        $hour = $hour - 12;
        $ampm = "PM";
    }

    my @Days = ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday");
    my @Months = ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
    
    my $day = $Days[$wday];
    my $month = $Months[$mon];
    my $date = $mday;
    
    $year = 1900 + $year;
    if ($year eq "1900")
    {
        $year = 2000 + $year;
    }
    
    my $datetime = "$hour:$min$ampm, $date $month $year";
    return $datetime;
}



sub runtime {
	my $start_time	=	shift;
	my $end_time	=	shift;
	
	my $run_time = $end_time - $start_time;
	($run_time) = hours_mins_secs($run_time);

	return $run_time;	
}

sub hours_mins_secs {
	my $seconds			=	shift;
	
	my $hours = int($seconds / 3600);
	my $minutes = int( ($seconds % 3600) / 60 );
	$seconds = ( ($seconds % 3600) % 60 );

	$hours = pad_zero($hours, 2);
	$minutes = pad_zero($minutes, 2);
	$seconds = pad_zero($seconds, 2);
	
	return "$hours:$minutes:$seconds";
}

sub seconds {
	my $hours_mins_secs 	=	shift;
	
	my $seconds = 0;
	my ($hours, $mins, $secs) = $hours_mins_secs =~ /^([^:]+):([^:]+):([^:]+)$/;
	$seconds += $hours * 3600;
	$seconds += $mins * 60;
	$seconds += $secs;

	return $seconds;
}


sub pad_zero {
	my $number			=	shift;
	my $pad				=	shift;
	
	my $sprintf = "%0" . $pad . "d";
	$number = sprintf $sprintf, $number;

	return $number;
}

sub current_datetime {
	my ($sec, $min, $hour, $day_of_month, $month, $year, $weekday, $day_of_year, $isdst) = localtime;	
	
	$min = sprintf "%02d", $min;
	$day_of_month = sprintf "%02d", $day_of_month;
	$month	= $month + 1;	
	$month	= sprintf "%02d", $month; 
	$hour	= sprintf "%02d", $hour;
	$min	= sprintf "%02d", $min;
	$sec	= sprintf "%02d", $sec;	
	$year	= 1900 + $year;
	$year	=~ s/^\d{2}//;

	my $current_datetime = "$year-$month-$day_of_month $hour:$min:$sec";
	
	return ($current_datetime);
}

sub current2mysql_datetime {
	my $current_datetime			=	shift;

	# CURRENT DATETIME:	06-05-13 17:52:21
	# MYSQL DATETIME:	1998-07-06 09:32:36
	my ($year) = $current_datetime =~ /^(\d+)/;
	my $extra_digits = 19;
	if ( $year < 20 )	{	$extra_digits = 20;	}	
	
	return "$extra_digits$current_datetime";
}


sub blast2mysql_datetime {
    # CONVERT FROM BLAST DATETIME TO MYSQL DATETIME
	# BLAST DATE: Fri Jul 6 09:32:36 1998
	# .ACE DATE: Thu Jan 19 20:32:58 2006
	# .PHD DATE: Thu Jan 19 20:32:58 2006
	# MYSQL DATE: 1998-07-06 09:32:36
	# 
    # STAT DATE: Apr 16 19:39:22 2006
    
	my $blast_datetime      =   shift;
 
    my ( $month, $date, $hour, $minutes, $seconds, $year) = $blast_datetime =~ /^\s*\S+\s+(\S+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+(\d+)\s*/;
   # $date = Annotation::two_digit($date);
    $month = month_number($month);
    my $mysql_datetime = "$year-$month-$date $hour:$minutes:$seconds";
    
    return $mysql_datetime;
}

sub month_number {
    my $month           =   shift;
    
    if ( $month =~ /^Jan/ ) {   return "01";    }
    elsif ( $month =~ /^Feb/ ) {   return "02";    }
    elsif ( $month =~ /^Mar/ ) {   return "03";    }
    elsif ( $month =~ /^Apr/ ) {   return "04";    }
    elsif ( $month =~ /^May/ ) {   return "05";    }
    elsif ( $month =~ /^Jun/ ) {   return "06";    }
    elsif ( $month =~ /^Jul/ ) {   return "07";    }
    elsif ( $month =~ /^Aug/ ) {   return "08";    }
    elsif ( $month =~ /^Sep/ ) {   return "09";    }
    elsif ( $month =~ /^Oct/ ) {   return "10";    }
    elsif ( $month =~ /^Nov/ ) {   return "11";    }
    return "12";
}

sub stat_datetime_created {
	my $filename					=	shift;
	
	my $stat_string = `stat $filename`;
	my $tokens = tokenise_string($stat_string); # DATA ENTRIES ARE DELIMITED WITH " " IF THEY CONTAIN SPACES
	# 234881035 24271102 -rwxrwxrwx 1 young young 0 10000 "Apr 25 15:31:06 2006" "Jan 19 20:28:37 2006" "Jan 25 14:51:27 2006" 4096 24 0 /Users/young/FUNNYBASE/pipeline/151-158/phd_dir/151-001-A01.ab1.phd.1

	#  FORMAT: Jan 25 14:51:27 2006	
	my $stat_datetime = $$tokens[10];
	
	
	# NB: Not all fields are supported on all filesystem types. Here are the meanings of the fields:
	# 0 dev      device number of filesystem
	# 1 ino      inode number
	# 2 mode     file mode  (type and permissions)
	# 3 nlink    number of (hard) links to the file
	# 4 uid      numeric user ID of file's owner
	# 5 gid      numeric group ID of file's owner
	# 6 rdev     the device identifier (special files only)
	# 7 size     total size of file, in bytes
	# 8 atime    last access time in seconds since the epoch
	# 9 mtime    last modify time in seconds since the epoch
	#10 ctime    inode change time in seconds since the epoch (*)
	#11 blksize  preferred block size for file system I/O
	#12 blocks   actual number of blocks allocated

	return $stat_datetime;
}

sub stat_datetime_modified {
	my $filename					=	shift;
	
	my $stat_string = `stat $filename`;
	my $tokens = tokenise_string($stat_string); # DATA ENTRIES ARE DELIMITED WITH " " IF THEY CONTAIN SPACES
	# 234881035 24271102 -rwxrwxrwx 1 young young 0 10000 "Apr 25 15:31:06 2006" "Jan 19 20:28:37 2006" "Jan 25 14:51:27 2006" 4096 24 0 /Users/young/FUNNYBASE/pipeline/151-158/phd_dir/151-001-A01.ab1.phd.1

	#  FORMAT: Jan 25 14:51:27 2006	
	my $stat_datetime = $$tokens[9];
	
	
	# NB: Not all fields are supported on all filesystem types. Here are the meanings of the fields:
	# 0 dev      device number of filesystem
	# 1 ino      inode number
	# 2 mode     file mode  (type and permissions)
	# 3 nlink    number of (hard) links to the file
	# 4 uid      numeric user ID of file's owner
	# 5 gid      numeric group ID of file's owner
	# 6 rdev     the device identifier (special files only)
	# 7 size     total size of file, in bytes
	# 8 atime    last access time in seconds since the epoch
	# 9 mtime    last modify time in seconds since the epoch
	#10 ctime    inode change time in seconds since the epoch (*)
	#11 blksize  preferred block size for file system I/O
	#12 blocks   actual number of blocks allocated

	return $stat_datetime;
}

sub tokenise_string {
	my $string						=	shift;
	
	chomp($string);
		
	my $tokens;	
	my $token_counter = 0;
	while ( $string !~ /^\s*$/ )
	{
		
		my $token = '';
		if ( $string =~ s/^\s*"// )
		{
			
			while ( $string !~ /^\s*"/ and $string !~ /^\s*$/ )
			{
				$string =~ s/^\s*([^"^\s]+)//;
				($token) .= "$1 ";
				$token_counter++;	
			}
			$string =~ s/^\s*"//;
		}
		else
		{
			$string =~ s/^\s*(\S+)\s*//;
			($token) .= $1;
		}
		
		push @$tokens, $token;
		$token_counter++;
	}
	
	
	
	return $tokens;
}
	
sub stat2mysql_datetime {
	# CONVERT FROM STAT DATETIME TO MYSQL DATETIME
	# STAT DATE: Apr 16 19:39:22 2006
	# MYSQL DATE: 1998-07-06 09:32:36
	#
	# BLAST DATE: Fri Jul 6 09:32:36 1998
	# .ACE DATE: Thu Jan 19 20:32:58 2006	
	# .PHD DATE: Thu Jan 19 20:32:58 2006
    
	my $stat_datetime				=	shift;

	#  FORMAT: Jan 25 14:51:27 2006	
	my ( $month, $date, $time, $year) = split " ", $stat_datetime;
	my ($hour, $minutes, $seconds) = split ":", $time;
	$month = month_number($month);
    my $mysql_datetime = "$year-$month-$date $hour:$minutes:$seconds";
    
    return $mysql_datetime;
}
	



1;