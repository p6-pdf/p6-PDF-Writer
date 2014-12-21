use v6;
# based on Perl 5's PDF::API::Basic::PDF::Filter::ASCIIHexDecode

use PDF::Basic::Filter;

class PDF::Basic::Filter::ASCIIHex
    is PDF::Basic::Filter;

# Maintainer's Note: ASCIIHexDecode is described in the PDF 1.7 spec
# in section 7.4.2.

method encode($input, Bool :$eod) {

    $input.subst(/(.)/, {
        my $ord = $0.ord;
        die 'illegal non-byte character > \xFF' if $ord > 0xFF;
        sprintf '%02x', $ord;
    }, :g) ~ ($eod ?? '>' !! '');

}

method decode($input, Bool :$eod) {

    my $str = $input.subst(/\s/, '', :g);

    if $str && $str.substr(*-1,1) eq '>' {
        $str = $str.chop;

        # "If the filter encounters the EOD marker after reading an odd
        # number of hexadecimal digits, it shall behave as if a 0 (zero)
        # followed the last digit."

        $str ~= '0'
            unless $str.chars %% 2;
    }
    else {
       die "missing end-of-data marker '>' at end of hexidecimal encoding"
           if $eod
    }

    die "Illegal character found in ASCII hex-encoded stream"
        if $str ~~ m:i/< -[0..9 A..F]>/;

    return $str.subst( /(..?)/, -> $/ { :16(~$0).chr }, :g );
}