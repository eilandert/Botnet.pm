#!/usr/bin/perl

use Botnet;

my $ip = shift(@ARGV);
my $domain = shift(@ARGV);
my $max = shift(@ARGV);

my @clientwords = ('.*dsl.*', 'cable', 'catv', 'ddns', 'dhcp',
    'dial(-?up)?', 'dip', 'docsis', 'dyn(amic)?(ip)?', 'modem', 'ppp(oe)?',
    'res(net|ident(ial)?)?', 'bredband'
    , 'client', 'fixed', 'ip', 'pool', 'static', 'user'  # controversial ones
    );

my $cwordre = '((\b|\d)' . join('(\b|\d))|((\b|\d)', @clientwords) . '(\b|\d))';

my @serverwords = ('e?mail(out)?', 'mta', 'mx(pool)?', 'relay', 'smtp'
                  , 'exch(ange)?'
                  );

my $swordre = '((\b|\d)' . join('(\b|\d))|((\b|\d)', @serverwords) . '(\b|\d))';

my ($word, $i, $temp, $tests);
my ($rdns, $baddns, $client, $soho, $cwords, $swords, $iphost);
$rdns = $baddns = $client = $soho = $cwords = $swords = $iphost = 0;

if (defined($ip)) {
   $ip =~ s/^\[//;
   $ip =~ s/\]$//;
   }
else {
   print "usage: $0 ip-address [maximum]\n";
   exit(1);
   }


unless ($ip =~ /^\d+\.\d+\.\d+\.\d+$/) {
   print "must be a ipv4 ip-address\n";
   exit(1);
   }

my $version = Mail::SpamAssassin::Plugin::Botnet::get_version();

print "Botnet Version = " . $version . "\n";

print "checking IP address: $ip\n";

unless (defined $domain) {
   $domain = "";
   }

if ($domain ne "") {
   print "checking mail domain: $domain\n";
   }

unless ((defined ($max)) && ($max =~ /^\d+$/)) {
   $max = 5;
   }



my $hostname = Mail::SpamAssassin::Plugin::Botnet::get_rdns($ip);

if ($hostname eq "") {
   $rdns = 1;
   print "   BOTNET_NORDNS: hit\n";
   }
else {
   print "   BOTNET_NORDNS: not hit - $hostname\n";
   }

if ( ($hostname ne "") &&
   (Mail::SpamAssassin::Plugin::Botnet::check_dns($hostname, $ip, "A", "-1"))) {
   print "   BOTNET_BADDNS: not hit - hostname resolves back to ip\n";
   }
elsif ($hostname ne "") {
   print "   BOTNET_BADDNS: hit - hostname doesn't resolve back to ip\n";
   $baddns = 1;
   }
else {
   print "   BOTNET_BADDNS: not hit\n";
   }


#print "   BOTNET_CLIENT:\n";
if (Mail::SpamAssassin::Plugin::Botnet::check_ipinhostname($hostname, $ip)) {
   print "      BOTNET_IPINHOSTNAME: hit\n";
   $iphost = 1;
   }
else {
   print "      BOTNET_IPINHOSTNAME: not hit\n";
   }

#print "      BOTNET_CLIENTWORDS:\n";
$i = 0; $tests = "";
foreach $word (@clientwords) {
   $temp = '((\b|\d)' . $word . '(\b|\d))';
   if (Mail::SpamAssassin::Plugin::Botnet::check_words($hostname, $temp)) {
      #print "         hostname matched $word\n";
      $tests .= $word . " ";
      $i++;
      }
   }

$tests =~ s/ $//;

if ($i) {
   print "      BOTNET_CLIENTWORDS: hit, matches=$tests\n";
   $cwords = 1;
   }
else {
   print "      BOTNET_CLIENTWORDS: not hit\n";
   }

#print "      BOTNET_SERVERWORDS:\n";
$i = 0; $tests = "";
foreach $word (@serverwords) {
   $temp = '((\b|\d)' . $word . '(\b|\d))';
   if (Mail::SpamAssassin::Plugin::Botnet::check_words($hostname, $temp)) {
      #print "         hostname matched $word\n";
      $tests .= $word . " ";
      $i++;
      }
   }

$tests =~ s/ $//;

if ($i) {
   print "      BOTNET_SERVERWORDS: hit, matches=$tests\n";
   $swords = 1;
   }
else {
   print "      BOTNET_SERVERWORDS: not hit\n";
   }

if ((! $swords) && ($cwords || $iphost)) {
   $client = 1;
   print "   BOTNET_CLIENT (meta) hit\n";
   }
elsif ($swords && ($cwords || $iphost)) {
   print "   BOTNET_CLIENT (meta) not hit, BOTNET_SERVERWORDS exemption\n";
   }
else {
   print "   BOTNET_CLIENT (meta) not hit\n";
   }

$tests = "";
if (Mail::SpamAssassin::Plugin::Botnet::check_client($hostname, $ip, $cwordre,
                                                     $swordre, \$tests)) {
   $tests = "none" if ($tests eq "");
   print "   BOTNET_CLIENT (code) hit, tests=$tests\n";
   }
else {
   $tests = "none" if ($tests eq "");
   print "   BOTNET_CLIENT (code) not hit, tests=$tests\n";
   }

if (($domain ne "") && ($hostname ne $domain)) {
   if (Mail::SpamAssassin::Plugin::Botnet::check_soho($hostname, $ip,
                                                      $domain, "")) {
      $soho = 1;
      print "   BOTNET_SOHO: hit\n";
      }
   else {
      print "   BOTNET_SOHO: not hit\n";
      }
   }
elsif ($domain ne "") {
   print "   BOTNET_SOHO: skipped (hostname eq mail domain)\n";
   }
else {
   print "   BOTNET_SOHO: skipped (no mail domain given)\n";
   }

if ((! $soho) && ($rdns || $baddns || $client)) {
   print "BOTNET (meta) hit\n";
   }
else {
   print "BOTNET (meta) not hit\n";
   }

$tests = "";
if (Mail::SpamAssassin::Plugin::Botnet::check_botnet($hostname, $ip, $cwordre,
                                          $swordre, $domain, $helo, \$tests)) {
   $tests = "none" if ($tests eq "");
   print "BOTNET (code) hit, tests=$tests\n";
   }
else {
   $tests = "none" if ($tests eq "");
   print "BOTNET (code) not hit, tests=$tests\n";
   }
