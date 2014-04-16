# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 760 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/user_data.al)"
sub user_data {
    return shift->[0]{user_data} if @_ <= 1;
    my $heap = shift;
    my $old = $heap->[0]{user_data};
    $heap->[0]{user_data} = shift;
    return $old;
}

# end of Heap::Simple::Perl::user_data
1;
