#!/usr/bin/perl

# Combine 2 image into one and add a filenames label to all images in a dir.
# Could probably swizzle imagemagic into looping on all files (e.g. mogrify), but this seems easier

use strict;

my $dir1 = 'c:/Users/bruce/Documents/inaturalist/photos_large/1';
my $dir2 = 'c:/Users/bruce/Documents/inaturalist/photos_large/2';
my $dir3 = 'c:/Users/bruce/Documents/inaturalist/poster_plants';

add_labels($dir1, $dir2, $dir3);

sub add_labels {
    my ($dir1, $dir2, $dir3) = @_;
    mkdir($dir3, 0777);
    print "Adding labels $dir1 $dir2 -> $dir3\n";
    opendir(my $dh, $dir1) || die;
    my $count = 0;
    for my $f1 ( sort {$a cmp $b} readdir $dh ) {
	next if $f1 =~ /^\./;
#	my $label = join " ", map {ucfirst} split " ", $f1;
	my $label = $f1;
	$label =~ s/\.jpg//;
	$label =~ s/\b(\w)/\U$1/g;  # Uppercase first char for each word
	$label =~ s/  +/  -  /;     # Add species / name seperator
#	my ($label1, $label2) = $label =~ /(.+)  +(.+)/;  
	$count++;
#	next if $count < 5;
#	last if $count > 7;
	print "c=$count f1=$f1\n";
	#	my $cmd = "'c:\Program Files/ImageMagick-7.0.10-Q16-HDRI/magick'";
	# -style Italic -weight Bold
	# -font Arial-Bold-Italic
	my $cmd = qq|magick convert -background grey -gravity center "$dir1/$f1" "$dir2/$f1"  +append -pointsize 50 -weight Bold label:"$label" -append -bordercolor none -border 10 "$dir3/$f1"|;
	print "$cmd\n";
	system $cmd;
    }
}

# Follow with something like this:
#   magick montage * -tile 12x12 -geometry 400x549+0+0 ../poster_plant1.png
