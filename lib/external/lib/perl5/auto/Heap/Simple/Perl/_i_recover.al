# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 776 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/_i_recover.al)"
# Recover from a partially executed insert
sub _i_recover {
    my ($heap, $end, $err) = @_;
    $err ||= $@ || die "Assertion failed: No exception pending";
    my @indices;
    for (my $i = $#$heap; $i>$end; $i >>=1) {
        unshift @indices, $i;
    }
    for my $i (@indices) {
        $heap->[$end] = $heap->[$i];
        $end = $i;
    }
    pop @$heap;
    die $err;
}

# end of Heap::Simple::Perl::_i_recover
1;
