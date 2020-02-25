#!/usr/bin/perl

# Repeat
# Fabio Rodrigues (anfabio@gmail.com)
# Versão 1.0

use strict;
use Getopt::Std;
use DateTime;
use Term::ANSIColor qw(:constants);
local $Term::ANSIColor::AUTORESET = 1;

# declare the perl command line flags/options we want to allow
my %options=();
getopts("r:c:p:thv", \%options);

if (($options{h}) or (not %options))
{	
	
  print "
REPETE 1.0
";
  print BOLD "
NOME
";
print "
       repete.pl - repete um comando um determinado número de vezes, adicionando uma pausa entre as execuções

";
  print BOLD "
SINOPSE
";
  print BOLD "
       repete.pl";
  print " [opções]
";
  print BOLD "
OPÇÕES
";
  print "
       -r     Número de repetições (não informar para repetições infinitas).

       -c     Comando a ser utilizado. Caso contenha mais de uma palavra utilizar aspas.

       -p     Pausa durante as execuções (em segundos)

       -t     Mostra o momento em que cada comando foi executado

       -h     Mostra esta ajuda e finaliza

       -v     Informa a versão e finaliza\n\n";
  exit;
}

if ($options{v})
{
  print "repete.pl versão 1.0\n";
  exit;
}


my $counter = $options{r};
my $cmd = $options{c};
my $pause = $options{p};



if ($counter != '') {
	while ($counter > 0) 
	{
  	if ($options{t}) { print DateTime->now()->strftime("%a, %d %b %Y %H:%M:%S \now=========================\n") }
  	system("$cmd");
  	$counter--;
  	if ($counter != 0) {sleep ($pause); }
	}
}


if ($counter == '') {
	while () 
	{
  	if ($options{t}) { print DateTime->now()->strftime("%a, %d %b %Y %H:%M:%S \n=========================\n") }
  	system("$cmd");
  	$counter--;
  	if ($counter != 0) {sleep ($pause); }
	}
}
