use v6;
use Test;
plan 13;

use PDF::IO::IndObj;

use PDF::Grammar::PDF;
use PDF::Grammar::PDF::Actions;

my $actions = PDF::Grammar::PDF::Actions.new;

my $input = 't/pdf/ind-obj-ObjStm-Flate.in'.IO.slurp( :enc<latin-1> );
PDF::Grammar::PDF.parse($input, :$actions, :rule<ind-obj>)
    // die "parse failed";
my %ast = $/.ast;
my $ind-obj = PDF::IO::IndObj.new( |%ast, :$input );
does-ok $ind-obj.object, ::('PDF::COS::Type')::('ObjStm');

my $objstm;
lives-ok { $objstm = $ind-obj.object.decode }, 'basic content decode - lives';

my $expected-objstm = [
    [16, "<</BaseFont/CourierNewPSMT/Encoding/WinAnsiEncoding/FirstChar 111/FontDescriptor 15 0 R/LastChar 111/Subtype/TrueType/Type/Font/Widths[600]>>",
    ],
    [17, "<</BaseFont/TimesNewRomanPSMT/Encoding/WinAnsiEncoding/FirstChar 32/FontDescriptor 14 0 R/LastChar 32/Subtype/TrueType/Type/Font/Widths[250]>>",
    ],
    ];

is-deeply $objstm, $expected-objstm, 'decoded index as expected';
my $objstm-recompressed = $ind-obj.object.encode;
lives-ok {$ind-obj.object.check}, '.check lives';

my %ast2;
lives-ok { %ast2 = $ind-obj.ast }, '$.ast - lives';

my $ind-obj2 = PDF::IO::IndObj.new( |%ast2 );
my $objstm-roundtrip = $ind-obj2.object.decode( $objstm-recompressed );

is-deeply $objstm, $objstm-roundtrip, 'encode/decode round-trip';
lives-ok {::('PDF::COS::Type')::('ObjStm').new(:dict{ :N(1), :First(1) }, :decoded[[10, '<< /Foo (bar) >>']])}, 'ObjStm.new';
my $objstm-new = ::('PDF::COS::Type')::('ObjStm').new(:dict{ :N(1), :First(1) }, :decoded[[10, '<< /Foo (bar) >>'], [11, '[ 42 true ]']] );
lives-ok {$objstm-new.encode( :check )}, '$.encode( :check ) - with valid data lives';
is $objstm-new.Type, 'ObjStm', '$objstm.new .Name auto-setup';
is $objstm-new.N, 2, '$objstm.new .N auto-setup';
is $objstm-new.First, 11, '$objstm.new .First auto-setup';

my $invalid-decoding =  [[10, '<< /Foo wtf!! (bar) >>'], [11, '[ 42 true ]']];
lives-ok {$objstm-new.encode( $invalid-decoding) }, 'encoding invalid data without :check - lives';
dies-ok {$objstm-new.encode( $invalid-decoding, :check) }, 'encoding invalid data with :check - dies';