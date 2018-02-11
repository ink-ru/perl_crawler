#! /usr/bin/perl

##############################
# GNU, george.a.wise@gmail.com
##############################

use XML::Simple;
use LWP;
#use Event::ScreenSaver;

$xml_pth="/etc/boinc-client/global_prefs_override.xml";
$dbg = 0;

my $browser = LWP::UserAgent->new;

my @ns_headers = (
       'User-Agent' => 'Mozilla/5.0 (Ubuntu; X11; Linux i686; rv:8.0) Gecko/20100101 Firefox/8.0',
       'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
       'Accept-Charset' => 'windows-1251,utf-8;q=0.7,*;q=0.7',
       'Accept-Language' => 'ru-ru,ru;q=0.8,en-us;q=0.5,en;q=0.3',
       'Authorization' => 'Basic YWRtaW46UG9pc29uMzU3'
      );

my $url_on = 'http://30.30.30.1/wlcfg.wl?wlSsidIdx=0&wlEnbl=1&wlHide=0&wlAPIsolation=0&wlSsid=ColdSpot&wlCountry=UA&wlMaxAssoc=3&wlDisableWme=0&wlEnbl_wl0v1=0&wlSsid_wl0v1=Guest&wlHide_wl0v1=0&wlAPIsolation_wl0v1=0&wlDisableWme_wl0v1=0&wlMaxAssoc_wl0v1=16';
my $url_off ='http://30.30.30.1/wlcfg.wl?wlSsidIdx=0&wlEnbl=0&wlHide=0&wlAPIsolation=0&wlSsid=ColdSpot&wlCountry=UA&wlMaxAssoc=3&wlDisableWme=0&wlEnbl_wl0v1=0&wlSsid_wl0v1=Guest&wlHide_wl0v1=0&wlAPIsolation_wl0v1=0&wlDisableWme_wl0v1=0&wlMaxAssoc_wl0v1=16';

# =========================
# use Log::Log4perl;
# my $conf = "
#        log4perl.logger.Main                = ALL, FileApp
#        log4perl.appender.FileApp           = Log::Log4perl::Appender::File
#        log4perl.appender.FileApp.filename  = /opt/my/log_file.txt
#        log4perl.appender.FileApp.layout    = PatternLayout";

#Log::Log4perl->init(\$conf);
#my $logger = Log::Log4perl->get_logger('Main');

#$logger->info('сообщение');


my $simple = XML::Simple->new(ForceArray => 1, KeepRoot => 1);
my $data   = $simple->XMLin($xml_pth);

$time=localtime(time);
$time=~s/[^:]+ (\d{2}):.*/$1/;
$time=~s/0(\d{1})/$1/;

$tm = `xprintidle`;
#$tm = system "xprintidle";
$tm = $tm/1000;
if($dbg) { print $tm." idle\n"; }

my $lmt = 30;
$dm = "empty";

my $oldcpu = $$data{'global_preferences'}[0]{'cpu_usage_limit'}[0];

if(($time > 16 && $time < 21) || ($time > 8 && $time < 14))
{

    $dm = `xrandr --output VGA1 --brightness 1.0`;
    
    $response = $browser->get($url_on, @ns_headers);
    print "Can't get $url -- ", $response->status_line
        unless $response->is_success;
    
    if($dbg)
    {
        print "Hey, I was expecting HTML, not ", $response->content_type unless $response->content_type eq 'text/html';
        print "Включаем WiFi.\n";
    }

    if($tm > $lmt)
    {
    	if($oldcpu < 50)
    	{
    	    $$data{'global_preferences'}[0]{'cpu_usage_limit'}[0]="90.00";
    	    
    	    $simple->XMLout($data, KeepRoot => 1, OutputFile => $xml_pth);
    	    
    	    $dm = `boinccmd --read_global_prefs_override`;
    	    if($dbg)
    	    {
    		print $dm."\n";
    		print "Повышвем мощность\n";
    		$dm = `notify-send -t 3 "BOINC" "$tm, Выходим на полную мощность!"`;
    	    }
    	} else { if($dbg) { print "Нечего делать!\n"; } }
    }
    else
    {
    	if($$data{'global_preferences'}[0]{'cpu_usage_limit'}[0] != 40)
    	{
    	    $$data{'global_preferences'}[0]{'cpu_usage_limit'}[0]="40.00";
    	    
    	    $simple->XMLout($data, KeepRoot => 1, OutputFile => $xml_pth);
    	
    	    $dm = `boinccmd --read_global_prefs_override`;
    	    if($dbg)
    	    {
    		print $dm."\n";
    		print "Снижаем мощность\n";
    		$dm = `notify-send -t 3 "BOINC" "$tm, Снижаем мощность!"`;
    	    }
    	} else { if($dbg) { print "Нечего делать!\n"; } }
    }
}
else
{
    if($$data{'global_preferences'}[0]{'cpu_usage_limit'}[0] > 12)
    {
    	$$data{'global_preferences'}[0]{'cpu_usage_limit'}[0]="10.00";
    	
    	$simple->XMLout($data, KeepRoot => 1, OutputFile => $xml_pth);
    	
    	$dm = `boinccmd --read_global_prefs_override`;
    	if($dbg)
    	{
    	    print $dm."\n";
    	    print "Снижаем мощность\n";
    	    $dm = `notify-send -t 3 "BOINC" "$tm, Снижаем мощность!"`;
    	}
    } else { if($dbg) { print "Нечего делать - спим!\n"; } }
    	
    	
    if($time < 9 || $time > 22 )
    {
	$dm = `xrandr --output VGA1 --brightness 0.8`;
	
	$response = $browser->get($url_off, @ns_headers);
	print "Can't get $url -- ", $response->status_line
	    unless $response->is_success;
	
	if($dbg)
	{
	    print "Hey, I was expecting HTML, not ", $response->content_type unless $response->content_type eq 'text/html';
	    print "Выключаем WiFi.\n";
	}
    }
    else
    {
	#$dm = `xrandr --output VGA1 --brightness 0.9`;
    }
}

#=============================================================
my $tmp = `cat /sys/class/hwmon/hwmon0/temp1_input`;
$tmp =~ s/^(\d{2}).*/$1/;
if($tmp > 75)
{
    
    $dm = `sudo /sbin/shutdown 0`;
    
    $dm = `notify-send -t 60 "Перегрев" "Процессор перегрелся!!!"`;
}
else
{
    if($tmp > 70)
    {
	$$data{'global_preferences'}[0]{'cpu_usage_limit'}[0]="10.00";
    	if($dbg) { print "Снижаем мощность\n"; }
    	$simple->XMLout($data, KeepRoot => 1, OutputFile => $xml_pth);
    	$dm = `boinccmd --read_global_prefs_override`;
    	
	$dm = `notify-send -t 30 "Перегрев" "перегрев"`;
    }
}

#=============================================================



__end__

