package Agua::CLI::Getopt;

#### THIS PROVIDES getOptionsFromArray FUNCTIONALITY TO MooseX::Getopt

#use MooseX::Declare;
use MooseX::Getopt;
use Getopt::Long;
use Moose::Role 0.56;

with 'MooseX::Getopt';

#class Agua::CLI::Getopt with MooseX::Getopt {

sub new_with_options {

    my ($class, @params) = @_;

    print "Agua::CLI::Getopt::new_with_options()\n";
    print "Agua::CLI::Getopt::new_with_options    class: $class\n";
    print "Agua::CLI::Getopt::new_with_options    params: @params\n";
    print "Agua::CLI::Getopt::new_with_options    ARGV: @ARGV\n";

    my $config_from_file;
    if($class->meta->does_role('MooseX::ConfigFromFile')) {
        #local @ARGV = @ARGV;
        local @ARGV = @params;

        # just get the configfile arg now; the rest of the args will be
        # fetched later
        my $configfile;
        my $opt_parser = Getopt::Long::Parser->new( config => [ qw( no_auto_help pass_through ) ] );
        $opt_parser->getoptions( "configfile=s" => \$configfile );

        if(!defined $configfile) {
            my $cfmeta = $class->meta->find_attribute_by_name('configfile');
            $configfile = $cfmeta->default if $cfmeta->has_default;
            if (ref $configfile eq 'CODE') {
                # not sure theres a lot you can do with the class and may break some assumptions
                # warn?
                $configfile = &$configfile($class);
            }
            if (defined $configfile) {
                $config_from_file = eval {
                    $class->get_config_from_file($configfile);
                };
                if ($@) {
                    die $@ unless $@ =~ /Specified configfile '\Q$configfile\E' does not exist/;
                }
            }
        }
        else {
            $config_from_file = $class->get_config_from_file($configfile);
        }
    }

    my $constructor_params = ( @params == 1 ? $params[0] : {@params} );

    Carp::croak("Single parameters to new_with_options() must be a HASH ref")
        unless ref($constructor_params) eq 'HASH';

    my %processed = $class->_parse_argv(
        options => [
            $class->_attrs_to_options( $config_from_file )
        ],
        params => $constructor_params,
    );

    my $params = $config_from_file ? { %$config_from_file, %{$processed{params}} } : $processed{params};

    # did the user request usage information?
    if ( $processed{usage} and $params->{help_flag} )
    {
        $class->_getopt_full_usage($processed{usage});
    }

    $class->new(
        ARGV       => $processed{argv_copy},
        extra_argv => $processed{argv},
        ( $processed{usage} ? ( usage => $processed{usage} ) : () ),
        %$constructor_params, # explicit params to ->new
        %$params, # params from CLI
    );
}
    
1;


