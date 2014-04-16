# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 298 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/insert.al)"
sub insert {
    my $heap = shift;
    if ($heap->_KEY("") eq "") {
        $heap->_make('sub insert {
    my $heap = shift;
    _ORDER_PREPARE()
    _CANT_DIE(
    _MAX_COUNT(my $available = _THE_MAX_COUNT()-$#$heap;)
    if (@_ > 1 _MAX_COUNT(&& $available > 1)) {
	my $first = @$heap;
        my $i = push(@$heap, _MAX_COUNT(splice(@_, 0, $available), @_))-1;
	my @todo = reverse $first/2..$#$heap/2;
        while (my $j = shift @todo) {
	    my $key = $heap->[$j];
            my $l = $j*2;
            while ($l < $i) {
                if (_SMALLER(_KEY($heap->[$l]), $key)) {
                    $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
                } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                    $l--;
                    last;
                }
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
            if ($l == $i && _SMALLER(_KEY($heap->[$l]), $key)) {
                $heap->[$l >> 1] = $heap->[$l];
            } else {
		$l >>= 1;
	    }
            if ($j != $l) {
                $heap->[$l] = $key;
                $l >>= 1;
                push(@todo, $l) if !@todo || $l < $todo[0];
            }
        }
	return _MAX_COUNT(unless @_);
    })
    for my $key (@_) {
    my $i = @$heap;
    _MAX_COUNT(if ($i > _THE_MAX_COUNT()) {
        next unless _SMALLER(_KEY($heap->[1]), $key);
        $i--;
        my $l = 2;
        _CAN_DIE(my $min = $heap->[1]; eval {)
            while ($l < $i) {
                if (_SMALLER(_KEY($heap->[$l]), $key)) {
                    $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
                } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                    $l--;
                    last;
                }
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
            if ($l == $i && _SMALLER(_KEY($heap->[$l]), $key)) {
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
        _CAN_DIE(        1
    } || $heap->_e_recover($l, $min);)
    $heap->[$l >> 1] = $key;
    next;})
    _CAN_DIE(eval {)
        $i = $i >> 1 while $i > 1 && _SMALLER($key, ($heap->[$i] = $heap->[$i >> 1]))
    _CAN_DIE(; 1} || $heap->_i_recover($i));
    $heap->[$i] = $key;
    }}');
    } else {
        $heap->_make('sub insert {
    my $heap = shift;
    _PREPARE()
    _CANT_DIE(
    _MAX_COUNT(my $available = _THE_MAX_COUNT()-$#$heap;)
    if (@_ > 1 _MAX_COUNT(&& $available > 1)) {
	my $first = @$heap;
        my $i = push(@$heap, _MAX_COUNT(splice(@_, 0, $available), @_))-1;
	my @todo = reverse $first/2..$#$heap/2;
        while (my $j = shift @todo) {
	    my $value = $heap->[$j];
            my $key = _KEY($value);
            my $l = $j*2;
            while ($l < $i) {
                if (_SMALLER(_KEY($heap->[$l]), $key)) {
                    $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
                } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                    $l--;
                    last;
                }
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
            if ($l == $i && _SMALLER(_KEY($heap->[$l]), $key)) {
                $heap->[$l >> 1] = $heap->[$l];
            } else {
		$l >>= 1;
	    }
            if ($j != $l) {
                $heap->[$l] = $value;
                $l >>= 1;
                push(@todo, $l) if !@todo || $l < $todo[0];
            }
        }
	return _MAX_COUNT(unless @_);
    })
    for my $value (@_) {
    my $key = _REAL_KEY($value);
    my $i = @$heap;
    _MAX_COUNT(if ($i > _THE_MAX_COUNT()) {
        next unless _SMALLER(_KEY($heap->[1]), $key);
        $i--;
        my $l = 2;
        _CAN_DIE(my $min = $heap->[1]; eval {)
            while ($l < $i) {
                if (_SMALLER(_KEY($heap->[$l]), $key)) {
                    $l++ if _SMALLER(_KEY($heap->[$l+1]), _KEY($heap->[$l]));
                } elsif (!(_SMALLER(_KEY($heap->[++$l]), $key))) {
                    $l--;
                    last;
                }
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
            if ($l == $i && _SMALLER(_KEY($heap->[$l]), $key)) {
                $heap->[$l >> 1] = $heap->[$l];
                $l *= 2;
            }
        _CAN_DIE(        1
    } || $heap->_e_recover($l, $min);)
    $heap->[$l >> 1] = _WRAPPER($key, $value);
    next;})
    _CAN_DIE(eval {)
        $i = $i >> 1 while
        $i > 1 && _SMALLER($key, _KEY(($heap->[$i] = $heap->[$i >> 1])));
    _CAN_DIE(1} || $heap->_i_recover($i);)
    $heap->[$i] = _WRAPPER($key, $value);
    }}');
    }
    $heap->insert(@_);
}

# end of Heap::Simple::Perl::insert
1;
