# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 768 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/infinity.al)"
sub infinity {
    return shift->[0]{infinity} if @_ <= 1;
    my $heap = shift;
    my $old = $heap->[0]{infinity};
    $heap->[0]{infinity} = shift;
    return $old;
}

# end of Heap::Simple::Perl::infinity
1;
