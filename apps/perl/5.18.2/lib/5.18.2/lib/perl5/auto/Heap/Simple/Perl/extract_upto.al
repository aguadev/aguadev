# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 439 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/extract_upto.al)"
sub extract_upto {
    my $heap = shift;
    $heap->_make('sub extract_upto {
    my $heap   = shift;
    my $border = shift;
    _PREPARE()
    my @result;
    push(@result, $heap->extract_top) until
        @$heap <= 1 || _SMALLER($border, _KEY($heap->[1]));
    return @result
}');

    $heap->extract_upto(@_);
}

# end of Heap::Simple::Perl::extract_upto
1;
