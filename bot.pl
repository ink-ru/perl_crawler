#!/usr/bin/perl

# Подключаем библиотеки
use strict;
use LWP::RobotUA;
use LWP::UserAgent;
use threads;
use threads::shared;


# Установка переменных
my @threads;
my $threads=4;
my $last_p:shared=0;

my $req;
my @urlst;
my $map='http://magizoo.ru/sitemap_000.xml';

# Лог файл для записи

open (LOG, ">bot.log") or die ( "Can't open log file!" );
$| = 1;


# Берем карту сайта
my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0");
$req=HTTP::Request->new(GET =>$map);
$req->method('GET');
$req->header('Accept'=>'text/html');

my $res = $ua->request($req);
my $urls=$res->content;

while ($urls =~ s/<loc>([^<]*)</loc>/)
{
    push @urlst, $1;

 	# $req=HTTP::Request->new(GET=>$1);
	# $req->method('HEAD');
	# $res = $ua->request($req);
	# print "$1 - ", $res->status_line(), "\n";

}

# print '-------------\n', scalar(keys @urlst), "\n";
# print @urls;

#print $res->status_line();
#print "$1\n" if $res->content()=~/(>[^(<|>)]+<)/;

# Создаём нужное количество потоков
for my $t (1..$threads) {
  push @threads, threads->create(\&parse_url, $t);
}
# Дожидаемся окончания работы всех потоков
foreach my $t (@threads) {
  $t->join();
}

sub parse_url
# Парсинг страниц
{
  # Номер текущего потока
  my $num=shift;
  my $count = 0;
  print "+ Thread $num started.\n";

  # Бесконечный цикл
  while (1)
  {
    select (STDOUT); $|=1;

    # Берём следующий номер в списке
    my $seq=$last_p++;
    # Если список кончился, заканчиваем
    if ($seq>=@urlst)
    {
      print "- Thread $num done.\n";
      return;
    }
    # Получаем адрес из списка
    my $turl=$urlst[$seq];

    my $spyder = LWP::RobotUA->new("SeoCheckBot/1.$num", 'y.vasin@demis.ru');
	$spyder->delay(0.01);
	$spyder->use_sleep(1);

	$req=HTTP::Request->new(GET=>$turl);
	$req->method('GET');
	$res = $spyder->request($req);
	$_=$res->content;
	$count = s/<h1[^>]*>(.*)</h1>/ig;
	# print STDOUT $seq, "satus - ", $res->status_line(), " $turl == ", $1, "\n";
	print STDOUT " $turl == ", $1, "\n";
	select (LOG); $|=1;
	# print LOG $seq, "satus - ", $res->status_line(), " $turl == ", $1, "\n";
	print LOG " $turl == ", $1, "\n";

	undef $count;

  }

}

close(LOG) or die "Cannot close file";

__END__
