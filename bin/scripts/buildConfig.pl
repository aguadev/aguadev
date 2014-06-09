#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
#$DEBUG = 1;

#### TIME
my $time = time();

=head2

    APPLICATION     buildConfig
    
    PURPOSE
    
            WRITE THE buildX.config.js FILE USED TO BUILD BY GETTING THE
            
            TOTAL LIST OF REQUIRED FILES INSIDE ALL FILES IN ALL SUBDIRECTORIES
            
            INSIDE THE USER-SPECIFIED DIRECTORY, E.G., agua/html/plugins
                
    INPUT
    
        1. INPUT DIRECTORY
        
        2. OUTPUT DIRECTORY
    
    OUTPUT
    
        1. CONFIG FILE INSIDE OUTPUT DIRECTORY
        
        2. PRINT TO STDOUT COMMAND TO RUN BUILD 

    NOTES
    
       1. CREATES buildname.profile.js FILE
        
            E.G.: C:\DATA\base\html\Bioptic0.2.5\html\dojo.1.2.2\util\buildscripts\profiles\build8.profile.js
            
            dependencies ={
                layers:  [
                    {
                    name: "../report.js",
                        dependencies: [
                            
                            "plugins.report.Controller",
                            "plugins.report.Report",
                            "plugins.report.Report.SNP",
                            
                            "dijit.form.CheckBox",
            
                            "dijit.dijit",
                            "dijit.form.Slider",
                            "dijit.form.regexingSelect",
                            "dijit.form.Button",
                            ,
                            "dijit.form.NumberSpinner",
                            "dijit.Editor",
                            "dijit.form.DateTextBox",
                            "dijit.form.Textarea",
                            ,
                            "dijit.form.TextBox",
                            "dijit.form.ValidationTextBox",
                            "dijit.form.NumberTextBox",
                            "dijit.form.CurrencyTextBox",
                            "dojo.currency",
                            "dojo.parser"
                        ]
                    }
                ]
            
                //prefixes: [
                //    [ "dijit", "../dijit" ],
                //    [ "dojox", "../dojox" ],
                //    [ "plugins", "../../plugins" ]
                //]
            };


        2. AFTER RUNNING buildConfig.pl, YOU BUILD THE LAYER FILE AS FOLLOWS:
        
            CREATE THE OUTPUT DIRECTORY FOR YOUR BUILD

            mkdir C:\DATA\base\html\Bioptic0.2.5\html\build8
            
            RUN THE BUILD (TAKES A FEW MINS)
            
            cd C:\DATA\base\html\Bioptic0.2.5\html\dojo.1.2.2\util\buildscripts
            
            java -jar ..\shrinksafe\custom_rhino.jar build.js profile="build8" action="release" version="0.2.5" cssOptimize=comments.keepLines releaseDir=../../../build8/ > ..\..\..\build8\build8-output.txt
            

    USAGE
    
    ./buildConfig.pl <--inputdir String> <--outputdir String> [--regex String] [--regex String] [--help]
    
    --inputdir          :   /Full/path/to/input/directory
    --outputdir         :   /Full/path/to/output/directory
    --exclude         	:   Comma-separated /full/path/to/excluded/directories
    --help              :   Print help info

    EXAMPLES

perl buildConfig.pl --inputdir /agua/html/plugins/workflow --outputfile /agua/html/dojo/util/buildscripts/profiles/workflow.profile.js --name "../agua.js"


=cut

use strict;

#### FLUSH BUFFER
$| = 1;

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### INTERNAL MODULES
use Timer;
use Util;
use Conf::Yaml;

#### EXTERNAL MODULES
use Data::Dumper;
use Term::ANSIColor qw(:constants);
use Getopt::Long;

#### GET OPTIONS
my $inputdir;
my $exclude;
my $include;
my $excludedir;
my $outputfile;
my $name;
my $help;
GetOptions (
	'inputdir=s' => \$inputdir,
	'exclude=s' => \$exclude,
	'include=s' => \$include,
	'excludedir=s' => \$excludedir,
	'outputfile=s' => \$outputfile,
	'name=s' => \$name,
	'help' => \$help
) or die "No options specified. Try '--help'\n";

#### PRINT HELP IF REQUESTED
if ( defined $help )	{	usage();	}

#### CHECK FOR REQUIRED inputdir
die "inputdir not defined (option --inputdir)\n" if not defined $inputdir;
die "Output directory not defined (option --outputfile)\n" if not defined $outputfile;
#print "Outputfile: $outputfile\n";

my $outputdir;
($outputdir) = $outputfile =~ /^(.+?)\/[^\/]+$/;
mkdir($outputdir) or die "Can't create output directory: $outputdir" if not -d $outputdir;

#### GET .js FILES
print "Getting .js files in subdirectories...\n";
my $regex = "\.js\$";
my $max_depth = 5;
my $already_seen;
my $files = recursive_getfiles($already_seen, $inputdir, $regex, $max_depth);
die "No files in directory: $inputdir\n" if not defined $files or scalar(@$files) == 0;
print "done.\n";

#### GET MODULES
print "Parsing out modules in .js files\n";
my $modules;
foreach my $file ( @$files )
{
    $/ = "\n";
    open(FILE, $file) or die "Can't open file: $file\n";
    while ( <FILE> )
    {
        if ( $_ =~ /dojo\.provide\(\s*"([^"^\s]+\s*)/ or /dojo\.require\(\s*"([^"^\s]+\s*)/) {
            push @$modules, $1;
        }
    }
}
@$modules = sort @$modules;

#### FILTER
print "Filtering modules\n";
if ( defined $exclude )
{
	my @excluded = split ",", $exclude;

	for ( my $i = 0; $i < @$modules; $i++ )
	{
		for ( my $k = 0; $k < $#excluded + 1; $k++ ) {
			if ( $$modules[$i] =~ /$excluded[$k]/ )
			{
				print "splicing excluded module: $$modules[$i]\n";
				splice @$modules, $i, 1;
				$i--;
			}
		}	
	}
}

if ( defined $include )
{
	for ( my $i = 0; $i < @$modules; $i++ )
	{
		if ( $$modules[$i] !~ /$include/ )
		{
			print "splicing module non-included module: $$modules[$i]\n";

			splice @$modules, $i, 1;
			$i--;
		}
	}
}

print "AFTER FILTER:\n";
print join "\n", @$modules;




#### PRINT build_X_.config.js FILE
my $content = qq(dependencies = {
    layers:  [
        {
	        name: "$name",
            dependencies: [
);

my $seen_module = {};
foreach my $module ( @$modules )
{
	if ( exists $seen_module->{$module} )
	{
		next;
	}
	else
	{
		$seen_module->{$module} = 1;
	}
	
    $content .= qq{\t\t\t\t"$module",\n};    
}
$content =~ s/,$//;

$content .= qq(
            ]
        }
    ],

    prefixes: [
        [ "dijit", "../dijit" ],
        [ "dojox", "../dojox" ],
        [ "plugins", "../../plugins" ]
    ]
};);

#print "content: $content\n";

open(OUTFILE, ">$outputfile") or die "Can't open output file: $outputfile\n";
print OUTFILE $content;
close(OUTFILE);

print "\n\nConfig file printed:\n\n$outputfile\n\n";

#### PRINT RUN TIME
my $runtime = Timer::runtime( $time, time() );
print "\nRun time: $runtime\n";
print "Completed $0\n";
print Util::datetime(), "\n";
print "****************************************\n\n\n";
exit;




###########################################################################################
####################                 S U B R O U T I N E S                ################# 
###########################################################################################

=head2

    SUBROUTINE      recursive_getfiles
    
    PURPOSE
    
        GET ALL FILES WITH A CERTAIN regex IN THEIR NAME WITHIN
        
        ALL SUBDIRECTORIES OF A DIRECTORY
        
=cut

sub recursive_getfiles
{
	my $already_seen	=	shift;
    my $directory   	=   shift;
    my $regex       	=   shift;
    my $max_depth   	=   shift;
    my $depth       	=   shift;
    
    $depth = 0 if not defined $depth;
    $depth++;
    return if $depth == $max_depth;

    #print "directory: $directory\n";
    #print "regex: $regex\n";
    #print "max depth: $max_depth\n";
    #print "depth: $depth\n";
    
    my $gotfiles = [];
    my $files = Util::files($directory);
    #print "files: @$files\n";
    foreach my $file ( @$files )
    {
        #print "file: $file\n";
        next if $file =~ /^\s*$/ or $file =~ /^[\.]{1,2}$/;
        
        my $filepath = "$directory/$file";
        if ( -d $filepath )
        {
            my $subfiles = recursive_getfiles($already_seen, $filepath, $regex, $max_depth, $depth);
            next if not defined $subfiles or scalar @$subfiles == 0 or not @$subfiles;
            #print "subfiles:\n";
            #print Dumper $subfiles;
            @$gotfiles = (@$gotfiles, @$subfiles);
        }
        else
        {
        	use re 'eval';# EVALUATE $regex AS REGULAR EXPRESSION
            if ( $file =~ /$regex/ )
            {
                #print "file: $file\n";
				if ( $already_seen->{$file} )	{	next;	}
				else
				{
					$already_seen->{$file} = 1;
	                push @$gotfiles, "$directory/$file";
				}
            }
        	no re 'eval';# STOP EVALUATING AS REGULAR EXPRESSION
        }
    }
    
    return $gotfiles;
}



sub usage
{
	print GREEN;
    print `perldoc $0`;
	print RESET;

	exit;
}




