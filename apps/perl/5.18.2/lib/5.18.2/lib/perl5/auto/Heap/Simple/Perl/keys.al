# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 678 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/keys.al)"
sub keys {
    my $heap = shift;
    if($heap->_KEY("") eq "") {
        $heap->_make('sub keys {
    my $heap = shift;
    return @$heap[1..$#$heap]}');
    } else {
        $heap->_make('sub keys {
    my $heap = shift;
    _ELEMENTS_PREPARE()
    return map _KEY($_), @$heap[1..$#$heap]}');
    }
    return $heap->keys(@_);
}

# end of Heap::Simple::Perl::keys
1;
