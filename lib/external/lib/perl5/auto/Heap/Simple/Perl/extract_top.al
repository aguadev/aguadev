# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 484 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/extract_top.al)"
sub extract_top {
    my $heap = shift;
    $heap->_make('sub extract_top {
    my $heap = shift;
    if (@$heap <= 3) {
        return _VALUE(pop(@$heap)) if @$heap == 2;
        Carp::croak "Empty heap" if @$heap < 2;
        my $min = $heap->[1];
        $heap->[1] = pop @$heap;
        return _VALUE($min);
    }
    my $min = $heap->[1];
    _PREPARE()
    my $key = _KEY($heap->[-1]);
    my $n = @$heap-2;
    my $l = 2;
    _CAN_DIE(eval {)
        while ($l < $n) {
            if (_SMALLER(_KEY($heap->[$l]), $key)) {
                $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
            } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                $l--;
                last;
            }
            $heap->[$l >> 1] = $heap->[$l];
            $l *= 2;
        }
        if ($l == $n && _SMALLER(_KEY($heap->[$l]), $key)) {
            $heap->[$l >> 1] = $heap->[$l];
            $l *= 2;
        }
    _CAN_DIE(        1
    } || $heap->_e_recover($l, $min);)
    $heap->[$l >> 1] = pop(@$heap);
    return _VALUE($min);
}');

    $heap->extract_top(@_);
}

# end of Heap::Simple::Perl::extract_top
1;
