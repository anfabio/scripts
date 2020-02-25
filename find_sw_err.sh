#!/bin/bash

# Find err_disable port on cisco switches using expect

if [ "$1" = "" ] || [ "$2" = "" ] 
then
	echo "Informar usuário e senha no mínimo.
Usage: find_sw_err username password \"string de busca\" \"Switches\"
Ex: find_sw_err.sh afrs pass err 8AND"
	exit
else
echo "Usage: find_sw_err username password \"string de busca\" \"Switches\"
Ex: find_sw_err.sh afrs pass err 8AND"
fi

user=$1
pass=$2
string=$3
andar=$4


# Busca normal
if [ "$andar" != "" ] && [ "$string" != "" ]
then
echo "Busca Normal"
# SSH
for host in `cat sw_ips | grep -v NOT | grep SSH | grep -i $andar | cut -f1`
do
echo $host
echo ================================================
./ex_ssh $host $user $pass | grep -i $string
echo
done

# Telnet
for host in `cat sw_ips | grep -v NOT | grep -v SSH | grep -i $andar |cut -f1`
do
echo $host
echo ================================================
./ex_tel $host $user $pass | grep -i $string
echo
done

exit
fi


# Busca TUDO em TODOS
if [ "$string" = "" ]
then 
echo "Mostra TUDO em TODOS os SW"
# SSH
for host in `cat sw_ips | grep -v NOT | grep SSH | cut -f1`
do
echo $host
echo ================================================
./ex_ssh $host $user $pass
echo
done

# Telnet
for host in `cat sw_ips | grep -v NOT | grep -v SSH | cut -f1`
do
echo $host
echo ================================================
./ex_tel $host $user $pass
echo
done
exit
fi


# Busca TUDO em Andares
if [ "$string" != "" ]
then
echo "Busca String de busca em TODOS os SW"
# SSH
for host in `cat sw_ips | grep -v NOT | grep SSH | cut -f1`
do
echo $host
echo ================================================
./ex_ssh $host $user $pass | grep -i $string
echo
done

# Telnet
for host in `cat sw_ips | grep -v NOT | grep -v SSH | cut -f1`
do
echo $host
echo ================================================
./ex_tel $host $user $pass | grep -i $string
echo
done
exit

fi
