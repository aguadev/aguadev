# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 802 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/merge_arrays.al)"
sub merge_arrays {
    my $heap = shift;
    $heap->_make('sub merge_arrays {
    if (@_ <= 2) {
        return [] if @_ <= 1;
        my $array = $_[1];
        _MAX_COUNT(my $start = @$array - _THE_MAX_COUNT();
        return [@$array[$start..$#$array]] if $start > 0;)
        return [@$array];
    }
    my $heap = shift;
    my @heap = (undef);
    _REAL_PREPARE()
    my $key;
    my $left = 0;
    _MAX_COUNT(my $sorted;)
    for my $array (@_) {
        next if !@$array;
        _MAX_COUNT(if ($#heap == _THE_MAX_COUNT()) {
            unless ($sorted) {
                my $half = _THE_MAX_COUNT() >> 1;
                while ($half) {
                    my $l = $half * 2;
                    my $work = $heap[$half--];
                    while ($l < _THE_MAX_COUNT()) {
                        if (_SMALLER($heap[$l][0], $work->[0])) {
                            $l++ if _SMALLER($heap[$l+1][0], $heap[$l][0]);
                        } elsif (!(_SMALLER($heap[++$l][0], $work->[0]))) {
                            $l--;
                            last;
                        }
                        $heap[$l >> 1] = $heap[$l];
                        $l *= 2;
                    }
                    if ($l == _THE_MAX_COUNT() && _SMALLER($heap[_THE_MAX_COUNT()][0], $work->[0])) {
                        $heap[_THE_MAX_COUNT() >> 1] = $heap[_THE_MAX_COUNT()];
                        $l = _THE_MAX_COUNT() * 2;
                    }
                    $heap[$l >> 1] = $work;
                }
                $sorted = 1;
            }

            $key = _REAL_KEY($array->[-1]);
            next unless _SMALLER($heap[1][0], $key);
            my $l = 2;
            while ($l < _THE_MAX_COUNT()) {
                if (_SMALLER($heap[$l][0], $key)) {
                    $l++ if _SMALLER($heap[$l+1][0], $heap[$l][0]);
                } elsif (!(_SMALLER($heap[++$l][0], $key))) {
                    $l--;
                    last;
                }
                $heap[$l >> 1] = $heap[$l];
                $l *= 2;
            }
            if ($l == _THE_MAX_COUNT() && _SMALLER($heap[_THE_MAX_COUNT()][0], $key)) {
                $heap[_THE_MAX_COUNT() >> 1] = $heap[_THE_MAX_COUNT()];
            } else {
                $l >>= 1;
            }
            $left -= $heap[$l][2];
            $heap[$l] = [$key, $array, $#$array];
            $left += $heap[$l][2];
            next;
        })
        push(@heap, [_REAL_KEY($array->[-1]), $array, $#$array]);
        $left += @$array;
    }

    if (@heap <= 2) {
        return [] if @heap <= 1;
        my $array = $heap[1][1];
        _MAX_COUNT(my $start = @$array - _THE_MAX_COUNT();
        return [@$array[$start..$#$array]] if $start > 0;)
        return [@$array];
    }

    my $n = $#heap;
    my $half = $n >> 1;
    while ($half) {
        my $l = $half * 2;
        my $work = $heap[$half--];
        while ($l < $n) {
            if (_SMALLER($work->[0], $heap[$l][0])) {
                $l++ if _SMALLER($heap[$l][0], $heap[$l+1][0]);
            } elsif (!(_SMALLER($work->[0], $heap[++$l][0]))) {
                $l--;
                last;
            }
            $heap[$l >> 1] = $heap[$l];
            $l *= 2;
        }
        if ($l == $n && _SMALLER($work->[0], $heap[$l][0])) {
            $heap[$l >> 1] = $heap[$l];
            $l *= 2;
        }
        $heap[$l >> 1] = $work;
    }

    _MAX_COUNT($left = _THE_MAX_COUNT() if $left > _THE_MAX_COUNT();)
    my @result;
    while (1) {
        my $work = $heap[1];
        my $j = $work->[2];
        $result[--$left] = $work->[1][$j--];
        _MAX_COUNT(return \@result unless $left;)
        if ($j >= 0) {
            $key = _REAL_KEY($work->[1][$j]);
            $work->[0] = $key;
            $work->[2] = $j;
        } else {
            $work = pop @heap;
            if (--$n <= 1) {
                $left--;
                @result[0..$left] = @{$work->[1]}[$work->[2]-$left..$work->[2]];
                return \@result;
            }
            $key = $work->[0];
        }
        my $l = 2;
        while ($l < $n) {
            if (_SMALLER($key, $heap[$l][0])) {
                $l++ if _SMALLER($heap[$l][0], $heap[$l+1][0]);
            } elsif (!(_SMALLER($key, $heap[++$l][0]))) {
                $l--;
                last;
            }
            $heap[$l >> 1] = $heap[$l];
            $l *= 2;
        }
        if ($l == $n && _SMALLER($key, $heap[$l][0])) {
            $heap[$l >> 1] = $heap[$l];
            $l *= 2;
        }
        $heap[$l >> 1] = $work;
    }
}');

    $heap->merge_arrays(@_);
}

1;
__END__

1;
# end of Heap::Simple::Perl::merge_arrays
