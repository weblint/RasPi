#!/usr/bin/perl
use LWP::UserAgent;
use POSIX qw/strftime/;
use Time::Local;

my $Datum=strftime "%d.%m.%Y", localtime;
my $dir = '/home/pi/';
#my $metar_url = 'http://weather.noaa.gov/pub/data/observations/metar/stations/EDLP.TXT';
my $metar_url = 'http://de.allmetsat.com/metar-taf/deutschland.php?icao=EDLP';
my $is_celsius = 1; #set to 1 if using Celsius

my $ua = new LWP::UserAgent;
$ua->timeout(120);
my $request = new HTTP::Request('GET', $metar_url);
my $response = $ua->request($request);
my $metar= $response->content();

$metar =~ /([\s|Mt])(\d{2})\//g;
$outtemp = ($1 eq 'Mt') ? $2 * -1 : $2; #'M' in a METAR report signifies below 0 temps
$outtemp = ($is_celsius) ? $outtemp + 0 : ($outtemp * 9/5) + 32;

$modules = `cat /proc/modules`;
if ($modules =~ /w1_therm/ && $modules =~ /w1_gpio/)
{
        #modules installed
}
else
{
        $gpio = `sudo modprobe w1-gpio`;
        $therm = `sudo modprobe w1-therm`;
}

$output = "";
$attempts = 0;
while ($output !~ /YES/g && $attempts < 5)
{
        $output = `sudo cat /sys/bus/w1/devices/28-*/w1_slave 2>&1`;
        if($output =~ /No such file or directory/)
        {
                print "Could not find DS18B20\n";
                last;
        }
        elsif($output !~ /NO/g)
        {
                $output =~ /t=(\d+)/i;
                $temp = ($is_celsius) ? ($1 / 1000) : (($1 / 1000) * 9/5 + 32);
                $rrd = `/usr/bin/rrdtool update $dir/hometemp.rrd N:$temp:$outtemp`;
        }

        $attempts++;
}

print "Inside temp: $temp\n";
print "Outside temp: $outtemp\n";
#print "$Datum\n";
print strftime "%Y-%m-%d %H:%M:%S", localtime(time);
print "\n";
print "----------------\n";
