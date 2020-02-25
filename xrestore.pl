#!/usr/bin/perl

# XBackup (Percona)
# Fabio Rodrigues (anfabio@gmail.com)
# Version 1.0

use strict;
use Getopt::Std;
use DateTime;
use POSIX qw(strftime);
use Term::ANSIColor qw(:constants);

my %options=();
getopts("f:i:l:d:a:m:t:u:p:hv", \%options);

if ( ($options{h}) or (not %options) ) {
  print "
XRestore (Percona Mysql Server) 1.0
";
  print BOLD "
NOME
";
print RESET "
       xrestore.pl - restaura um backup usando percona xtrabackup

";
  print BOLD "
SINOPSE
";
  print RESET "
       xrestore.pl";
  print " [opções]
";
  print BOLD "
OPÇÕES
";
  print RESET"
       -f     Restauração completa. Informar o caminho do arquivo de backup em formato tar.gz. A cópia dos arquivos restaurados deverá ser feito manualmente.
              
       -i      Restauração incremental. Informar o caminho do DIRETÓRIO de backups (base/incremental). Pode-se informar o nome ou uma lista das databases a serem restauradas (opções -b ou -a). Caso nenhuma database seja informada, o backup será preparado para restauração completa de todas as databases. A cópia dos arquivos restaurados deverá ser feito manualmente.
       
       -l     Caminho do diretório último backup incremental desejado (usado em conjunto com a opção -i). Caso não seja informado, o último backup incremental do diretório informado na opção -i será utilizado.
       
       -d     Nome da database a ser restaurada
       
       -a     Lista de databases a serem restauradas (1 por linha).
              
       -m     Caminho para os dados do mysql (padrão é /var/lib/mysql)
       
       -t     Caminho do diretório onde a restauração deve ser preparada. Caso não seja informado, o diretório do arquivo tar.gz (opção -f) ou o diretório dos backups incrementais (opção -i) será utilizado.       
       
       -u     Usuário mysql
       
       -p     Senha mysql
       
       -h     Mostra esta ajuda e finaliza

       -v     Informa a versão e finaliza\n\n";

  print BOLD "
EXEMPLOS
";

  print RESET"
Preparar uma restauração completa no diretório \"/tmp/restauracao\" a partir de um backup bkp.completo.tar.gz:";
  print BOLD "
	xrestore.pl -u usuario -p pass -f /var/backup/2014fev/bkp.completo.tar.gz -t /tmp/restauracao
";
  print RESET"
Preparar uma restauração completa no diretório \"/tmp/restauracao\" usando incrementos. O último incremento é o bkp.inc-2.tar.gz:";
  print BOLD "
	xrestore.pl -u usuario -p pass -i /var/backup/2014fev -l bkp.inc-2.tar.gz -t /tmp/restauracao
";
  print RESET"
Restaurar um DB chamado mydb usando o diretório \"/tmp/restauracao\" como preparação temporária dos arquivos. O último incremento é o último incremento do diretório onde estão os backups:";
  print BOLD "
	xrestore.pl -u usuario -p pass -i /var/backup/2014fev -t /tmp/restauracao -d mydb
";
  print RESET"
Restaurar os DBs do arquivo mydb.list. O último incremento é o INC-3 do diretório onde estão os backups:";
  print BOLD "
	xrestore.pl -u usuario -p pass-i /var/backup/2014fev -l bkp.inc-3.tar.gz -a mydb.list
";
	exit;
}

if ($options{v})
{
  print "xrestore.pl versão 1.0\n";
  exit;
}


my $dateformat = "%Y/%m/%d %H:%M:%S";
my $MYSQL_LIB;
my $BKP_FILE;
my $DB_NAME;
my $DB_LIST;
my $user;
my $pass;
my $BASE_DIR;
my $BKP_INC_PATH;
my $LAST_INC;
my $BKP_FULL_PATH;
my $BKP_INC_BASE;
my @INCREMENTOS;
my @DBs;
my $DB_NULL = 0;
	


if ($options{f}) {$BKP_FILE=$options{f}};
if ($options{i}) {$BKP_INC_PATH=$options{i}};
if ($options{l}) {$LAST_INC=$options{l}};
if ($options{d}) {$DB_NAME=$options{d}};
if ($options{a}) {$DB_LIST=$options{a}};
if ($options{t}) {$BKP_FULL_PATH=$options{t}};
if ($options{m}) {$MYSQL_LIB=$options{m}} else {$MYSQL_LIB="/var/lib/mysql"};
if ($options{u}) {$user=$options{u}};
if ($options{p}) {$pass=$options{p}};

chomp $DB_NAME;
chomp $BKP_FILE;
chomp $BKP_INC_PATH;
chomp $LAST_INC;
chomp $BKP_FULL_PATH;
chomp $MYSQL_LIB;
chomp $user;
chomp $pass;

#####################################   T E S T E S   ##################################### 

# TESTE DE NENHUM DB FOI INFORMADO (BACKUP SE TORNA COMPLETO - DB_NULL=TRUE)
if ( ((not defined($options{d})) or ($DB_NAME eq "")) and ((not defined($options{a})) or ($DB_LIST eq "")) ) { $DB_NULL = 1;}


if ( (not defined($options{f})) and (not defined($options{i})) ) {
	print "Usar apenas uma das opções (-f ou -i).\n";
	exit;
	}

if ( ($BKP_FILE ne "") and ($BKP_INC_PATH ne "") ) { 
	print "Usar apenas uma das opções: -f (completo) ou -i (incremental).\n";
	exit;
	}

############################  R E S T A U R A Ç Ã O   C O M P L E T A  ############################
if ($options{f}) {
	if (-d "$BKP_FILE") {print "Arquivo informado é um diretório ($BKP_FILE).\n"; exit;}
	if (not -e $BKP_FILE) {print "Arquivo informado inesistente ($BKP_FILE).\n"; exit;}
	#Restauração a partir de arquivo tar.gz
	if ($options{f}) {		
		if ($BKP_FULL_PATH eq "") { $BKP_FULL_PATH = `/usr/bin/dirname $BKP_FILE`}
		if (not -d "$BKP_FULL_PATH") {system("/usr/bin/mkdir -p $BKP_FULL_PATH");}
		print "
#######################################################
USANDO DIRETÓRIO $BKP_FULL_PATH PARA RESTAURAÇÃO
#######################################################\n";
		system("/bin/tar xf $BKP_FILE --strip-components 1 -C $BKP_FULL_PATH");			
		system("/usr/local/xtrabackup/innobackupex --apply-log $BKP_FULL_PATH");
		#Removendo arquivos desnecessários
		system("/usr/bin/rm $BKP_FULL_PATH/backup-my.cnf");
		system("/usr/bin/rm $BKP_FULL_PATH/xtrabackup_*");
		system("/usr/bin/rm -rf $BKP_FULL_PATH/schemas");
		#Dando permissões para o mysql
		system("/usr/bin/chown -R mysql:mysql $BKP_FULL_PATH");
		print "
###################################################################		
Restauração preparada no diretório $BKP_FULL_PATH
Para efetivar a mesma execute os passos abaixo:
1. Parar o mysql server: /etc/init.d/mysql stop
2. Remover todos os dados do mysql: rm -rf $MYSQL_LIB
3. Copiar os arquivos restaurados para o diretório de dados do mysql: rsync -avrP $BKP_FULL_PATH/ $MYSQL_LIB/
4. Certifique-se de que as permissões dos novos dados estão corretas. Caso negativo, mude-as com o comando: chown -R mysql:mysql $MYSQL_LIB
5. Iniciar o mysql server: /etc/init.d/mysql start
6. Copiar o arquivo my.cnf de backup para $MYSQL_LIB: cp /home/backup/.my.cnf $MYSQL_LIB/
###################################################################\n";
		}
	exit;
	}


############################  R E S T A U R A Ç Ã O   I N C R E M E N T A L ############################
if ($options{i}) {
	
	# SE NENHUM DIRETÓRIO ALVO FOR INFORMADO O MESMO SERÁ PREPARADO NO PRÓPRIO DIRETÓRIO DE BACKUP
	if ($BKP_FULL_PATH eq "") { $BKP_FULL_PATH = $BKP_INC_PATH;}
	if (not -d "$BKP_FULL_PATH") {system("/usr/bin/mkdir -p $BKP_FULL_PATH");}
	print "
#######################################################
DIRETÓRIO DE RESTAURAÇÃO: $BKP_FULL_PATH
#######################################################\n";

	# SE O ÚLTIMO INCREMENTO NÃO FOR INFORMADO SERÃO PROCESSADOS TODOS OS INCREMENTOS
	if ( ((not defined($options{l})) or ($LAST_INC eq "")) ) {
		$LAST_INC = `/usr/bin/ls -t $BKP_INC_PATH/*.tar.gz |head -n1 | xargs -n1 basename |cut -d . -f1,2`;
		print "ÚLTIMO INCREMENTO DEFINIDO AUTOMATICAMENTE: $LAST_INC\n";
		}
	else {
		$LAST_INC =~ s/.......$//;
		print "ÚLTIMO INCREMENTO: $LAST_INC\n";
		}
		
	print"
###########################################################
DIRETÓRIO DE BACKUP INCREMENTAL: $BKP_INC_PATH
###########################################################\n";	
	
	print "INCREMENTOS A SEREM PROCESSADOS:\n";			
	foreach my $INC (`/usr/bin/ls -tr $BKP_INC_PATH/*tar.gz | xargs -n1 basename |cut -d . -f1,2`) {
		chomp $INC;
		push @INCREMENTOS, $INC;
		print "$INC\n";
		if ($INC eq $LAST_INC) {last;}
		}
	
										######## PREPARAR BASE ######## 
	$BKP_INC_BASE = "$INCREMENTOS[0]";
	print "
#######################################################
PROCESSANDO BASE: :$BKP_INC_BASE
#######################################################\n";	
		
	system("/bin/tar xf $BKP_INC_PATH/$BKP_INC_BASE.tar.gz -C $BKP_FULL_PATH");	
	
	######## REMOVENDO "COMPLETO" DO NOME ########
	$BKP_INC_BASE =~ s/.COMPLETO//;
	
	#TESTA ÚLTIMO ELEMENTO
	if ($BKP_INC_BASE eq $LAST_INC) {		
		system ("/usr/bin/xtrabackup --prepare --target-dir=$BKP_FULL_PATH/$BKP_INC_BASE");
		#####Remover arquivos desnecessários
		}
	else {
		system ("/usr/bin/xtrabackup --prepare --apply-log-only --target-dir=$BKP_FULL_PATH/$BKP_INC_BASE");
		splice @INCREMENTOS, 0, 1;
		}		
	
								######## PREPARAR INCREMENTOS ######## 
										

	#PROCESSANDO OS INCREMENTOS
	foreach (@INCREMENTOS) {
		chomp $_;
		system ("/bin/tar xf $BKP_INC_PATH/$_.tar.gz -C $BKP_FULL_PATH");			
		if ($_ eq $INCREMENTOS[-1]) { # TESTA SE É O ÚLTIMO INCREMENTO		
				
#### ÚLTIMO INCREMENTO
			print "
#######################################################
PROCESSANDO ÚLTIMO INCREMENTO $_
#######################################################\n";			
			if ($DB_NULL) { #NENHUM DB DEFINIDO - NÃO É USADA A OPÇÃO EXPORT
				my @dir = split('\.', $_);
				system ("/usr/bin/xtrabackup --prepare --target-dir=$BKP_FULL_PATH/$BKP_INC_BASE --incremental-dir=$BKP_FULL_PATH/$dir[0]");
				}
			else { #DB INFORMADO - RESTAURAÇÃO PARCIAL USANDO EXPORT
				my @dir = split('\.', $_);
				system ("/usr/bin/xtrabackup --prepare --export --target-dir=$BKP_FULL_PATH/$BKP_INC_BASE --incremental-dir=$BKP_FULL_PATH/$dir[0]");				
				}
			}
#### PRÓXIMO INCREMENTO			
		else {			
			print "
#######################################################
PROCESSANDO INCREMENTO: $_
#######################################################\n";
			my @dir = split('\.', $_);
			system ("/usr/bin/xtrabackup --prepare --apply-log-only --target-dir=$BKP_FULL_PATH/$BKP_INC_BASE --incremental-dir=$BKP_FULL_PATH/$dir[0]");
			}
		}	
		
		
						######## COPIAR SCHEMAS DO ÚLTIMO INCREMENTO ######## 		
		
	print "
#######################################################
COPIANDO SCHEMAS
#######################################################\n";
	if ( $INCREMENTOS[0] ne "" ) { # HÁ ALGUM ELEMENTO NO ARRAY			
		print "$BKP_FULL_PATH/$BKP_INC_BASE/schemas\n";
		system ("rm -r $BKP_FULL_PATH/$BKP_INC_BASE/schemas");
		my @dir = split('\.', $INCREMENTOS[-1]);
		print
		print ("cp -r $BKP_FULL_PATH/$dir[0]/schemas $BKP_FULL_PATH/$BKP_INC_BASE\n");
		system ("cp -r $BKP_FULL_PATH/$dir[0]/schemas $BKP_FULL_PATH/$BKP_INC_BASE");
		}
	
	# NENHUM DB FOI INFORMADO (BACKUP SE TORNA COMPLETO)	
	if ($DB_NULL) {
			print "
#######################################################
NENHUM DB DEFINIDO PARA RESTAURAÇÃO
PREPARANDO RESTAURAÇÃO COMPLETA
#######################################################\n";
		$BKP_FULL_PATH = "$BKP_FULL_PATH/$BKP_INC_BASE";
		#Removendo arquivos desnecessários
		system("/usr/bin/rm $BKP_FULL_PATH/backup-my.cnf");
		system("/usr/bin/rm $BKP_FULL_PATH/xtrabackup_*");
		system("/usr/bin/rm -rf $BKP_FULL_PATH/schemas");
		#Dando permissões para o mysql
		system("/usr/bin/chown -R mysql:mysql $BKP_FULL_PATH");		
		print "
###################################################################		
Restauração preparada no diretório $BKP_FULL_PATH
Para efetivar a mesma execute os passos abaixo:
1. Parar o mysql server: /etc/init.d/mysql stop
2. Remover todos os dados do mysql: rm -rf $MYSQL_LIB
3. Copiar os arquivos restaurados para o diretório de dados do mysql: rsync -avrP $BKP_FULL_PATH/ $MYSQL_LIB/
4. Certifique-se de que as permissões dos novos dados estão corretas. Caso negativo, mude-as com o comando: chown -R mysql:mysql $MYSQL_LIB
5. Iniciar o mysql server: /etc/init.d/mysql start
6. Copiar o arquivo my.cnf de backup para $MYSQL_LIB: cp /home/backup/.my.cnf $MYSQL_LIB/
###################################################################\n";
		exit;		
		}
		
	}


############################  R E S T A U R A Ç Ã O   D A S   D A T A B A S E S ############################	

if ($options{i}) {
	
	# PREVENIR USAR LISTA E NOME DO DB AO MESMO TEMPO
	if ( ($DB_LIST ne "") and ($DB_NAME ne "") ) { 
	print "Usar apenas uma das opções: -b (database) ou -a (lista).\n";
	exit;
	}
	
	#OBTER DBs DA LISTA
	if ($DB_LIST ne "") {
	open(my $DB, "<", "$DB_LIST")
		or die "Falha ao abrir arquivo: $DB_LIST\nAbortando...";
	while(<$DB>) {
		chomp;
		push @DBs, $_;
		}
	close $DB;
	}

	#OBTER DB ÚNICO
	if ($DB_NAME ne "") {
	chomp $DB_NAME;
	push @DBs, $DB_NAME;
	}
	
	#RESTAURANDO OS DBs
	foreach (@DBs) {
		system("/usr/local/mysql/bin/mysql -u $user -p$pass --execute \"CREATE DATABASE $_\" 2>/dev/null");
		system("/usr/local/mysql/bin/mysql -u $user -p$pass $_ < $BKP_FULL_PATH/$BKP_INC_BASE/schemas/$_.schema.sql");		
		foreach my $table (`/usr/bin/ls $BKP_FULL_PATH/$BKP_INC_BASE/$_/*.ibd |xargs -n1 basename |cut -d . -f1`) {
			chomp $table;			
			system("/usr/local/mysql/bin/mysql -u $user -p$pass --execute \"SET FOREIGN_KEY_CHECKS=0; ALTER TABLE $_.$table DISCARD TABLESPACE\" 2>/dev/null");
			system("/usr/bin/cp $BKP_FULL_PATH/$BKP_INC_BASE/$_/$table.ibd $MYSQL_LIB/$_");
			system("/usr/bin/cp $BKP_FULL_PATH/$BKP_INC_BASE/$_/$table.exp $MYSQL_LIB/$_");
			system("/usr/bin/chown mysql:mysql $MYSQL_LIB/$_/$table.*");
			system("/usr/local/mysql/bin/mysql -u $user -p$pass --execute \"SET FOREIGN_KEY_CHECKS=0; ALTER TABLE $_.$table IMPORT TABLESPACE\" 2>/dev/null");
			system("/usr/local/mysql/bin/mysql -u $user -p$pass --execute \"ANALYZE TABLE $_.$table\" 2>/dev/null");
			}
		print "
#######################################################
DATABASE $_ RESTAURADA
#######################################################\n
";		
	}
}

exit;
