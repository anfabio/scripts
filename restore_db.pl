#!/usr/bin/perl

# Restore DB (Percona)
# Fabio Rodrigues (anfabio@gmail.com)
# Versão 1.0

use strict;
use Getopt::Std;
use DateTime;
use POSIX qw(strftime);


my %options=();
getopts("d:f:u:p:l:hv", \%options);

if ($options{h})
{	
	
  print "
Restore DB (Percona Mysql Server) 1.0
";
  print BOLD "
NOME
";
print "
       restore_db.pl - restaura uma database de um backup usando percona xtrabackup

";
  print BOLD "
SINOPSE
";
  print BOLD "
       restore_db.pl";
  print " [opções]
";
  print BOLD "
OPÇÕES
";
  print "
       -d     Nome da database (obrigatório)

       -f     Caminho do arquivo de backup em formato tar.gz (obrigatório)
       
       -l     Caminho para a lib do mysql (padrão é /var/lib/mysql)
       
       -u     Usuário mysql
       
       -p     Senha mysql
       
       -h     Mostra esta ajuda e finaliza

       -v     Informa a versão e finaliza\n\n";
  exit;
}

if ($options{v})
{
  print "restore_db.pl versão 1.0\n";
  exit;
}


my $dateformat = "%Y/%m/%d %H:%M:%S";
my $MYSQL_LIB;
my $BKP_FILE;
my $DB_NAME;
my $user;
my $pass;
my $BASE_DIR;

if ($options{f}) {$BKP_FILE=$options{f}} else {print "Nenhum arquivo de backup informado\n"; exit;};
if ($options{d}) {$DB_NAME=$options{d}}  else {print "Nenhuma database informada\n"; exit;};
if ($options{l}) {$MYSQL_LIB=$options{l}} else {$MYSQL_LIB="/var/lib/mysql"};
if ($options{u}) {$user=$options{u}};
if ($options{p}) {$pass=$options{p}};


if ($BKP_FILE) {
	$BASE_DIR = "/tmp/".`/usr/bin/basename $BKP_FILE |cut -d . -f 1`;	
	chomp $BASE_DIR;
	system("/usr/bin/mkdir $BASE_DIR");
	system("/bin/tar xvf $BKP_FILE -C $BASE_DIR");
}

system("/usr/local/xtrabackup/innobackupex --apply-log --export $BASE_DIR");

system("/usr/local/mysql/bin/mysql -u $user -p$pass --execute \"CREATE DATABASE $DB_NAME\"");


system("/usr/local/mysql/bin/mysql -u $user -p$pass --execute \"SET FOREIGN_KEY_CHECKS=0\"");


system("/usr/local/mysql/bin/mysql -u $user -p$pass $DB_NAME < $BASE_DIR/$DB_NAME.schema.sql");


foreach my $table (`ls $BASE_DIR/$DB_NAME/*.ibd |xargs -n 1 basename |cut -d . -f 1`)
		{
			chomp $table;			
			system("/usr/local/mysql/bin/mysql -u $user -p$pass --execute \"SET FOREIGN_KEY_CHECKS=0; ALTER TABLE $DB_NAME.$table DISCARD TABLESPACE\"");
			system("/usr/bin/cp $BASE_DIR/$DB_NAME/$table.ibd $MYSQL_LIB/$DB_NAME");
			system("/usr/bin/cp $BASE_DIR/$DB_NAME/$table.exp $MYSQL_LIB/$DB_NAME");
			system("/usr/bin/chown mysql:mysql $MYSQL_LIB/$DB_NAME/$table.*");
			system("/usr/local/mysql/bin/mysql -u $user -p$pass --execute \"SET FOREIGN_KEY_CHECKS=0; ALTER TABLE $DB_NAME.$table IMPORT TABLESPACE\"");
			system("/usr/local/mysql/bin/mysql -u $user -p$pass --execute \"ANALYZE TABLE $DB_NAME.$table\"");
		}

system("/usr/local/mysql/bin/mysql -u $user -p$pass --execute \"SET FOREIGN_KEY_CHECKS=1\"");

exit;
