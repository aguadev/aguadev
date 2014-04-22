# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 707 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/_absorb.al)"
sub _absorb {
    my $heap = shift;
    if ($heap->_VALUE("") eq "") {
        $heap->_make('sub _absorb {
    my ($heap, $to) = @_;
    Carp::croak "Self absorption" if $heap == $to;
    if (@$heap > 2 && !$to->can_die) {
        $to->insert(@$heap[1..$#$heap]);
        $#$heap = 0;
        return;
    }
    while (@$heap > 1) {
        $to->insert(_VALUE($heap->[-1]));
        pop @$heap;
    }
}');

    } else {
        $heap->_make('sub _absorb {
    my ($heap, $to) = @_;
    Carp::croak "Self absorption" if $heap == $to;
    if (@$heap > 2 && !$to->can_die) {
        $to->insert(map _VALUE($_), @$heap[1..$#$heap]);
        $#$heap = 0;
        return;
    }
    while (@$heap > 1) {
        $to->insert(_VALUE($heap->[-1]));
        pop @$heap;
    }
}');

    }
    return $heap->_absorb(@_);
}

# end of Heap::Simple::Perl::_absorb
1;
