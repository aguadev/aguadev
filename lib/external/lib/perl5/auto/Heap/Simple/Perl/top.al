# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 468 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/top.al)"
sub top {
    my $heap = shift;
    if ($heap->_KEY("") eq "") {
    $heap->_make('sub top {
    Carp::croak "Empty heap" if @{$_[0]} < 2;
    return _VALUE(shift->[1])
}');

    } else {
        $heap->_make('sub top {
    my $heap = shift;
    return _VALUE(($heap->[1] || Carp::croak "Empty heap"))
}');

    }
    $heap->top(@_);
}

# end of Heap::Simple::Perl::top
1;
