use strict;
use warnings;
use feature 'say';
use DBI;
use Tree::Binary2;
use SVG;
use Getopt::Long;


#
# Draw_cell_lineage_tree.pl
# Reqirements: Perl5
# Author: Xiao-Tai Huang
# Email: xthuang226@gmail.com
# Version: 2.0
# Date: 2017/12/05
#


my $file        = "Draw_cell_lineage_tree.pl";
my $program     = uc($&) if $file =~ /^\w+/;
my $version     = "2.0";
my $date        = "2017/12/05";
my $author      = "Xiao-Tai Huang";



### program identification
my $title = "$program $version, $date $author\n";



### option variables
my @bool = ("false", "true");
$::opt_help          = 0;
$::opt_root          = 'P0';
$::opt_endtime       = 140;
$::opt_cellstage     = 0;
$::opt_cutoff        = 1466.8;
$::opt_lefontsize    = 20;
$::opt_lafontsize    = 15;
$::opt_blafontsize   = 10;
$::opt_axfontsize    = 20;
$::opt_brfontsize    = 30;
$::opt_titlefontsize = 20;
$::opt_scale         = 5;
$::opt_lineinter     = 15;
$::opt_linewidth     = 5;
$::opt_width         = 0;
$::opt_height        = 0;
$::opt_model         = 0;
$::opt_binary        = 0;
$::opt_label         = 0;
$::opt_bottomlabel   = 0;
$::opt_titlelabel    = 1;
$::opt_axis          = 0;
$::opt_brand         = 0;
$::opt_autozoom      = 0;
$::opt_mixtree    = 1;
$::opt_indb          = 'data/cdfiles.db3';
$::opt_output        = 'results/';



my $usage = <<"END_OF_USAGE";
${title}Syntax:   \L$program\E <table> [options]
Function: Draw cell lineage tree into .svg format.
Options:                                                               (defaults:)
  -h, --help         print usage
  -r, --root         root of the tree                                  ($::opt_root)
  --endtime          endtime of the tree                               ($::opt_endtime)
  --cellstage        cell stage of the tree                            ($::opt_cellstage)
  --cutoff           set cutoff for binarizing gene expression         ($::opt_cutoff)
  --lefontsize       set top leader cell font size                     ($::opt_lefontsize)
  --lafontsize       set cell label font size                          ($::opt_lafontsize)
  --blafontsize      set bottom cell label font size                   ($::opt_blafontsize)
  --axfontsize       set axis font size                                ($::opt_axfontsize)
  --brfontsize       set brand font size                               ($::opt_brfontsize)
  --titlefontsize    set title font size                               ($::opt_titlefontsize)
  --scale            control vertical line scale                       ($::opt_scale)
  --lineinter        set gap between two vertical lines                ($::opt_lineinter)
  --linewidth        set vertical line width                           ($::opt_linewidth)
  -w, --width        set graph width                                   ($::opt_width)
  -h, --height       set graph height                                  ($::opt_height)
  -i, --indb         set input SQLite database .db3 file               ($::opt_indb)
  -o, --output       set output tree graph folder path                 ($::opt_output)
  -m, --model        draw model tree                                   ($bool[$::opt_model])
  -b, --binary       draw tree with binary gene expression value       ($bool[$::opt_binary])
  --label            draw label for each cell                          ($bool[$::opt_label])
  --bottomlabel      draw label for bottom cells of the tree           ($bool[$::opt_bottomlabel])
  --titlelabel       draw title on the lefttop coner of the graph      ($bool[$::opt_titlelabel])
  --axis             draw axis for the tree                            ($bool[$::opt_axis])
  --brand            draw brand for the tree                           ($bool[$::opt_brand])
  --autozoom         autozoom graph with window size                   ($bool[$::opt_autozoom])
  --mixtree       draw merged tree with multiple marker expressions ($bool[$::opt_mixtree])
Examples:
  \L$program\E CD130826PHA4p2
  \L$program\E CD130826PHA4p2 --root ABara --cellstage 350 --autozoom
  \L$program\E CD130826PHA4p2 --root P0 --cellstage 350 -b --axis --brand --label --bottomlabel
  \L$program\E CD130826PHA4p2 --root P0 --endtime 140 -m --axis --brand --label --bottomlabel
  \L$program\E CD130826PHA4p2 CD140102NHR25p2 --root P0 --cellstage 400 --axis --brand --label --bottomlabel --mixtree
END_OF_USAGE



### process options
GetOptions(
  "help|h!",
  "root|r=s",
  "endtime=f",
  "cellstage=i",
  "cutoff=f",
  "lefontsize=f",
  "lafontsize=f",
  "blafontsize=f",
  "axfontsize=f",
  "brfontsize=f",
  "titlefontsize=f",
  "scale=f",
  "lineinter=f",
  "linewidth=f",
  "width|w=f",
  "height|h=f",
  "model|m!",
  "binary|b!",
  "label!",
  "bottomlabel!",
  "titlelabel!",
  "axis!",
  "brand!",
  "autozoom!",
  "mixtree!",
  "indb=s",
  "output=s"
) or die $usage;
!$::opt_help or die $usage;



### Set parameters
my $origin = 'P0';
my @tables = @ARGV;
my ($root, $endtime, $cellstage, $indb, $output) = ($::opt_root, $::opt_endtime, $::opt_cellstage, $::opt_indb, $::opt_output);
die $usage unless defined $tables[0];
my ($binary, $model, $cutoff, $autozoom, $mixtree) = ($::opt_binary, $::opt_model, $::opt_cutoff, $::opt_autozoom, $::opt_mixtree);
my ($label, $bottom_label, $axis, $brand, $titlelabel) = ($::opt_label, $::opt_bottomlabel, $::opt_axis, $::opt_brand, $::opt_titlelabel);
my ($width, $height, $linewidth, $lineinter, $scale) = ($::opt_width, $::opt_height, $::opt_linewidth, $::opt_lineinter, $::opt_scale);
my ($lefontsize, $lafontsize, $blafontsize, $axfontsize, $brfontsize, $titlefontsize) = ($::opt_lefontsize, $::opt_lafontsize, $::opt_blafontsize, $::opt_axfontsize, $::opt_brfontsize, $::opt_titlefontsize);


### Set drawing ways
$model = 0 if $mixtree == 1;
$binary = 1 if $model == 1;
$mixtree = 0 if $binary == 1;
if ($autozoom == 1) {
	$label = 0;
	$bottom_label = 0;
	$axis = 0;
	$brand = 0;
}


my ($marginleft, $marginright, $margintop, $marginbottom) = (20, 20, 20, 40);

my $axis_width = 0;
$axis_width =  120 if $axis == 1;
my $brand_width = 0;
$brand_width = 100 if $brand == 1;
my $rootheight = 20;
my $botlabheight = 0;
$botlabheight = 70 if $bottom_label == 1;

my $spaceleft = $marginleft + $axis_width;
my $spaceright = $marginright + $brand_width;
my $spacetop = $margintop + $rootheight;
my $spacebottom = $marginbottom + $botlabheight;

die 'Please set $linewidth !' if $linewidth == 0;
die 'Please set $lineinter or $width' if ($lineinter == 0 && $width == 0);
die 'Please set $scale or $height' if ($scale == 0 && $height == 0);



## Connect to DBMS
my $conn = DBI->connect("dbi:SQLite:dbname=$indb","","",{ RaiseError => 1 }) or die $DBI::errstr;

my (@leafnumb_ALL, @treehash_ALL, @cell_exp_ary_ALL, @cell_exp_avg_ALL, @cell_length_ALL, @add_cells_ALL);

my $i = 0;
foreach (@tables) {
	say "\n$_";
	my ($endtime_c, $leafnumb, $treehash, $cell_exp_ary, $cell_exp_avg, $cell_length, $add_cells) = &get_data_to_be_drew ($tables[$i], $endtime, $cellstage, $model, $origin);

	push @leafnumb_ALL, $leafnumb;
	push @treehash_ALL, $treehash;
	push @cell_exp_ary_ALL, $cell_exp_ary;
	push @cell_exp_avg_ALL, $cell_exp_avg;
	push @cell_length_ALL, $cell_length;
	push @add_cells_ALL, $add_cells;

	map{say "Invalid data in $tables[$i] in cell: $_"}@$add_cells;
	say "\n";

	$endtime = $endtime_c if $i == 0;

	$i++;
}

unless (defined $cell_length_ALL[0]->{$root}) {
	die "\n[Warning: $root is invalid! Please input valid root name.]\n\n";
}



### Get sub tree info
my ($root_start_tp, $sub_tp, $sub_leafnumb) = &sub_tree_info($root, $treehash_ALL[0], $cell_length_ALL[0], $model, $add_cells_ALL[0], $endtime);



### Compute $scale, $height, $lineinter, $width if no input for them
if ($height != 0) {
	$scale = ($height-$spacetop-$spacebottom) / $sub_tp;
}else{
	$height = $spacetop+$spacebottom+$scale*$sub_tp;
}

if ($width != 0) {
	### Reset $linewidth, $lineinter based on $width
	$linewidth *= 2;
	my $linewidth_tmp = (1/3) * (($width-$spaceleft-$spaceright) / ($sub_leafnumb - 1));
	$linewidth = $linewidth_tmp if $linewidth_tmp < $linewidth;
	$lineinter = ($width-$spaceleft-$spaceright) / ($sub_leafnumb - 1) - $linewidth;
}else{
	$width = $spaceleft+$spaceright+($sub_leafnumb-1)*($lineinter+$linewidth)+(scalar @tables - 0.5)*$linewidth;
	$width = $spaceleft+$spaceright+($sub_leafnumb-1)*($lineinter+$linewidth)+0.5*$linewidth if $mixtree==1;
}

my $scale_ra = $scale / $height * 100;
my $lineinter_ra = $lineinter / $width * 100;
my $linewidth_ra = $linewidth / $width * 100;



### Compute cells x positions
my $cellx = &fix_xaxis_position($treehash_ALL[0], $root, $spaceleft, $linewidth_ra, $lineinter_ra, $width);



### Output file
my $output_tmp = $output;
my $output_whole;

while ($output_tmp =~ s/^([\.\/]*[^\.\/]+\/?)//) {
	$output_whole .= $&;
	mkdir $output_whole;
}

my $outfilename = join('_', @tables);
my $outpath = "$output/$outfilename\_$root\_tp$endtime\_c$leafnumb_ALL[0].svg";



### Set colors
my @linecolors_set = split(/\|/, "rgb(200, 0, 0)|rgb(0, 200, 0)|rgb(33, 148, 35)");
my @labelcolors_set = split(/\|/, "rgb(160, 160, 160)|black");



### Draw tree
&draw_tree ($root, \@treehash_ALL, \@cell_length_ALL, $cellx, \@cell_exp_avg_ALL, \@cell_exp_ary_ALL, $scale_ra, $linewidth_ra, $sub_tp, $model, $binary, $cutoff, $label, $bottom_label, $linewidth, $spacetop, $spacebottom, $spaceleft, $spaceright, $lefontsize, $lafontsize, $blafontsize, $axfontsize, $brfontsize, $titlefontsize, $autozoom, $mixtree, $width, $height, $root_start_tp, $marginleft, $endtime, $titlelabel, $axis, $brand, \@linecolors_set, \@labelcolors_set);



### Disconnect DBMS
$conn->disconnect();
$conn = undef;
















sub get_data_to_be_drew {
	my ($table, $endtime, $cellstage, $model, $origin) = @_;

	my ($add_cells, $leafnumb, $treehash, $cell_exp_ary, $cell_exp_avg, $cell_length);

	if ($cellstage != 0) {
		$endtime = 130 unless defined $endtime;				##### If endtime is undefined, give a default endtime.
		($endtime, $add_cells, $leafnumb, $treehash, $cell_exp_ary, $cell_exp_avg, $cell_length) = &modify_endtime($table, $endtime, $cellstage, $model, $origin);	##### Get endtime with the given cellstage.
	}elsif (defined $endtime) {
		($cell_exp_ary, $cell_exp_avg, $cell_length) = &get_tree_data_by_endtime ($table, $endtime, $model);

		($add_cells, $cell_exp_ary, $cell_exp_avg, $cell_length) = &supplement_tree_data ($cell_exp_ary, $cell_exp_avg, $cell_length, $model);

		$treehash = &insert_treehash(keys %$cell_exp_avg);
		$leafnumb = &compute_cellstage($treehash, $origin);
		say "=> timepoint:$endtime\tcellstage:$leafnumb";
	}else{
		die 'Please give a specific $endtime or $cellstage !';
	}

	return ($endtime, $leafnumb, $treehash, $cell_exp_ary, $cell_exp_avg, $cell_length, $add_cells);
}


sub modify_endtime {
	my ($table, $endtime, $cellstage, $model, $origin) = @_;

	my ($cell_exp_ary, $cell_exp_avg, $cell_length) = &get_tree_data_by_endtime ($table, $endtime, $model);
	(my $add_cells, $cell_exp_ary, $cell_exp_avg, $cell_length) = &supplement_tree_data ($cell_exp_ary, $cell_exp_avg, $cell_length, $model);
	my $treehash = &insert_treehash(keys %$cell_exp_avg);
	my $leafnumb = &compute_cellstage($treehash, $origin);
	say "timepoint:$endtime\tcellstage:$leafnumb";

	my %record;

	while ($leafnumb != $cellstage){

		$record{$endtime} = abs($leafnumb-$cellstage);

		if ($leafnumb > $cellstage){
			$endtime--;
		}elsif($leafnumb < $cellstage){
			$endtime++;
		}

		if (defined $record{$endtime}) {
			my @record = sort {$record{$a} <=> $record{$b}} keys %record;
			$endtime = $record[0];
			($cell_exp_ary, $cell_exp_avg, $cell_length) = &get_tree_data_by_endtime ($table, $endtime, $model);
			($add_cells, $cell_exp_ary, $cell_exp_avg, $cell_length) = &supplement_tree_data ($cell_exp_ary, $cell_exp_avg, $cell_length, $model);
			$treehash = &insert_treehash(keys %$cell_exp_avg);
			$leafnumb = &compute_cellstage($treehash, $origin);
			say "timepoint:$endtime\tcellstage:$leafnumb";
			last;
		}else{
			($cell_exp_ary, $cell_exp_avg, $cell_length) = &get_tree_data_by_endtime ($table, $endtime, $model);
			($add_cells, $cell_exp_ary, $cell_exp_avg, $cell_length) = &supplement_tree_data ($cell_exp_ary, $cell_exp_avg, $cell_length, $model);
			$treehash = &insert_treehash(keys %$cell_exp_avg);
			$leafnumb = &compute_cellstage($treehash, $origin);
			say "timepoint:$endtime\tcellstage:$leafnumb";
		}

	}

	say "=> timepoint:$endtime\tcellstage:$leafnumb";
	return ($endtime, $add_cells, $leafnumb, $treehash, $cell_exp_ary, $cell_exp_avg, $cell_length);
}


sub get_tree_data_by_endtime {
	my ($table, $endtime, $model) = @_;
	my ($cell_exp_ary, $cell_exp_avg, $cell_length);

	my $sql = "SELECT * FROM $table WHERE time <= $endtime";
	my $query = $conn->prepare($sql);
	$query->execute();

	while ( my @row = $query->fetchrow_array() ) {
		my @exp_ary = split (/,/, $row[3]);
		$$cell_exp_ary{$row[0]} = \@exp_ary;
		$$cell_exp_avg{$row[0]} = $row[4];
		if ($model == 1) {
			$$cell_length{$row[0]} = ($row[5] =~ tr/././) + 1;
		}else{
			$$cell_length{$row[0]} = $row[2];
		}
	}

	undef $query;
	return ($cell_exp_ary, $cell_exp_avg, $cell_length);
}


sub supplement_tree_data {
	my ($cell_exp_ary, $cell_exp_avg, $cell_length, $model) = @_;
	my $add_cells;

	my $cell_level_sup_ref;
	$$cell_level_sup_ref{'P0'} = 1;
	$$cell_level_sup_ref{'AB'} = 2;
	$$cell_level_sup_ref{'P1'} = 2;
	$$cell_level_sup_ref{'ABa'} = 3;
	$$cell_level_sup_ref{'ABp'} = 3;
	$$cell_level_sup_ref{'EMS'} = 3;
	$$cell_level_sup_ref{'P2'} = 3;
	$$cell_level_sup_ref{'ABal'} = 4;
	$$cell_level_sup_ref{'ABar'} = 4;
	$$cell_level_sup_ref{'ABpl'} = 4;
	$$cell_level_sup_ref{'ABpr'} = 4;
	$$cell_level_sup_ref{'MS'} = 4;
	$$cell_level_sup_ref{'E'} = 4;
	$$cell_level_sup_ref{'C'} = 4;
	$$cell_level_sup_ref{'P3'} = 4;
	$$cell_level_sup_ref{'D'} = 5;
	$$cell_level_sup_ref{'P4'} = 5;
	$$cell_level_sup_ref{'Z2'} = 6;
	$$cell_level_sup_ref{'Z3'} = 6;

	# foreach (qw/P0 AB P1 ABa ABp EMS P2 ABal ABar ABpl ABpr MS E C P3 D P4 Z2 Z3/){
	foreach (qw/P0 AB P1 ABa ABp EMS P2/){
		my $add_cell = $_;
		unless (defined $$cell_exp_ary{$add_cell}){
			my @exp_ary = qw/0 0 0 0/;
			$$cell_exp_ary{$add_cell} = \@exp_ary;
			$$cell_exp_avg{$add_cell} = 0;

			if ($model == 1) {
				$$cell_length{$add_cell} = $$cell_level_sup_ref{$add_cell};
			}else{
				$$cell_length{$add_cell} = scalar @exp_ary;
			}

			push @$add_cells, $add_cell;
		}
	}
	return ($add_cells, $cell_exp_ary, $cell_exp_avg, $cell_length);
}


sub insert_treehash {
	my (@cells) = @_;
	my %treehash;

	### Put elements of @cells into a tree.
	foreach (@cells){
		$treehash{$_} = Tree::Binary2->new($_);
	}

	### Connect node to its parent.
	foreach (@cells){
		my $cell = $_;
		
		if ($cell =~ /^(A?B?M?S?E?C?D?.*)([aplrdv])$/){
			my $pres = $1;
			my $ends = $2;
			
			if ($ends =~ /[lad]/){
				$treehash{$pres} = Tree::Binary2->new( $pres ) unless defined $treehash{$pres};
				$treehash{$pres}->left( $treehash{$cell} );
			}
			if ($ends =~ /[rpv]/){
				$treehash{$pres} = Tree::Binary2->new( $pres ) unless defined $treehash{$pres};
				$treehash{$pres}->right( $treehash{$cell} );
			}
		}
		
		if ($cell =~ /^P1$/){
			$treehash{'P0'} = Tree::Binary2->new( 'P0' ) unless defined $treehash{'P0'};
			$treehash{'P0'}->right( $treehash{$cell} );
		}
		if ($cell =~ /^AB$/){
			$treehash{'P0'} = Tree::Binary2->new( 'P0' ) unless defined $treehash{'P0'};
			$treehash{'P0'}->left( $treehash{$cell} );
		}
		if ($cell =~ /^EMS$/){
			$treehash{'P1'} = Tree::Binary2->new( 'P1' ) unless defined $treehash{'P1'};
			$treehash{'P1'}->left( $treehash{$cell} );
		}
		if ($cell =~ /^P2$/){
			$treehash{'P1'} = Tree::Binary2->new( 'P1' ) unless defined $treehash{'P1'};
			$treehash{'P1'}->right( $treehash{$cell} );
		}
		if ($cell =~ /^P3$/){
			$treehash{'P2'} = Tree::Binary2->new( 'P2' ) unless defined $treehash{'P2'};
			$treehash{'P2'}->right( $treehash{$cell} );
		}
		if ($cell =~ /^C$/){
			$treehash{'P2'} = Tree::Binary2->new( 'P2' ) unless defined $treehash{'P2'};
			$treehash{'P2'}->left( $treehash{$cell} );
		}
		if ($cell =~ /^P4$/){
			$treehash{'P3'} = Tree::Binary2->new( 'P3' ) unless defined $treehash{'P3'};
			$treehash{'P3'}->right( $treehash{$cell} );
		}
		if ($cell =~ /^D$/){
			$treehash{'P3'} = Tree::Binary2->new( 'P3' ) unless defined $treehash{'P3'};
			$treehash{'P3'}->left( $treehash{$cell} );
		}
		if ($cell =~ /^Z3$/){
			$treehash{'P4'} = Tree::Binary2->new( 'P4' ) unless defined $treehash{'P4'};
			$treehash{'P4'}->left( $treehash{$cell} );
		}
		if ($cell =~ /^Z2$/){
			$treehash{'P4'} = Tree::Binary2->new( 'P4' ) unless defined $treehash{'P4'};
			$treehash{'P4'}->right( $treehash{$cell} );
		}
		if ($cell =~ /^E$/){
			$treehash{'EMS'} = Tree::Binary2->new( 'EMS' ) unless defined $treehash{'EMS'};
			$treehash{'EMS'}->right( $treehash{$cell} );
		}
		if ($cell =~ /^MS$/){
			$treehash{'EMS'} = Tree::Binary2->new( 'EMS' ) unless defined $treehash{'EMS'};
			$treehash{'EMS'}->left( $treehash{$cell} );
		}
	}
	
	return \%treehash;
}


sub compute_cellstage {
	my ($treehash, $origin) = @_;
	
	my $leafnumb;

	my $check_root = $$treehash{$origin};

	my $trav = $check_root->traverse($check_root->POST_ORDER);
	while ( my $node = $trav->() ) {
		unless ($node -> children){
			$leafnumb++;
		}
	}

	return $leafnumb;
}


sub compute_end_tp_for_cell {
	my ($cell, $treehash, $cell_length) = @_;
	my $tp = $$cell_length{$cell};

	my $parent = $$treehash{$cell} -> parent;
	while ($parent){
		$tp += $$cell_length{$parent->value};
		$parent = $parent -> parent;
	}
	return $tp;
}


sub compute_end_tp_and_leafnumb_for_tree {
	my ($root, $treehash, $cell_length) = @_;
	my $end_tp = 0;
	my $leafnumb = 0;

	my $check_root = $$treehash{$root};
	my $trav = $check_root->traverse($check_root->LEVEL_ORDER);
	while ( my $node = $trav->() ) {
		unless ($node -> children){
			my $tp = &compute_end_tp_for_cell($node->value, $treehash, $cell_length);
			$end_tp = $tp if $tp > $end_tp;
			$leafnumb++;
		}
	}
	return ($end_tp, $leafnumb);
}


sub sub_tree_info {
	my ($root, $treehash, $cell_length, $model, $add_cells, $endtime) = @_;

	my $root_start_tp = &compute_end_tp_for_cell($root, $treehash, $cell_length) - $$cell_length{$root};

	my ($sub_end_tp, $sub_leafnumb) = &compute_end_tp_and_leafnumb_for_tree($root, $treehash, $cell_length);

	my $sub_tp;

	if ($model == 1) {
		$sub_tp = $sub_end_tp - $root_start_tp;
	}else{
		my $sup_tp = 0;
		foreach (@$add_cells) {
			my $tp = &compute_end_tp_for_cell($_, $treehash, $cell_length);
			$sup_tp = $tp if $tp > $sup_tp;
		}
		if ($sup_tp < $endtime) {
			$sub_tp = $endtime + $sup_tp - $root_start_tp;
		}
	}

	return ($root_start_tp, $sub_tp, $sub_leafnumb);
}


sub fix_xaxis_position {
	my ($treehash, $root, $spaceleft, $linewidth_ra, $lineinter_ra, $width) = @_;
	
	my %cellx;
	my $xleaf = $spaceleft / $width * 100;

	my $check_root = $$treehash{$root};
	my $trav = $check_root->traverse($check_root->POST_ORDER);
	while ( my $node = $trav->() ) {
		
		my $cell = $node -> value;

		if (my @children = $node -> children){

			die "The data of cell $cell is not valid!\n" if scalar @children != 2;
			
			my $lx = $cellx{$children[0]->value};
			my $rx = $cellx{$children[1]->value};
			
			$cellx{$cell} = $lx + 0.5*($rx-$lx);
			
		}else{
			$cellx{$cell} = $xleaf;
			$xleaf += $lineinter_ra + $linewidth_ra;
		}
		
	}
	return \%cellx;
}


sub draw_tree {
	my ($root, $treehash_ALL, $cell_length_ALL, $cellx, $cell_exp_avg_ALL, $cell_exp_ary_ALL, $scale_ra, $linewidth_ra, $sub_tp, $model, $binary, $cutoff, $label, $bottom_label, $linewidth, $spacetop, $spacebottom, $spaceleft, $spaceright, $lefontsize, $lafontsize, $blafontsize, $axfontsize, $brfontsize, $titlefontsize, $autozoom, $mixtree, $width, $height, $root_start_tp, $marginleft, $endtime, $titlelabel, $axis, $brand, $linecolors_set, $labelcolors_set) = @_;


	### leader cells
	my %leader_cells;
	foreach (qw/P0 P1 P2 P3 P4 AB ABa ABp EMS E MS C D Z2 Z3/) {
		$leader_cells{$_} = 1;
	}

	undef %leader_cells if $autozoom == 1;
	
	my ($x1,$y1,$x2,$y2) = qw/0 0 0 0/;

	my $celly;
	$$celly{$root} = $spacetop/$height*100;

	my $celly_start_tp;
	$$celly_start_tp{$root} = 0;
	


	my $svg;
	if ($autozoom == 1) {
		$svg = SVG->new();
	}else{
		$svg = SVG->new(width=>$width, height=>$height);
	}

	my $check_root = $$treehash_ALL[0]->{$root};
	my $trav = $check_root->traverse($check_root->LEVEL_ORDER);
	while ( my $node = $trav->() ) {
		my $cell = $node->value;

		$x1 = $$cellx{$cell};
		$y1 = $$celly{$cell};
		$x2 = $x1;
		$y2 = $y1 + ($$cell_length_ALL[0]->{$cell} * $scale_ra);

		if (my @children = $node -> children){

			foreach (@children) {
				$$celly{$_->value} = $y2;
				$$celly_start_tp{$_->value} = $$celly_start_tp{$cell} + $$cell_length_ALL[0]->{$cell};
			}

			### Draw label
			my $x_label = $x1 + (scalar @tables) * $linewidth_ra;
			$x_label = $x1 + $linewidth_ra if $mixtree == 1;
			my $y_label = $y1 + $scale_ra; 

			if (defined $leader_cells{$cell}) {
				if ($cell eq $root) {
					$x_label += -0.15;
					$y_label += -0.5;
				}elsif($cell eq 'E'){
					$x_label += -0.1;
					$y_label += -1;
				}elsif($cell eq 'C'){
					$x_label += -0.1;
					$y_label += -1;
				}elsif($cell eq 'D'){
					$x_label += -0.1;
					$y_label += -1;
				}elsif($cell eq 'ABp'){
					$x_label += 0.1;
					$y_label += 0.6;
				}elsif($cell eq 'EMS'){
					$x_label += -0.5;
					$y_label += 0.6;
				}else{
					$x_label += -0.2;
					$y_label += -1;
				}
				$svg->text(x => "$x_label%", y => "$y_label%", "fill"=>"balck", "font-family"=>"Times New Roman","font-size"=>$lefontsize, "-cdata" => $cell);
			}elsif ($label == 1 && $cell ne $root) {
				my $x_label_px = $width * $x_label / 100;
				my $y_label_px = $height * $y_label / 100;
				$svg->text(x => $x_label_px.'px', y => $y_label_px.'px', fill => $$labelcolors_set[0], transform =>"rotate(90,$x_label_px,$y_label_px)", "font-family"=>"Times New Roman","font-size"=>$lafontsize, "-cdata" => $cell);
			}elsif ($label == 1 && $cell eq $root) {
				$x_label += -2;
				$y_label += -0.5;
				$svg->text(x => "$x_label%", y => "$y_label%", "fill"=>"balck", "font-family"=>"Times New Roman","font-size"=>$lefontsize, "-cdata" => $cell);
			}

		}else{
			$y2 = 100 - $spacebottom/$height*100 if $model == 1 || $y2 > (100 - $spacebottom/$height*100);

			if ($bottom_label == 1) {
				my $x_bottom_label = $x2 - $linewidth_ra;
				my $y_bottom_label = 100 - ($spacebottom - 10)/$height*100;
				my $x_bottom_label_px = $width*$x_bottom_label/100;
				my $y_bottom_label_px = $height*$y_bottom_label/100;
				$svg->text(x => "$x_bottom_label%", y => "$y_bottom_label%", transform =>"rotate(30, $x_bottom_label_px, $y_bottom_label_px)", "font-family"=>"Times New Roman","font-size"=>$blafontsize, "-cdata" => $cell);
			}
		}

		my $linecolor;
		if ($binary == 1) {

			my $i = 0;
			foreach my $tab (@tables) {
				my $cell_exp_avg_value = $$cell_exp_avg_ALL[$i]->{$cell};

				unless (defined $cell_exp_avg_value) {
					my $sql = "
						SELECT avgexp FROM \'$tab\' WHERE cell = \'$cell\';
					";
					my $query = $conn->prepare($sql);
					$query->execute;

					while (my @row = $query->fetchrow_array) {
						$cell_exp_avg_value = $row[0];
					}
					undef $query;
				}

				unless (defined $cell_exp_avg_value) {
					$cell_exp_avg_value = 0;
				}

				if ($cell_exp_avg_value >= $cutoff){
					$linecolor = $$linecolors_set[$i];
				}else{
					$linecolor = 'black';
				}

				my $x1_re = $x1 + $i * $linewidth_ra;
				my $x2_re = $x2 + $i * $linewidth_ra;

				my $draw_method = 0;
				if ($draw_method == 0) {
					### Draw vertical line via line method
					if ($autozoom == 1) {
						$svg->line(x1 => "$x1_re%", y1 => "$y1%", x2 => "$x2_re%", y2 => "$y2%", stroke=>$linecolor,"stroke-width"=>$linewidth_ra.'%');
					}else{
						$svg->line(x1 => "$x1_re%", y1 => "$y1%", x2 => "$x2_re%", y2 => "$y2%", stroke=>$linecolor,"stroke-width"=>$linewidth.'px');
					}
				}else{
					for (1..$$cell_length_ALL[0]->{$cell}) {
						my $cur_tp = $_;
						if (($$celly_start_tp{$cell}+$cur_tp) <= $sub_tp) {
							if ($autozoom == 1) {
								$svg->line(x1 => "$x1%", y1 => "$y1%", x2 => "$x2%", y2 => ($y1+$scale_ra)."%", stroke=>$linecolor,"stroke-width"=>$linewidth_ra.'%');
							}else{
								$svg->line(x1 => "$x1%", y1 => "$y1%", x2 => "$x2%", y2 => ($y1+$scale_ra)."%", stroke=>$linecolor,"stroke-width"=>$linewidth.'px');
							}
							$y1 += $scale_ra;
						}
					}
				}

				$i++;
			}

		}else{

			### Draw vertical line via point method

			if (scalar @tables > 1 && $mixtree == 1) {

				my @linecolor_R;
				my @linecolor_G;
				my @linecolor_B;


				my $i = 0;
				foreach my $tab (@tables) {

					my $exps = $$cell_exp_ary_ALL[$i]->{$cell};
					unless (defined $exps) {
						my $sql = "
							SELECT exp FROM \'$tab\' WHERE cell = \'$cell\';
						";
						my $query = $conn->prepare($sql);
						$query->execute;

						while (my @row = $query->fetchrow_array) {
							@$exps = split(',', $row[0]);
						}
						undef $query;
					}

					my $exps_tmp = 0;

					for (1..$$cell_length_ALL[0]->{$cell}) {
						my $cur_tp = $_;
						if (($$celly_start_tp{$cell}+$cur_tp) <= $sub_tp) {

							my $linecolors = &get_linecolors($$linecolors_set[$i],10);

							$exps_tmp = $$exps[$cur_tp-1] if defined $$exps[$cur_tp-1];

							$linecolor = &set_linecolor($exps_tmp,$linecolors);

							if ($linecolor =~ /^rgb\((\d+),(\d+),(\d+)\)$/) {
								# $linecolor_R[$cur_tp-1] += $1;			### take average of RGB
								# $linecolor_G[$cur_tp-1] += $2;
								# $linecolor_B[$cur_tp-1] += $3;

								if (defined $linecolor_R[$cur_tp-1]) {
									$linecolor_R[$cur_tp-1] = abs($linecolor_R[$cur_tp-1] - $1);
								}else{
									$linecolor_R[$cur_tp-1] = $1;
								}

								if (defined $linecolor_G[$cur_tp-1]) {
									$linecolor_G[$cur_tp-1] = abs($linecolor_G[$cur_tp-1] - $2);
								}else{
									$linecolor_G[$cur_tp-1] = $2;
								}

								if (defined $linecolor_B[$cur_tp-1]) {
									$linecolor_B[$cur_tp-1] = abs($linecolor_B[$cur_tp-1] - $3);
								}else{
									$linecolor_B[$cur_tp-1] = $3;
								}

							}else{
								die "Error in RGB color setting!";
							}

						}
					}

					$i++;
				}

				# for (1..scalar @linecolor_R) {					### take average of RGB
				# 	$linecolor_R[$_-1] /= scalar @tables;
				# 	$linecolor_G[$_-1] /= scalar @tables;
				# 	$linecolor_B[$_-1] /= scalar @tables;
				# }

				for (1..$$cell_length_ALL[0]->{$cell}) {
					my $cur_tp = $_;
					if (($$celly_start_tp{$cell}+$cur_tp) <= $sub_tp) {

						$linecolor = "rgb(".$linecolor_R[$cur_tp-1].",".$linecolor_G[$cur_tp-1].",".$linecolor_B[$cur_tp-1].")";

						if ($autozoom == 1) {
							$svg->line(x1 => "$x1%", y1 => "$y1%", x2 => "$x2%", y2 => ($y1+$scale_ra)."%", stroke=>$linecolor,"stroke-width"=>$linewidth_ra.'%');
						}else{
							$svg->line(x1 => "$x1%", y1 => "$y1%", x2 => "$x2%", y2 => ($y1+$scale_ra)."%", stroke=>$linecolor,"stroke-width"=>$linewidth.'px');
						}
						$y1 += $scale_ra;
					}
				}


			}else{

				my $y_tmp = $y1;

				my $i = 0;
				foreach my $tab (@tables) {

					$y1 = $y_tmp;

					my $x1_re = $x1 + $i * $linewidth_ra;
					my $x2_re = $x2 + $i * $linewidth_ra;

					my $exps = $$cell_exp_ary_ALL[$i]->{$cell};
					unless (defined $exps) {
						my $sql = "
							SELECT exp FROM \'$tab\' WHERE cell = \'$cell\';
						";
						my $query = $conn->prepare($sql);
						$query->execute;

						while (my @row = $query->fetchrow_array) {
							@$exps = split(',', $row[0]);
						}
						undef $query;
					}


					my $exps_tmp = 0;

					for (1..$$cell_length_ALL[0]->{$cell}) {
						my $cur_tp = $_;
						if (($$celly_start_tp{$cell}+$cur_tp) <= $sub_tp) {

							my $linecolors = &get_linecolors($$linecolors_set[$i],10);

							$exps_tmp = $$exps[$cur_tp-1] if defined $$exps[$cur_tp-1];

							$linecolor = &set_linecolor($exps_tmp,$linecolors);

							if ($autozoom == 1) {
								$svg->line(x1 => "$x1_re%", y1 => "$y1%", x2 => "$x2_re%", y2 => ($y1+$scale_ra)."%", stroke=>$linecolor,"stroke-width"=>$linewidth_ra.'%');
							}else{
								$svg->line(x1 => "$x1_re%", y1 => "$y1%", x2 => "$x2_re%", y2 => ($y1+$scale_ra)."%", stroke=>$linecolor,"stroke-width"=>$linewidth.'px');
							}
							$y1 += $scale_ra;
						}
					}

					$i++;
				}

			}


		}

		if (my @children = $node -> children) {
			### Draw branch
			if ($autozoom == 1) {
				$svg->line(x1 => $$cellx{$children[0]->value}."%", y1 => "$y2%", x2 => $$cellx{$children[1]->value}."%", y2 => "$y2%", stroke=>'black',"stroke-width"=>0.5*$linewidth_ra.'%');
			}else{
				$svg->line(x1 => $$cellx{$children[0]->value}."%", y1 => "$y2%", x2 => $$cellx{$children[1]->value}."%", y2 => "$y2%", stroke=>'black',"stroke-width"=>0.5*$linewidth.'px');
			}
		}

	}


	### draw table name and cell stage
	if ($autozoom == 0 && $titlelabel == 1) {
		$svg->text(x => $spaceleft.'px', y => ($spacetop).'px', "font-family"=>"Times New Roman","font-size"=>$titlefontsize, "-cdata" => "$outfilename", "fill"=>$$labelcolors_set[1], "font-style"=>"italic");
		$svg->text(x => $spaceleft.'px', y => ($spacetop+30).'px', "font-family"=>"Times New Roman","font-size"=>$titlefontsize, "-cdata" => "$leafnumb_ALL[0]-cell stage", "fill"=>$$labelcolors_set[1], "font-style"=>"italic");
	}


	### draw axis
	if ($axis == 1) {


		my $y1_axis = $spacetop;
		my $y4_axis = $y1_axis + $sub_tp * $scale;
		my $y2_axis = int ((1/3)*($y4_axis-$y1_axis)) + $y1_axis;
		my $y3_axis = int ((2/3)*($y4_axis-$y1_axis)) + $y1_axis;
		my $x1_axis = $marginleft + 30;

		### Axis minute
		# my $axislabel1 = $root_start_tp * 1.5;
		# my $axislabel4 = $endtime * 1.5;
		# my $axislabel2 = int ((1/3)*($axislabel4-$axislabel1));
		# my $axislabel3 = int ((2/3)*($axislabel4-$axislabel1));

		### Axis timepoint
		my $axislabel1 = $root_start_tp;
		my $axislabel4 = $endtime;
		my $axislabel2 = int ((1/3)*($axislabel4-$axislabel1));
		my $axislabel3 = int ((2/3)*($axislabel4-$axislabel1));


		$svg->line(x1 => $x1_axis.'px', y1 => $y1_axis.'px', x2 => $x1_axis.'px', y2 => $y4_axis.'px', stroke=>"black","stroke-width"=>"2px");
		my $x2_axis = $x1_axis + 20;
		my $x3_axis = $x2_axis + 10;

		$svg->line(x1 => $x1_axis.'px', y1 => $y1_axis.'px', x2 => $x2_axis.'px', y2 => $y1_axis.'px', stroke=>"black","stroke-width"=>"2px");
		$svg->text(x => $x3_axis.'px', y => ($y1_axis+10).'px', "font-family"=>"Times New Roman","font-size"=>$axfontsize, "-cdata" => $axislabel1);

		$svg->line(x1 => $x1_axis.'px', y1 => $y2_axis.'px', x2 => $x2_axis.'px', y2 => $y2_axis.'px', stroke=>"black","stroke-width"=>"2px");
		$svg->text(x => $x3_axis.'px', y => ($y2_axis+10).'px', "font-family"=>"Times New Roman","font-size"=>$axfontsize, "-cdata" => $axislabel2);

		$svg->line(x1 => $x1_axis.'px', y1 => $y3_axis.'px', x2 => $x2_axis.'px', y2 => $y3_axis.'px', stroke=>"black","stroke-width"=>"2px");
		$svg->text(x => $x3_axis.'px', y => ($y3_axis+10).'px', "font-family"=>"Times New Roman","font-size"=>$axfontsize, "-cdata" => $axislabel3);

		$svg->line(x1 => $x1_axis.'px', y1 => $y4_axis.'px', x2 => $x2_axis.'px', y2 => $y4_axis.'px', stroke=>"black","stroke-width"=>"2px");
		$svg->text(x => $x3_axis.'px', y => ($y4_axis+10).'px', "font-family"=>"Times New Roman","font-size"=>$axfontsize, "-cdata" => $axislabel4);


		my $cx = $x1_axis-10;
		my $cy = ($y4_axis-$y1_axis)/2+70;

		### Axis minute
		# $svg->text(x => $cx.'px', y => $cy.'px', transform =>"rotate(-90, $cx, $cy)", "font-family"=>"Times New Roman","font-size"=>$axfontsize, "-cdata" => "Minute");

		### Axis timepoint
		$svg->text(x => $cx.'px', y => $cy.'px', transform =>"rotate(-90, $cx, $cy)", "font-family"=>"Times New Roman","font-size"=>$axfontsize, "-cdata" => "Timepoint");
	}


	## draw brand
	if ($brand == 1) {
		my $x_brand = $width - $spaceright + 30;
		my $y1_brand = $spacetop;
		my $y2_brand = $height - $spacebottom;

		if ($binary == 1){

			my $x_brand_re;

			my $i = 0;
			foreach (@tables) {
				$x_brand_re = $x_brand + ($i * 20);

				$svg->line(x1 => $x_brand_re.'px', y1 => $y1_brand.'px', x2 => $x_brand_re.'px', y2 => (($y1_brand+$y2_brand)/2).'px', stroke=>"black","stroke-width"=>'20px');

				$svg->line(x1 => $x_brand_re.'px', y1 => (($y1_brand+$y2_brand)/2).'px', x2 => $x_brand_re.'px', y2 => $y2_brand.'px', stroke=>$$linecolors_set[$i],"stroke-width"=>'20px');

				$i++;
			}

			my $cx = $x_brand_re + 15;
			my $cy = $y1_brand;
			$svg->text(x => $cx.'px', y => $cy.'px', transform =>"rotate(90, $cx, $cy)", "font-family"=>"Times New Roman","font-size"=>$brfontsize, "-cdata" => "not express");

			$cy = ($y1_brand + $y2_brand)/2;
			$svg->text(x => $cx.'px', y => $cy.'px', transform =>"rotate(90, $cx, $cy)", "font-family"=>"Times New Roman","font-size"=>$brfontsize, "-cdata" => "express");
		}else{

			my $x_brand_re;

			my $i = 0;
			foreach (@tables) {
				$x_brand_re = $x_brand + ($i * 20);

				my $linecolors = &get_linecolors($$linecolors_set[$i],10);

				my $j = 1;
				foreach (@$linecolors){
					$svg -> line(x1 => $x_brand_re.'px', y1 => ($y1_brand+(($j-1)/10)*($y2_brand-$y1_brand)).'px', x2 => $x_brand_re.'px', y2 => ($y1_brand+($j/10)*($y2_brand-$y1_brand)).'px', stroke => $$linecolors[$j-1], "stroke-width"=>'20px');
					$j++;
				}

				$i++;
			}

			my $cx = $x_brand_re + 15;
			my $cy = ($y1_brand + $y2_brand)/2 - 100;
			$svg->text(x => $cx.'px', y => $cy.'px', transform =>"rotate(90, $cx, $cy)", "font-family"=>"Times New Roman","font-size"=>$brfontsize, "-cdata" => "expression level");

		}
	}


	### Draw border
	# $svg->line(x1 => '0px', y1 => '0px', x2 => '0px', y2 => $height.'px', stroke=>"green","stroke-width"=>'5px');
	# $svg->line(x1 => $width.'px', y1 => '0px', x2 => $width.'px', y2 => $height.'px', stroke=>"green","stroke-width"=>'5px');
	# $svg->line(x1 => '0px', y1 => '0px', x2 => $width.'px', y2 => '0px', stroke=>"green","stroke-width"=>'5px');
	# $svg->line(x1 => '0px', y1 => $height.'px', x2 => $width.'px', y2 => $height.'px', stroke=>"green","stroke-width"=>'5px');

	# $svg->line(x1 => $marginleft.'px', y1 => $margintop.'px', x2 => $marginleft.'px', y2 => ($height-$marginbottom).'px', stroke=>"blue","stroke-width"=>'5px');
	# $svg->line(x1 => ($width-$marginright).'px', y1 => $margintop.'px', x2 => ($width-$marginright).'px', y2 => ($height-$marginbottom).'px', stroke=>"blue","stroke-width"=>'5px');
	# $svg->line(x1 => $marginleft.'px', y1 => $margintop.'px', x2 => ($width-$marginright).'px', y2 => $margintop.'px', stroke=>"blue","stroke-width"=>'5px');
	# $svg->line(x1 => $marginleft.'px', y1 => ($height-$marginbottom).'px', x2 => ($width-$marginright).'px', y2 => ($height-$marginbottom).'px', stroke=>"blue","stroke-width"=>'5px');

	# $svg->line(x1 => $spaceleft.'px', y1 => $spacetop.'px', x2 => $spaceleft.'px', y2 => ($height-$spacebottom).'px', stroke=>"pink","stroke-width"=>'5px');
	# $svg->line(x1 => ($width-$spaceright).'px', y1 => $spacetop.'px', x2 => ($width-$spaceright).'px', y2 => ($height-$spacebottom).'px', stroke=>"pink","stroke-width"=>'5px');
	# $svg->line(x1 => $spaceleft.'px', y1 => $spacetop.'px', x2 => ($width-$spaceright).'px', y2 => $spacetop.'px', stroke=>"pink","stroke-width"=>'5px');
	# $svg->line(x1 => $spaceleft.'px', y1 => ($height-$spacebottom).'px', x2 => ($width-$spaceright).'px', y2 => ($height-$spacebottom).'px', stroke=>"pink","stroke-width"=>'5px');



	## Save svg
	my $out = $svg->xmlify;
	open SVGFILE, ">$outpath";
	print SVGFILE $out;

}


sub set_linecolor {
	my ($exp,$linecolors) = @_;
	
	if ($exp >= 5000){
		return $$linecolors[9];
	}elsif($exp <= 0){
		return $$linecolors[0];
	}else{
		return $$linecolors[int($exp*10/5000)];
	}
}

sub get_linecolors {
	my ($rgb, $levels) = @_;
	$rgb =~ s/\s//g;
	my ($r, $g, $b);

	if ($rgb =~ /^rgb\((\d+),(\d+),(\d+)\)$/) {
		$r = $1;
		$g = $2;
		$b = $3;
	}else{
		die "Error in RGB!";
	}

	$levels -= 1;
	my @linecolors;
	for (0..$levels){
		push @linecolors, 'rgb('.int($_*($r/$levels)).','.int($_*($g/$levels)).','.int($_*($b/$levels)).')';
	}

	return \@linecolors;
}
