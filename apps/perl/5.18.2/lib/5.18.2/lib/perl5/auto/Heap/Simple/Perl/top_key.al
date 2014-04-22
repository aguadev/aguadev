# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 601 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/top_key.al)"
sub top_key {
    my $heap = shift;
    if ($heap->_QUICK_KEY("") ne "-") {
        $heap->_make('sub top_key {
    my $heap = shift;
    return @$heap > 1 ? _QUICK_KEY($heap->[1]) :
        defined($heap->[0]{infinity}) ? $heap->[0]{infinity} : Carp::croak "Empty heap"
}');

    } else {
        $heap->_make('sub top_key {
    my $heap = shift;
    return defined($heap->[0]{infinity}) ? $heap->[0]{infinity} : Carp::croak "Empty heap" if @$heap <= 1;
    _ELEMENTS_PREPARE()
    return _KEY($heap->[1])
}');

    }
    $heap->top_key(@_);
}

# end of Heap::Simple::Perl::top_key
1;
