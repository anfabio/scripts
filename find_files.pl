#!/usr/bin/perl

# Find Files
# Fabio Rodrigues (anfabio@gmail.com)
# Versão 2.0

use strict;
use Getopt::Std;
use POSIX qw(strftime);
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use File::Find::Rule;
use Number::Bytes::Human qw(format_bytes);
use List::Util qw( sum );
use Spreadsheet::WriteExcel;

my %options=();
getopts("d:r:x:hv", \%options);

if ( ($options{h}) or (not %options) ) {
	
  print "
find_files 1.0
";
  print BOLD "
NOME
";
  print RESET"
       find_files.pl - find

";
  print BOLD "
SINOPSE
";
  print RESET"
Uso: find_files [OPÇÕES]...
\n";
  print " [opções]
";
  print BOLD "
OPÇÕES
";
    print RESET" 
       -d     Diretorio Raiz
              
       -r     Regras, uma por linha (ex: 	MP3,*.txt
											PDF,*.pdf)
       
       -x	  Arquivo Excel para o relatorio
       
       -h     Mostra esta ajuda e finaliza

       -v     Informa a versão e finaliza\n\n";

print BOLD "
EXEMPLOS
";
print RESET"

Exemplo 1
";
print BOLD "
	find_filesv2.pl -d /home -r /tmp/rules.txt  -x /tmp/relatorio.xls	
";
  exit;
}

if ($options{v})
{
  print "find_files.pl versão 1.0\n";
  exit;
}

my $ROOT_DIR;
my $NAME_RULES;
my $REPORT_FILE;
my $REPORT_TITLE;
my %rules;

if ($options{d}) {$ROOT_DIR=$options{d}} else {$ROOT_DIR="."};
if ($options{r}) {$NAME_RULES=$options{r}; chomp $NAME_RULES} else {$NAME_RULES="/tmp/parse"};
if ($options{x}) {$REPORT_FILE=$options{x}} else {$REPORT_FILE="/tmp/report.xls"};

my $worksheet = Spreadsheet::WriteExcel->new("$REPORT_FILE");

# Sheet Formats
my $header_format = $worksheet->add_format(bold => 1, bg_color => 'red', align => 'center', border   => 1, shrink => 1, font  => 'Arial', size  => 12, color => 'white');
my $font_format = $worksheet->add_format(font  => 'Arial', size  => 11, border => 1, align => 'right');
my $title_format = $worksheet->add_format(font  => 'Arial', size  => 24, border => 0, align => 'center', bold => 1);

# SUM KEY VALUES
sub sumkeys {
	my (%hash) = @_;
	my $total;
	for my $key (keys %hash) {      
	$total += sum($hash{$key});
	}
	return $total;
}
	
	
# Read Rules Data
open DATA, $NAME_RULES or die $!;
while (<DATA>) {
    my @rules_row = split(/,/);    
    $rules{@rules_row[0]} = @rules_row[1];   
}
print "================================================================\n";
print $ROOT_DIR,"\n";
print "================================================================\n\n\n";



# Search
for (keys %rules) {	
	my $rule = $rules{$_};
	chomp ($rule);
	print $_, " $rule\n";
	print "================================================================\n";
	
	my @files = `nice find $ROOT_DIR -type f -iname $rule`;
	print Dumper @files;
		
		
	
		
	my %lista;
	foreach (@files)
	{	
		chomp $_;		
		s/`/\\`/g;
		print "$_\n";
		Encode::_utf8_on($_);
		my $size =  `/usr/bin/stat -c %s "$_"`;
		$lista{$_} = $size;
		print "Tamanho: ",format_bytes($size),"\n";		
		
	}
	
	my $total = sumkeys(%lista);
	
	print "\nTOTAL: ",format_bytes($total),"\n";
	print "----------------------------------------------------------------\n\n";
	
	#Teste
#	print "$_ ", format_bytes($lista{$_}),"\n" for (keys %lista);
#	print "$_ $lista{$_}\n" for (keys %lista);
	
#	print format_bytes(sumkeys(%lista)),"\n";
#	print sumkeys(%lista),"\n"	;
	

	# Print Sheet
	my $sheet = $worksheet->add_worksheet("$_");
	$sheet->set_column('A:Z', 20, $font_format);

	
	$sheet->write(0, 0, "$ROOT_DIR", $title_format);


	#Print Sheet Header
	$sheet->write(2, 0, "Arquivo", $header_format);
	$sheet->write(2, 1, "Tamanho", $header_format);
	
	my $column = 0;
	my $row = 3;	
	
	#Print Sheet Data
	for (keys %lista) {
		Encode::_utf8_on($_);
		$sheet->write($row, $column, "$_", $font_format);		
		$sheet->write($row, $column+1, format_bytes($lista{$_}), $font_format);
		$row++;
	}
	
	# Print Total
	
	$sheet->write($row, $column, "TOTAL", $header_format);
	$sheet->write($row, $column+1, format_bytes($total), $header_format);	

	$sheet->set_column(0, 0, 80);
}
