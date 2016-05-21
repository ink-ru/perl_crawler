use strict;
use WWW::Mechanize;
#use warnings;
#no warnings 'recursion';

my $mech = WWW::Mechanize->new();

my @foundLinks;
my $urlToSpider = $ARGV[0];
$mech->get($urlToSpider);

print "\nThe url that will be spidered is $urlToSpider\n";

print "\nThe links found on the url's starting page\n";

# my @foundLinks = $mech->find_all_links();
my @foundLinks = $mech->find_all_links(url_abs_regex => qr/^\Q$urlToSpider\E/, tag => 'a');

foreach my $linkList(@foundLinks)
{

    print $linkList->url_abs();
    print "\n";
}
