#!/usr/bin/perl

use ZabbixAPI;
use DateTime

my $counter=1;
my $zab=ZabbixAPI->new("http://zabbixserver/zabbix/");
$zab->login("afrs_ad","senha);

my $events=$zab->event_get(
        {
                output => 'extend',
                selectHosts => 'extend',
                selectTriggers => 'extend',
                value => 1,
                limit => 20
        }
);

for my $event (@$events) {
        my $dt=DateTime->from_epoch(epoch => $event->{clock});
        my $timestamp=$dt->day." ".$dt->month." ".$dt->year." ".$dt->hour.":".$dt->minute.":".$dt->second;

        print "Host: ".${$event->{hosts}}[0]->{name}." Issue: ".${$event->{triggers}}[0]->{description}." Last change: ".$timestamp."\n"; 
}
