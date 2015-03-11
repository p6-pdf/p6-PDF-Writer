use v6;

use PDF::Object :to-ast;
use PDF::Object::Dict;
use PDF::Object::Stream;
use PDF::Tools::IndObj;

class PDF::Tools::Serializer {

    has Int $!cur-obj-num = 0;
    has @.ind-objs;
    has %!obj-num;
    has %.ref-count;

    method !get-ind-ref( Int :$id!) {
        :ind-ref[ %!obj-num{$id}, 0 ]
            if %!obj-num{$id}:exists;
    }

    method !make-ind-ref( Pair $ind-obj! is rw, Int :$id!) {
        my $obj-num = ++ $!cur-obj-num;
        @.ind-objs.push: (:ind-obj[ $obj-num, 0, $ind-obj]);
        %!obj-num{$id} = $obj-num;
        :ind-ref[ $obj-num, 0];
    }

    multi method analyse( Hash $dict! is rw) {
        return if %!ref-count{$dict.WHERE}++; # already encountered
        $.analyse($_) for $dict.values;
    }

    multi method analyse( Array $array! is rw ) {
        return if %!ref-count{$array.WHERE}++; # already encountered
        $.analyse($_) for $array.list;
    }

    #| we don't reference count anything else at the moment. Might consider
    #| making ind-refs for longish duplicated strings.
    multi method analyse( $other! is rw ) is default {
    }

    method !freeze-dict( Hash $dict is rw) {
        my %frozen;
        %frozen{.key} = $.freeze( .value )
            for $dict.pairs;
        %frozen;
    }

    method !freeze-array( Array $array is rw) {
        my @frozen;
        @frozen.push( $.freeze( $_ ) )
            for $array.list;
        @frozen;
    }

    #| handles PDF::Object::Dict, PDF::Object::Stream, (plain) Hash
    multi method freeze( Hash $object! is rw, Bool :$is-root ) {
        my $id = $object.WHERE;

        # already an indirect object
        return self!"get-ind-ref"(:$id )
            if %!obj-num{$id}:exists;

        my $has-type = $object<Type>:exists;
        my $is-stream = $object.isa(PDF::Object::Stream);

        my $ind-obj = dict => Mu;
        my $slot := $ind-obj.value;

        if $is-stream {
            $ind-obj = :stream{
                :$ind-obj,
                :encoded($object.encoded),
            }
        }

        my $ret = $is-stream || $is-root || $has-type || %!ref-count{$id} > 1
            ?? self!"make-ind-ref"($ind-obj, :$id )
            !! $ind-obj;

        $slot = self!"freeze-dict"($object);

        $ret;
    }

    #| handles PDF::Object::Array, (plain( Array
    multi method freeze( Array $array! is rw, Bool :$is-root ) {
        my $id = $array.WHERE;

        # already an indirect object
        return self!"get-ind-ref"( :$id )
            if %!obj-num{$id}:exists;

        my $ind-obj = array => Mu;
        my $slot := $ind-obj.value;

        my $ret = $is-root || %!ref-count{$id} > 1
            ?? self!"make-ind-ref"($ind-obj, :$id )
            !! $ind-obj;

        $slot = self!"freeze-array"($array);

        $ret;
    }

    #| handles other basic types
    multi method freeze($other) {
        to-ast $other;
    }

}
