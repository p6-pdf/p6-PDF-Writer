use v6;

use PDF::COS;
use PDF::COS::Tie::Array;

class PDF::COS::Array
    is Array
    does PDF::COS
    does PDF::COS::Tie::Array {

    use PDF::COS::Util :from-ast, :to-ast;

    my %seen{Any} = (); #= to catch circular references

    submethod TWEAK(:$array!) {
        %seen{$array} = self;
        self.tie-init;
        # this may trigger cascading PDF::COS::Tie coercians
        # e.g. native Array to PDF::COS::Array
        self[.key] = from-ast(.value) for $array.pairs;

        self.?cb-init();
    }

    method new(List() :$array = [], |c) {
        %seen{$array} // do {
            temp %seen{$array};
            self.bless(:$array, |c);
        }
    }

    my %content-cache{Any} = ();

    method content {
	my $obj = self;
        my $array = %content-cache{$obj};
        unless $array {
	    # to-ast may recursively call $.content. cache to break any cycles
            temp %content-cache{$obj} = $array = [];
            $array.push: to-ast($_)
                for self.list;
        }
        :$array;
    }
    multi method COERCE(PDF::COS::Array $array) is default { $array }
    multi method COERCE(List $array is raw, |c) {
        my $class := PDF::COS.load-array: $array, :base-class(self.WHAT);
        $class.new: :$array, |c;
    }
    multi method COERCE(Seq:D $seq is raw, |c) {
        self.COERCE: $seq.Array, |c;
    }

}
