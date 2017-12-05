use strict;
use warnings;
use feature 'say';
use DBI;
use Getopt::Long;

#
# Import2db_sqlite.pl
# Reqirements: Perl5
# Author: Xiao-Tai Huang
# Email: xthuang226@gmail.com
# Version: 1.1 for drawing overlapping tree only
# Date: 2017/11/22
#

my $file        = "Import2db_sqlite.pl";
my $program     = uc($&) if $file =~ /^\w+/;
my $version     = "1.1";
my $date        = "2017/11/22";
my $author      = "Xiao-Tai Huang";

### program identification
my $title = "$program $version, $date $author\n";


### option variables
$::opt_help         = 0;
$::opt_inpath       = 'data/';
$::opt_outpath      = 'data/cdfiles.db3';


my $usage = <<"END_OF_USAGE";
${title}Syntax:   \L$program\E [options]
Function: Import cell lineage data into SQLite.
Options:                                                             (defaults:)
  -h, --help            print usage
  -i, --inpath          set input cell lineage data .csv file path   ($::opt_inpath)
  -o, --outpath         set output SQLite .db3 file path             ($::opt_outpath)
Examples:
  \L$program\E
  \L$program\E -i=../data/single_cell_data/ -o=../data/single_cell_data/cdfiles_nhr25.db3 -x=../data/single_cell_data/experiment_info.csv
END_OF_USAGE


### process options
my @OrgArgv = @ARGV;
GetOptions(
  "help|h!",
  "inpath|i=s",
  "outpath|o=s",
) or die $usage;
!$::opt_help or die $usage;


### Set parameters
my ($inpath, $outpath) = ($::opt_inpath, $::opt_outpath);


### Make output file or path
my $output = $outpath;
$output =~ s/\/([^\/]+)$//;

my $output_tmp = $output;
my $output_whole;

while ($output_tmp =~ s/^([\.\/]*[^\.\/]+\/?)//) {
	$output_whole .= $&;
	mkdir $output_whole;
}


### Connect to database.
my $conn = DBI->connect("dbi:SQLite:dbname=$outpath","","",{ RaiseError => 1 }) or die $DBI::errstr;


### Read current tables in db.
my %tables;
foreach (split (/[\s\n]+/, `sqlite3 $outpath .tables`)) {
	$tables{$_} = $_;
}


### Read .csv file
opendir (DIR, "$inpath") || die "Cannot open dir : $!";
my @files = readdir(DIR);
close DIR;


### Build tables and import data from .csv files
my ($sql,$query);
my $etype = 'scd';
foreach (@files){
	if (/^((.+)\.csv)$/){
		unless (defined $tables{$2}) {
			say "\n$1";
			&insert1cdf ($1, "$etype\_$2", $inpath, $outpath);

			&info_table ("$etype\_$2", $2);

			say "Adding cell supplementary information...\n";
			&add_supp_info($2);

			&drop_table("$etype\_$2");
		}
	}
}



$conn->disconnect;
undef $conn;


###Show current tables
map{say}(split (/[\s\n]+/, `sqlite3 $outpath .tables`));




### Load data into tables from .csv file
sub insert1cdf {
	my ($file, $table, $inpath, $outpath) = @_;

	my $sql = "
		CREATE TABLE \'$table\' (
			cellTime	TEXT PRIMARY KEY NOT NULL,
			cell	TEXT,
			time	INT,
			none	INT,
			global	INT,
			local	INT,
			blot	INT,
			cross	INT,
			z	REAL,
			x	INT,
			y	INT,
			size	INT,
			gweight	INT
		);
	";
	my $query = $conn->prepare($sql);
	$query->execute;
	undef $query;

	open(PIPE, "|sqlite3 $outpath") or die "Open pipe error: $!";
	say PIPE ".mode csv\n.import $inpath$file $table\n.exit";
	close PIPE;
	$tables{$table} = $table;

}


### Create tables with useful information from original tables.
sub info_table {
	my ($table_tmp,$table) = @_;

	unless (defined $tables{$table}) {
		my $sql = "
			CREATE TABLE $table
			(
			  cell TEXT PRIMARY KEY,
			  time INT,
			  len INT,
			  exp VARYING TEXT,
			  avgexp REAL,
			  cellpath TEXT
			);
		";
		my $query = $conn->prepare($sql);
		$query->execute;
		undef $query;
		$tables{$table} = $table;

		$sql = "
			INSERT INTO $table (cell, time, len, exp, avgexp)
			SELECT cell, min(time), count(*), group_concat(blot), avg(blot)
			FROM \'$table_tmp\'
			WHERE cell GLOB \'[ACDEMPZ]*\'
			GROUP BY cell;
		";
		$query = $conn->prepare($sql);
		$query->execute;
		undef $query;
	}
}


### Get cell path. Cell path represents a path from the zygote ('P0') to the specified cell. For example of cell 'ABala', its cell path is 'P0.AB.a.l.a';
sub get_cellpath {
	my ($cell) = @_;
	my @cellpath;

	while ($cell =~ s/([a-z])$//) {
		unshift @cellpath, $1;
	}
	unshift @cellpath, $cell;

	until($cellpath[0] eq 'P0'){
		if ($cellpath[0] eq 'AB') {
			unshift @cellpath, 'P0';
		}
		if ($cellpath[0] eq 'P1') {
			unshift @cellpath, 'P0';
		}
		if ($cellpath[0] eq 'EMS') {
			unshift @cellpath, 'P1';
		}
		if ($cellpath[0] eq 'P2') {
			unshift @cellpath, 'P1';
		}
		if ($cellpath[0] eq 'MS') {
			unshift @cellpath, 'EMS';
		}
		if ($cellpath[0] eq 'E') {
			unshift @cellpath, 'EMS';
		}
		if ($cellpath[0] eq 'C') {
			unshift @cellpath, 'P2';
		}
		if ($cellpath[0] eq 'P3') {
			unshift @cellpath, 'P2';
		}
		if ($cellpath[0] eq 'D') {
			unshift @cellpath, 'P3';
		}
		if ($cellpath[0] eq 'P4') {
			unshift @cellpath, 'P3';
		}
		if ($cellpath[0] eq 'Z2') {
			unshift @cellpath, 'P4';
		}
		if ($cellpath[0] eq 'Z3') {
			unshift @cellpath, 'P4';
		}
	}

	return join ('.', @cellpath);
}


### Add some supplementary information about cells into tables, such as cell path, left or right child.
sub add_supp_info {
	my ($table) = @_;
	my $sql = "
		SELECT cell from $table
	";
	my $query = $conn->prepare($sql);
	$query->execute;

	while (my @row = $query->fetchrow_array) {
		my $sql = "
			UPDATE $table
			SET cellpath = ?
			WHERE cell IS ?;
		";
		my $query = $conn->prepare($sql);
		$query->execute(&get_cellpath($row[0]), $row[0]);
		undef $query;		
	}
	undef $query;
}


### Drop table in db
sub drop_table {
	my ($table) = @_;

	my $sql = "
		DROP TABLE \'$table\';
	";
	my $query = $conn->prepare($sql);
	$query->execute;
	undef $query;
}