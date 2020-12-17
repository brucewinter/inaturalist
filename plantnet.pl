#!/usr/bin/perl

# Parse a plantnet.org cvs export and create and html based report

use strict;
$|++;

my $in    = 'c:/Users/bruce/Downloads/my-observations.csv';
my $out1  = 'c:/Users/bruce/Documents/inaturalist/plantnet1.html';
my $out2  = 'c:/Users/bruce/Documents/inaturalist/plantnet2.html';
my $out3  = 'c:/Users/bruce/Documents/inaturalist/plantnet3.html';
my $out4  = 'c:/Users/bruce/Documents/inaturalist/plantnet1.txt';
my $out1c = 'h:/temp';

my @skip = qw( 1003553857 1003531226 1003608257 1003537001 1003530364 1003530360 1003531023 1003564387 1003531295 1003570822 1003570716  1003582559 );
my %skip = map { $_ => 1 } @skip;

# Mimosa quadrivalvis


open (IN,  '<', $in);
open (OUT1, '>', $out1);
open (OUT2, '>', $out2);
open (OUT3, '>', $out3);
open (OUT4, '>', $out4);

my (%p, $id, %toc, %hlist, $count, %id_by_name);
while (my $r = <IN>) {
    chomp $r;
    $r =~ s/\"//g;
    my @d = split ',', $r;
    if (@d > 2) {
	$id = $d[0];
	next if $id eq 'id';
	my $name = $d[6];
	my $date1 = "$d[2] $d[3]";
	my $date2 = $d[4];
	$p{$id}{name} = $name;
	$p{$id}{date1} = $date1;
	$p{$id}{date2} = $date2;
	push @{$p{$id}{url}}, $d[14];
#	print "db1 id=$id n=$d[6] u=$d[14]\n";
    }
    else {
	push @{$p{$id}{url}}, $d[0];
#	print "db2 id=$id n=$d[6] u=$d[0]\n";
    }
}

#or my $id (sort {$p{$a}{name} cmp $p{$b}{name}} keys %p) {
for my $id (sort {$p{$b}{date2} <=> $p{$a}{date2}} keys %p) {
    next if $skip{$id};
    my @urls = @{$p{$id}{url}};
    my $n1 = $p{$id}{name};
    next if $id_by_name{$n1};   # Keep only lastest
    $id_by_name{$n1} = $id;
    $count = $count + 1;
  
    my $n2 = $n1;  $n2 =~ s/ /\%20/g;
    my $n3 = $n1;  $n3 =~ s/ /_/g; $n3 =~ s/(\S+?_\S+?)_.+/$1/;
    my $n4 = $n3;  $n4 =~ s/_/%20/g;
    my $links = "<a href=https://identify.plantnet.org/species/the-plant-list/$n2>Plantnet</a>  ";
    $links   .= "<a href=https://en.wikipedia.org/wiki/$n3>Wikipedia</a>  ";
    $links   .= "<a href=https://www.inaturalist.org/taxa/search?q=$n4>iNaturalist</a>  ";
    $links   .= "<a href=http://coastalplainplants.org/wiki/index.php/$n3>CostalPlants</a>  ";
    
    
    my $w = `curl -sS "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro&redirects=1&titles=$n3"`;
    $w = '' unless $w =~ /\"extract\":/;  # A few plants do not have wiki articles
    $w =~ s/.+\"extract\":\"//;
    $w =~ s/\\n//g;
    $w =~ s/\"\}.+//;

    my ($n5, $n6);
    while ($w =~ /\<b>(.+?)\<\/b>/g) {
	$n5 .= ucfirst "$1, ";
    }
    $n5 =~ s/.+?, //;  # Drop formal name
    $n6 = $n5;
    $n6 =~ s/, .+//;
    $n6 = $n1 unless $n6;
    $n5 = ": $n5";

    my $html1 = "<hr>\n";
    $html1 .= "<h2 id=$id>$p{$id}{date1}: $links</h2>\n";
#   print "db3 n4=$n5 w=$w\n";
    for my $url (@urls) {
	$url =~ s/ .+//;
	$html1 .= "<img width=500 src=$url>\n";
    }
    $html1 .= "<h2><i>$n1</i>  $n5  </h2>$w\n";

    my $html2 = qq|<div class="container">\n  <a href=https://identify.plantnet.org/species/the-plant-list/$n2><img width=200 src="$urls[0]"/></a>\n  <div class="top-center">$n6</div>\n</div>\n|;

    $hlist{$id}{f1} = $html1;
    $hlist{$id}{f2} = $html2;

    $toc{$id}{date} = $p{$id}{date2};
    $toc{$id}{n1}   = $n1;
    $toc{$id}{n4}   = $n5;
    print "db4 id=$id n1=$n1 n2=$n2 n3=$n3 n4=$n5 urls=@urls\n";
#   print "db5 h=$html1\n";
}

my $hlist1;
for my $id (sort {$toc{$b}{date} <=> $toc{$a}{date}} keys %toc) {
#   print "db1 d=$toc{$id}{date} n=$toc{$id}{n4} id=$id\n";
    $hlist1 .= "$hlist{$id}{f1}\n";
}

my ($toc, $hlist2, $hlist3);
for my $id (sort {$toc{$a}{n1} cmp $toc{$b}{n1}} keys %toc) {
#   print "db2 d=$toc{$id}{date} n=$toc{$id}{n1} id=$id\n";
    $toc .= "<li><a href=#$id>$toc{$id}{n1}</a>  $toc{$id}{n4}</li>\n";
    $hlist2 .= "$hlist{$id}{f1}\n";
    $hlist3 .= "$hlist{$id}{f2}\n";
    my ($n1b) = $toc{$id}{n1} =~ /^(\S+ \S+)/;   # first 2 fields, to match with inaturalist
    print OUT4 "$n1b, $toc{$id}{n4}\n";
}

print "Report generated for $count plants";

my $html1 = <<'eof';
<!DOCTYPE html>
<html>
<head>
<style>
  .container {
      position: relative;
      display: inline-block;
      text-align: center;
      color: white;
  }
  .top-left {
      position: absolute;
      top: 8px;
      left: 16px;
      background-color: #ffffff;
  }
  .top-center {
      position: absolute;
      top: 8px;
      left: 50%;
      transform: translate(-50%);
      background-color: black;
  }
}
</style>
</head>
eof

print OUT1 <<eof;
$html1
<body>
<h1>Starcross Plants sorted by date</h1>
$hlist1;
<ul>
$toc
</ul>
</body>
eof
    
print OUT2 <<eof;
$html1
<body>
<h1>Starcross Plants sorted by name</h1>
$hlist2;
<ul>
$toc
</ul>
</body>
eof
    
print OUT3 <<eof;
$html1
<body>
<h1>Starcross Plants sorted by name</h1>
$hlist3;
</body>
eof

close(OUT1);
close(OUT2);
close(OUT3);
close(OUT4);

use File::Copy qw(copy);
copy $out1, $out1c;

    
#"id","URL","date observed","date observed (timestamp milliseconds)","project","current name","original name","family","valid","license","latitude","longitude","locality","images"
#"1003857331","https://identify.plantnet.org/observation/1003857331","May 19, 2019","1558262555000","the-plant-list","Liriope muscari (Decne.) L.H.Bailey","Liriope muscari (Decne.) L.H.Bailey","Asparagaceae","true","cc-by-sa","33.437661111111105","-86.77957611111111","","https://bs.floristic.org/image/o/8532a4ba550af486b9da34876ae632011efc1b82 (flower)
#https://bs.floristic.org/image/o/cc1a513a2ebb39e1f7f95b19dab76f078ad089d5 (leaf)
#https://bs.floristic.org/image/o/04c1abdb40b00fb1d6d07e7b7a5cf034ee39485e (habit)",
#"1003833615","https://identify.plantnet.org/observation/1003833615","May 17, 2019","1558096982000","namerica","Rudbeckia hirta L.","Rudbeckia hirta L.","Asteraceae","true","cc-by-sa","33.43763","-86.77998083333333","","https://bs.floristic.org/image/o/b874153a486ec180d0955e2c70e0e002949923b7 (flower)


#  https://en.wikipedia.org/w/api.php?format=html&action=query&prop=revisions&titles=Hollywood&rvprop=content&rvsection=0&rvparse
#  https://en.wikipedia.org/w/api.php?format=json&action=query&prop=extracts&exintro&redirects=1&titles=Arisaema_triphyllum    

# "extract":"<p class=\"mw-empty-elt\">\n</p>\n<p><i><b>Liriope muscari</b></i> is a species of low, herbaceous flowering plants from East Asia. Common names in English include <b>big blue lilyturf</b>, <b>lilyturf</b>, <b>border grass</b>, and <b>monkey grass</b>. It is a perennial with grass-like evergreen foliage and lilac-purple flowers which produce single-seeded berries on a spike in the fall.\n</p>"}}}}
