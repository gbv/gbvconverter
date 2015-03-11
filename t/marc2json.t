use Test::More;
use v5.14;

use GBV::App::Convert::MARC2JSON qw(marc2json);

my $marc = marc2json('t/data/4021477-1.xml');
is_deeply $marc->{record}->[-1], [
   '913',
   ' ',
   ' ',
   'S',
   'gkd',
   'i',
   'a',
   'a',
   "G\x{6F}\x{308}ttingen", # decomposed
   '0',
   '(DE-588b)8214-4'
 ], 'marc2json';

$marc = marc2json('t/data/4021477-1.xml', normalize => 'NFC');
is $marc->{record}->[-1]->[8], "G\x{F6}ttingen", 'normalize';

done_testing;
