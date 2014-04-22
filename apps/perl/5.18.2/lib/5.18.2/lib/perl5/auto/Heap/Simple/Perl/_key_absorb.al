# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 741 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/_key_absorb.al)"
sub _key_absorb {
    my $heap = shift;
    $heap->_make('sub _key_absorb {
    my ($heap, $to) = @_;
    Carp::croak "Self absorption" if $heap == $to;
    _ELEMENTS_PREPARE()
    if (@$heap > 2 && !$to->can_die) {
        $to->key_insert(map +(_KEY($_), _VALUE($_)), @$heap[1..$#$heap]);
        $#$heap = 0;
        return;
    }
    while (@$heap > 1) {
        $to->key_insert(_KEY($heap->[-1]), _VALUE($heap->[-1]));
        pop @$heap;
    }
}');

    return $heap->_key_absorb(@_);
}

# end of Heap::Simple::Perl::_key_absorb
1;
