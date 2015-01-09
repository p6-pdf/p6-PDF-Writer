use v6;
use Test;

plan 5;

use PDF::Core::IndObj;

use PDF::Grammar::PDF;
use PDF::Grammar::PDF::Actions;
use PDF::Core;

my $actions = PDF::Grammar::PDF::Actions.new;

my $input = 't/pdf/ind-obj-ObjStm-Flate.in'.IO.slurp( :enc<latin-1> );
PDF::Grammar::PDF.parse($input, :$actions, :rule<ind-obj>)
    // die "parse failed";
my $indobj-ast = $/.ast;

my $ind-obj = PDF::Core::IndObj.new-delegate( |%( $indobj-ast.kv ) );
isa_ok $ind-obj, ::('PDF::Core::IndObj')::('Stream');
isa_ok $ind-obj.dict, Hash, '$.dict';
is $ind-obj.dict<Length>.value, 167, '$.dict<Length>';
is $ind-obj.obj-num, 5, '$.obj-num';
is $ind-obj.gen-num, 0, '$.gen-num';