# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 640 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/first_key.al)"
sub first_key {
    my $heap = shift;
    if ($heap->_KEY("") eq "") {
        $heap->_make('sub first_key {
    return shift->[1]}');
    } elsif ($heap->_QUICK_KEY("") ne "-") {
        $heap->_make('sub first_key {
    my $heap = shift;
    return _QUICK_KEY(($heap->[1] || return undef))
}');

    } else {
    $heap->_make('sub first_key {
        my $heap = shift;
    return undef if @$heap <= 1;	# avoid autovivify
    _ELEMENTS_PREPARE()
    return _KEY($heap->[1])
}');

    }
    return $heap->first_key(@_);
}

# end of Heap::Simple::Perl::first_key
1;
