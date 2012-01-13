#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use Math::Trig;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

my %d;
my %actives;  # not-yet-paired nodes
my %edges;
my %vertices;
my $newnode = 0;  # labels of interior nodes

my %iso;
my %colorbyfam;
my %colorbylang;

open(COLORS, "<:utf8", "colors.txt") or die "Could not open colors.txt: $!";
while (<COLORS>) {
	chomp;
	(my $familyname, my $c) = /^([^ ]+) ([^ ]+)$/;
	$colorbyfam{$familyname} = $c;
}
close COLORS;

open(LANGS, "<:utf8", "langs.txt") or die "Could not open langs.txt: $!";
while (<LANGS>) {
	chomp;
	(my $langcode, my $isocode, my $familyname) = /^([^ ]+) ([^ ]+) ([^ ]+)$/;
	$colorbylang{$langcode} = $colorbyfam{$familyname};
	$iso{$langcode} = $isocode;
}
close LANGS;

# come into this with a d; compute Q, find min pair, add node, recompute d's
# keys of %actives are the as-yet unpaired nodes == labels on rows/cols of Q
sub compute_Q {
	my $minQ = 1000000;
	my $minL;
	my $minR;
	my $r = scalar keys %actives;
	my %colsum;  # $colsum{i} = sum_k d(i,k) 
	for my $i (keys %actives) {
		my $tot = 0;
		for my $k (keys %actives) {
			$tot += $d{"$i|$k"};
		}
		$colsum{$i} = $tot;
	}
	for my $i (keys %actives) {
		for my $j (keys %actives) {
			if ($i lt $j) {
				my $Qvalue = ($r-2)*$d{"$i|$j"} - $colsum{$i} - $colsum{$j};
				if ($Qvalue < $minQ) {
					$minQ = $Qvalue;
					$minL = $i;
					$minR = $j;
				}
			}
		}
	}

	# create new node with label $newnode; remove its two children
	$actives{$newnode} = 1;
	$vertices{$newnode}++;
	delete($actives{$minL});
	delete($actives{$minR});
	print STDERR "New node $newnode joins $minL and $minR...\n";

	# compute distance between new node and the two it joins
	if ($r == 2) {
		$d{"$minL|$newnode"} = 0.5*$d{"$minL|$minR"};  # formula below reduces to this if 0/0 = 0
	}
	else {
		$d{"$minL|$newnode"} = 0.5*($d{"$minL|$minR"} + ($colsum{$minL} - $colsum{$minR})/($r - 2));
	}
	$d{"$newnode|$minL"} = $d{"$minL|$newnode"};
	$d{"$minR|$newnode"} = $d{"$minL|$minR"} - $d{"$minL|$newnode"};
	$d{"$newnode|$minR"} = $d{"$minR|$newnode"}; 
	$edges{"$newnode|$minL"} = $d{"$minL|$newnode"}; 
	$edges{"$newnode|$minR"} = $d{"$minR|$newnode"}; 

	# compute distance between new node and all the others
	for my $n (keys %actives) {
		$d{"$newnode|$n"} = 0.5*($d{"$minL|$n"} + $d{"$minR|$n"} - $d{"$minR|$minL"});
		$d{"$n|$newnode"} = $d{"$newnode|$n"};
	}
	$newnode++;
	return ($r > 2);
}

my $first;
chomp($first = <STDIN>);
$first =~ s/^[^,]*,//;
my @langlist;
for my $l (split(/,/,$first)) {
	push @langlist, $l;
	$vertices{$l}++;
}

while (<STDIN>) {
	chomp;
	(my $lang, my $cosines) = m/^([^,]+)(,.+)$/;
	$actives{$lang} = 1;
	for my $other (@langlist) {
		$cosines =~ s/^,([^,]+)//;
		my $val = $1;
		my $thedist = 0;
		unless ($val eq '-') {
			$thedist = acos($val);  # true distance in high dim S^n
		}
		$d{"$lang|$other"} = $thedist;
		$d{"$other|$lang"} = $thedist;
	}
}

while (compute_Q()) {
	1;
}

#my $url = 'http://www.ethnologue.com/show_language.asp?code=';
my $url = 'http://www.sil.org/iso639-3/documentation.asp?id=';

print "digraph G {\n";
print "    edge [arrowhead=none];\n";
for my $v (keys %vertices) {
	if ($v =~ /^[0-9]+$/) {
		print "   \"$v\" [shape=point];\n"
	}
	else {
		my $c = $colorbylang{$v};
		my $iso = $iso{$v};
		print "   \"$v\" [shape=box, width=0.1, height=0.1, style=filled, color=$c, label=\"$v\", URL=\"$url$iso\", target=\"_blank\"];\n"
	}
}
for my $e (keys %edges) {
	my $toprint = $e;
	$toprint =~ s/^([^|]+)\|(.+)$/"$1" -> "$2"/g;
	my $len = $edges{$e};
	if ($len < 0.001) {  # for perspective, acos(0.99) = 0.14153
		$len = 0.001;
	}
	$len = sprintf("%.3f", 20*$len);
	print "   $toprint [len=$len];\n"
	#print "   $toprint [label=$len, len=$len];\n"
}
print "}\n";

exit 0;
