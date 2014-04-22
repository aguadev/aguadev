# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 661 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/key.al)"
sub key {
    my $heap = shift;
    if ($heap->_KEY("") eq "") {
        $heap->_make('sub key {
    return $_[1]}');
    } elsif ($heap->_QUICK_KEY("") ne "-") {
        $heap->_make('sub key {
    return _QUICK_KEY($_[1])}');
    } else {
        $heap->_make('sub key {
    my $heap = shift;
    _REAL_ELEMENTS_PREPARE()
    return _REAL_KEY(shift)}');
    }
    return $heap->key(@_);
}

# end of Heap::Simple::Perl::key
1;
