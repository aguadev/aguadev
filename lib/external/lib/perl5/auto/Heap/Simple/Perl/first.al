# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 453 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/first.al)"
sub first {
    my $heap = shift;
    if ($heap->_VALUE("") eq "") {
        $heap->_make('sub first {
    return shift->[1]
}');

    } else {
        $heap->_make('sub first {
    my $heap = shift;
    return _VALUE(($heap->[1] || return undef))
}');

    }
    return $heap->first(@_);
}

# end of Heap::Simple::Perl::first
1;
