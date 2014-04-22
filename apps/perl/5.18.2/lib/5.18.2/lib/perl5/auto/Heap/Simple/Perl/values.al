# NOTE: Derived from blib/lib/Heap/Simple/Perl.pm.
# Changes made here will be lost when autosplit is run again.
# See AutoSplit.pm.
package Heap::Simple::Perl;

#line 693 "blib/lib/Heap/Simple/Perl.pm (autosplit into blib/lib/auto/Heap/Simple/Perl/values.al)"
sub values {
    my $heap = shift;
    if($heap->_VALUE("") eq "") {
        $heap->_make('sub values {
    my $heap = shift;
    return @$heap[1..$#$heap]}');
    } else {
        $heap->_make('sub values {
    my $heap = shift;
    return map _VALUE($_), @$heap[1..$#$heap]}');
    }
    return $heap->values(@_);
}

# end of Heap::Simple::Perl::values
1;
