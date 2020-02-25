#!/usr/bin/perl

# Network interface status
# Fabio Rodrigues (anfabio@gmail.com)
# Versão 1.1


my $ANSI_TERM = 1;

use Time::HiRes qw(gettimeofday);
use Getopt::Long;

sub collect_stats($);
sub value2human($);

$NET_STATS_FILE = "/proc/net/dev";

GetOptions(
	'help|h' => \$help,
	'interval|i:i' => \$update_interval,
);

if ($help or !($update_interval)) {
	print STDERR "Usage: $0 [(-i|--interval seconds)]\n";
	exit 1;
}

my (%stats_prev, %stats);
collect_stats(\%stats_prev);
my $time_prev = $stats_prev{'time'}{'sec'} + $stats_prev{'time'}{'usec'}/1e6;
print "\e[H\e[2J" if ($ANSI_TERM);
do {
	sleep($update_interval);
	collect_stats(\%stats);
	my $time = $stats{'time'}{'sec'} + $stats{'time'}{'usec'}/1e6;
	my $delta = $time-$time_prev;
	print "\e[H" if ($ANSI_TERM);
	printf("%-6s %10s    %10s   \n", 'if', 'rx', 'tx');
	print "==================================\n";
	for (my $i = 0; $i < scalar(@{$stats{'if'}}); $i++)
	{
		my $row = ${$stats{'if'}}[$i];
		my $row_prev = ${$stats_prev{'if'}}[$i];
		printf("%-6s %10sb/s %10sb/s\n", ${$row}{'if'}, value2human((${$row}{'rx'}-${$row_prev}{'rx'})*8/$delta), value2human((${$row}{'tx'}-${$row_prev}{'tx'})*8/$delta));
		print "----------------------------------\n";
	}
	print "\n" if (!$ANSI_TERM);
	@{$stats_prev{'if'}} = @{$stats{'if'}};
	$time_prev = $time;
} while (1);

sub collect_stats($)
{
	my ($stats) = @_;

	if (!open(STATS, $NET_STATS_FILE))
	{
		die "open: ${NET_STATS_FILE}: $!\n";
	}

	my ($sec, $usec) = gettimeofday;
	%{${$stats}{'time'}} = ( 'sec' => $sec, 'usec' => $usec);
	@{${$stats}{'if'}} = ();
	while (<STATS>)
	{
		if (!/^\s*([^:]+):\s*(.+)$/)
		{
			next;
		}

		my ($if, $rest) = ($1, $2);
		my ($rx, $tx) = (split(/\s+/, $rest))[0, 8];
		push(@{${$stats}{'if'}}, {'if' => $if, 'rx' => $rx, 'tx' => $tx});
	}
	close STATS;
}
#
#	Converts a value into a human value in k, M or G.
#
sub value2human($)
{
	my ($value) = @_;

	if ($value < 1e3)
	{
		return sprintf("%.2f  ", $value);
	}
	elsif ($value < 1e6)
	{
		return sprintf("%.2f k", $value/1e3);
	}
	elsif ($value < 1e9)
	{
		return sprintf("%.2f M", $value/1e6);
	}
	else
	{
		return sprintf("%.2f G", $value/1e9);
	}
}
