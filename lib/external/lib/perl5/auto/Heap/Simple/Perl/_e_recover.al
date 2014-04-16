# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 792 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/_e_recover.al)"
# Recover from a partially executed extract
sub _e_recover {
    my ($heap, $end, $min, $err) = @_;
    $err ||= $@ || die "Assertion failed: No exception pending";
    $end >>= 1;
    $heap->[$end] = $heap->[$end >> 1] while ($end >>=1) > 1;
    $heap->[1] = $min;
    die $err;
}

# end of Heap::Simple::Perl::_e_recover
1;
