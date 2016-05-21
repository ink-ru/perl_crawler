#!/usr/bin/perl

use strict;
use Modern::Perl;
use WWW::Mechanize;
use warnings;
no warnings 'recursion';

my $root = 'http://sufab.ru/';
my $domain = 'http://sufab.ru';
my $mech = WWW::Mechanize->new(autocheck => 0);

# Лог файл для записи
open (LOG, ">crawler.log") or die ( "Can't open log file!" );
$|=1;

sub visit {
    my $url = shift;
    my $indent = shift || 0;
    my $visited = shift || {};
    my $tab = ' ' x $indent;

    # Already seen that.
    return if $visited->{$url}++;

    # Leaves domain.
    if ($url !~ /^$domain/) {
        # say $tab, "-> $url";
        select (STDOUT); $|=1;
        print STDOUT "$url\n";
        select (LOG); $|=1;
        print LOG "$url\n";
        return;
    }
    
    # Not seen yet.
    # say $tab, "- $url ";
    select (STDOUT); $|=1;
    print STDOUT "$url\n";
    select (LOG); $|=1;
    print LOG "$url\n";
    $mech->get($url);
    visit($_, $indent+2, $visited) for
        map {$_->url_abs} $mech->links;
}

visit($root);
