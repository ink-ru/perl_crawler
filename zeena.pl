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
my @urlst:shared;
my @urlst_done:shared;
my $log;

my $strt='http://sufab.ru/';

push @urlst, $strt;

# Лог файл для записи

open ($log, "+<:encoding(UTF-8)", "zeena.log") or die ( "Can't open $log file!" );
#open ($log, "+<zeena.log") or die ( "Can't open $log file!" );
$| = 1;

my $spyder = LWP::RobotUA->new("SeoCheckBot/main", 'y.vasin@demis.ru');
$spyder->delay(0.01);
$spyder->use_sleep(1);

my $req=HTTP::Request->new(GET=>$strt);
$req->method('GET');
my $res = $spyder->request($req); # response
# $_=$res->content;

if ($res->is_success() && $res->content_type() eq 'text/html')
  {
    # my @matches = $_ =~ /href\s*=\s*["']\S+["']/g;
    my @matches = ( $res->content =~ /href\s*=\s*["'](\S+)["']/g );
    print STDOUT "Initial scaning\nsatus - ", $res->status_line(), ", кол-во: ", 0+@matches, "\n";
    # print STDOUT $res->content;

    push @urlst, @matches;
  }

push @urlst_done, $strt;
undef $req;
undef $res;



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
  my $req;
  # Номер текущего потока
  my $num=shift;
  my @matches;

  print "+ Thread $num started.\n";

  my $spyder = LWP::RobotUA->new("SeoCheckBot/2.$num", 'y.vasin@demis.ru');
  $spyder->delay(0.01);
  $spyder->use_sleep(1);
  
  select (STDOUT); $|=1;

  while(1)
  {
    # Берём следующий номер в списке
    my $seq=$last_p++;

      # Если список кончился, заканчиваем
      # if ($seq>=@urlst)
      if( $seq >= 0+@urlst)
        {
          print "- Thread $num done.\n";
          return;
        }
      # Получаем адрес из списка
      my $turl = @urlst[$seq];
      $turl =~ s/^\s+|\s+$//g;

      # if( (!$turl eq '') and (index($turl, '#') < 0) )
      if( !($turl eq '') and (index($turl, $strt) > 0) )
      {
        $turl =~ s/^\/+$//g;
        if(index($turl, ':') < 0)
        {
          $turl = $strt.'/'.$turl;
        }
        if ( !grep( /^$turl$/, @urlst_done ) )
        {
	        # print STDOUT "trying ", $turl, "\n";

	      	$req=HTTP::Request->new(GET=>$turl);
	      	$req->method('GET');
	      	my $res = $spyder->request($req); # response
	      	# $_=$res->content;

	        if ($res->is_success() && $res->content_type() eq 'text/html')
	        {
	          # my @matches = $_ =~ /href\s*=\s*["']\S+["']/g;
	          my @matches = ( $res->content =~ /href\s*=\s*["'](\S+)["']/g );
	          # push @matches, [$1] while $res->content =~ /href\s*=\s*["'](\S+)["']/g;
	        	print STDOUT $seq, "satus - ", $res->status_line(), " $turl, кол-во: ", 0+@matches, "\n";

	          push @urlst, @matches;
	        }

	        push @urlst_done, $turl;

	        # Записываем найденные ссылки в файл
			select ($log); $|=1;
			foreach my $link (@urlst)
      {
        if ( !grep( /^$link$/, $log ) and !($link =~ m/(#|\.jpg|\.png|\.gif|\.css|\.js|skype:|tel:)/))
        {
          print $log $link, "\n";
        }
      }

	        undef $req;
	        undef $res;
    	}
        undef $turl;
      }
  }

}

close($log) or die "Cannot close file";

__END__
