use v6;
use Test;
plan 21;

use PDF::COS;
use PDF::COS::DateString;

my $date-spec = "D:199812231952-08'00'";
ok $date-spec ~~ PDF::COS::DateString::DateRegex, 'DateRegex match';

my PDF::COS::DateString $date .= new($date-spec);

is $date.year, 1998, 'Date year';
is $date.month, 12, 'Date month';
is $date.day, 23, 'Date day';
is $date.hour, 19, 'Date hour';
is $date.minute, 52, 'Date minute';
is $date.offset, -8*60*60, 'Date offset';

$date .= new("1999");
is $date.year, 1999, 'Date year';
is $date.month,   1, 'Date month (default)';
is $date.day,     1, 'Date day (default)';
is $date.hour,    0, 'Date hour (default)';
is $date.minute,  0, 'Date minute (default)';
is $date.offset,  0, 'Date offset (default)';

use PDF::COS::Dict;
class MyInfo is PDF::COS::Dict {
    use PDF::COS::Tie;
    has PDF::COS::DateString $.CreationDate is entry;
}

my MyInfo $info .= new( :dict{ :CreationDate( :literal<D:20130629204853+02'00'> ) } );

is $info.CreationDate, q<D:20130629204853+02'00'>, 'raw creation date';
my $creation-date = $info.CreationDate;
isa-ok $creation-date, DateTime;
is $creation-date.year, 2013, 'creation date year';
is $creation-date.offset, 2*60*60, 'creation date offset';
is ~$creation-date, q<D:20130629204853+02'00'>, 'creation data stringified';

is-deeply $creation-date.content, (:literal<D:20130629204853+02'00'>), 'creation date content';

lives-ok {$info.CreationDate = DateTime.new(:year(2105), :month(12), :day(25))}, "DateTime assignment - lives";
is-deeply $creation-date.content, (:literal<D:20130629204853+02'00'>), 'creation date content';

done-testing;
