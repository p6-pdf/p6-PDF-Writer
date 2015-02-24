use v6;
use Test;

plan 11;

use PDF::Tools::IndObj;

use PDF::Grammar::PDF;
use PDF::Grammar::PDF::Actions;

my $actions = PDF::Grammar::PDF::Actions.new;

my $input = 't/pdf/ind-obj-ObjStm-Flate.in'.IO.slurp( :enc<latin-1> );
PDF::Grammar::PDF.parse($input, :$actions, :rule<ind-obj>)
    // die "parse failed";
my $ast = $/.ast;
my $ind-obj = PDF::Tools::IndObj.new-delegate( |%$ast, :$input );
isa_ok $ind-obj, ::('PDF::Tools::IndObj')::('Type::ObjStm');

my $objstm;
lives_ok { $objstm = $ind-obj.decode }, 'basic content decode - lives';

my $expected-objstm = [
    [16, "<</BaseFont/CourierNewPSMT/Encoding/WinAnsiEncoding/FirstChar 111/FontDescriptor 15 0 R/LastChar 111/Subtype/TrueType/Type/Font/Widths[600]>>",
    ],
    [17, "<</BaseFont/TimesNewRomanPSMT/Encoding/WinAnsiEncoding/FirstChar 32/FontDescriptor 14 0 R/LastChar 32/Subtype/TrueType/Type/Font/Widths[250]>>",
    ],
    ];

is_deeply $objstm, $expected-objstm, 'decoded index as expected';
my $objstm-recompressed = $ind-obj.encode;

my $ast2;
lives_ok { $ast2 = $ind-obj.ast }, '$.ast - lives';

my $ind-obj2 = PDF::Tools::IndObj.new-delegate( |%$ast2 );
my $objstm-roundtrip = $ind-obj2.decode( $objstm-recompressed );

is_deeply $objstm, $objstm-roundtrip, 'encode/decode round-trip';

my $objstm-new = ::('PDF::Tools::IndObj')::('Type::ObjStm').new(:dict{}, :decoded[[10, '<< /Foo (bar) >>'], [11, '[ 42 true ]']] );
lives_ok {$objstm-new.encode( :check )}, '$.encode( :check ) - with valid data lives';
is_deeply $objstm-new.Type, (:name<ObjStm>), '$xref.new .Name auto-setup';
is_deeply $objstm-new.N, (:int(2)), '$xref.new .N auto-setup';
is_deeply $objstm-new.First, (:int(11)), '$xref.new .First auto-setup';

my $invalid-decoding =  [[10, '<< /Foo wtf!! (bar) >>'], [11, '[ 42 true ]']];
lives_ok {$objstm-new.encode( $invalid-decoding) }, 'encoding invlaid data without :check (lives)';
dies_ok {$objstm-new.encode( $invalid-decoding, :check) }, 'encoding invlaid data without :check (dies)';
