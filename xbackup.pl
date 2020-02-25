#!/usr/bin/perl

# XBackup (Percona)
# Fabio Rodrigues (anfabio@gmail.com)
# Version 2.0

use strict;
use Getopt::Std;
use DateTime;
use POSIX qw(strftime);
use Term::ANSIColor qw(:constants);


my %options=();
getopts("b:x:m:u:p:fihv", \%options);

if ( ($options{h}) or (not %options) ) {
	
  print "
xbackup (Percona Mysql Server) 1.0
";
  print BOLD "
NOME
";
  print RESET"
       xbackup.pl - backup usando percona xtrabackup

";
  print BOLD "
SINOPSE
";
  print RESET"
Uso: xbackup [OPÇÕES]...
Caso nenhum parâmetro de incremento seja informado, será realizado um backup completo.
\n";
  print " [opções]
";
  print BOLD "
OPÇÕES
";
    print RESET" 
       -f     Backup completo
       
       -i     Backup incremental. Necessita de um backup base (completo) no diretório escolhido
	   
       -b     Caminho para o diretório backup (padrão é /var/backup)
       
       -x     Caminho para o binário do xtrabackup (padrão é /usr/bin/xtrabackup)
       
       -m     Configuração do mysql (padrão é /etc/my.cnf)
       
       -u     Usuário mysql
       
       -p     Senha mysql
       
       -h     Mostra esta ajuda e finaliza

       -v     Informa a versão e finaliza\n\n";

print BOLD "
EXEMPLOS
";
print RESET"

Backup completo do DB
";
print BOLD "
	xbackup.pl -u root -p 123 -f -b /var/backup/mysql/completo
";

print RESET"
Novo backup incremental (a partir do diretório contendo o arquivo mysql com usuário e senha)
";
print BOLD "
	xbackup.pl -i -b /var/backup/mysql/maio
";      
  exit;
}

if ($options{v})
{
  print "xbackup.pl versão 1.0\n";
  exit;
}


my $dateformat = "%Y/%m/%d %H:%M:%S";
my $BKP_PATH;
my $XTRABACKUP_BIN;
my $MYSQL_CFG;
my $BKP_FULL;
my $conf;
my $user;
my $pass;
my $conn_test;

if ($options{b}) {$BKP_PATH=$options{b}} else {$BKP_PATH="/var/backup"};
if ($options{x}) {$XTRABACKUP_BIN=$options{x}} else {$XTRABACKUP_BIN="/usr/bin/xtrabackup"};
if ($options{m}) {$MYSQL_CFG=$options{m}} else {$MYSQL_CFG="/etc/my.cnf"};

if ($options{u}) {$user=$options{u}};
if ($options{p}) {$pass=$options{p}};


#TESTE DE CONEXÃO AO MYSQL
if ($user) {$conn_test=`/usr/local/mysql/bin/mysqladmin -u $user -p$pass ping 2>/dev/null`; }
else {$conn_test=`/usr/local/mysql/bin/mysqladmin ping 2>/dev/null`;}

if ($conn_test !~ /alive/) {
	print "
#############################################################################
NÃO FOI POSSÍVEL CONECTAR AO BANCO DE DADOS COM O USUÁRIO E SENHA INFORMADOS!
#############################################################################\n";
	exit;
	}

if (! -d "$BKP_PATH") {system("/usr/bin/mkdir -p $BKP_PATH")}

	print "
#######################################################
USANDO DIRETÓRIO $BKP_PATH PARA O BACKUP
#######################################################\n";	


############################  B A C K U P   I N C R E M E N T A L  ############################

if ($options{i}) {
		print "
#######################################################
CRIANDO BACKUP INCREMENTAL...
#######################################################\n";	
		system("/usr/local/xtrabackup/innobackupex --user $user --password $pass --defaults-file=$MYSQL_CFG --ibbackup=$XTRABACKUP_BIN --no-lock --incremental $BKP_PATH");
	
	my $LAST=`/usr/bin/ls -t $BKP_PATH| head -n 1`;
	chomp $LAST;
	print "
#######################################################
BACKUP INCREMENTAL $LAST CRIADO EM $BKP_PATH
#######################################################\n";	
	}
	
############################  B A C K U P    C O M P L E T O  ############################
	
else {
	print "
#######################################################
CRIANDO BACKUP TOTAL EM $BKP_PATH
#######################################################\n";		
	system("/usr/local/xtrabackup/innobackupex --user $user --password $pass --defaults-file=$MYSQL_CFG --ibbackup=$XTRABACKUP_BIN --no-lock $BKP_PATH");
	
	my $LAST=`ls -t $BKP_PATH| head -n 1`;
	chomp $LAST;
	print "
#######################################################
BACKUP TOTAL $LAST CRIADO EM $BKP_PATH
#######################################################\n";	
	}


#CRIANDO SCHEMAS
print "
######################################################
CRIANDO SCHEMAS...
#######################################################\n";	
my $LAST=`ls -t $BKP_PATH| head -n 1`;
chomp $LAST;
system("/usr/bin/mkdir -p $BKP_PATH/$LAST/schemas");
	
foreach my $DATABASE (`/usr/bin/find $BKP_PATH/$LAST/* -type d |xargs -n 1 basename`) {
	chomp $DATABASE;
	print "CRIANDO SCHEMA $DATABASE...\n";
	system("mysqldump -u $user -p$pass --no-data --single-transaction $DATABASE 2>/dev/null > $BKP_PATH/$LAST/schemas/$DATABASE.schema.sql");
	}

print "
#######################################################
SCHEMAS CRIADOS EM $BKP_PATH/$LAST/schemas
#######################################################\n";	

#comprimindo
print "COMPRIMINDO BACKUP... ";
if ($options{i}) {
	my $INC_NR = `/usr/bin/ls $BKP_PATH/*.tar.gz |wc -l`;	
	chomp $INC_NR;
	system("tar -zcf $BKP_PATH/$LAST.INC-$INC_NR.tar.gz -C $BKP_PATH $LAST");
	}
else {
	system("tar -zcf $BKP_PATH/$LAST.COMPLETO.tar.gz -C $BKP_PATH $LAST");
	}

print "OK!\n";

#removendo arquivos desnecessarios
print "REMOVENDO ARQUIVOS DESNECESSÁRIOS... ";
system("ls -d $BKP_PATH/$LAST/* |grep -v xtrabackup_checkpoints |xargs rm -rf");
print "OK!\n";

    
exit;
