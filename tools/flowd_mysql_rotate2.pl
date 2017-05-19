#!/usr/bin/perl
#
# Copyright (c) 2004 Damien Miller <djm@mindrot.org>
# Copyright (c) 2012 Jethro Carr <jethro.carr@jethrocarr.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#
# This script reads in the record log file written by flowd and imports
# it into MySQL and rotates the log file in a flowd-friendly way.
#

use strict;
use warnings;

use DBI;
use Flowd;
use File::Copy;

# Database settings
my $DBI_DRIVER =	"mysql"; # or one of "Pg" "mysql" "mysqlPP" 
my $DB =		"netflow";
my $TABLE =		"traffic";
my $USER =		"netflow";
my $PASS =		"netflow";

die "Usage: flowd_mysql_rotate.pl [flowd-log]\n" unless (@ARGV);

my $db = DBI->connect("dbi:$DBI_DRIVER:dbname=$DB", $USER, $PASS)
	or die "DBI->connect error: " . $DBI::errstr;

for (my $i = 0; $i < scalar(@ARGV); $i++) {
	my $flow_log 		= $ARGV[$i];
	my $flow_log_import	= $flow_log .".import";

	print "Processing flow log $flow_log...\n";
	copy($flow_log, $flow_log_import);
	truncate($flow_log, 0);

	my $flow_handle = Flowd->new($flow_log_import);

	while (my $flow = $flow_handle->read_flow()) {
		my $tag = $flow->{tag};
		$tag = 0 unless defined $tag;

#		print $flow->format(Flowd::Flow::BRIEF, 0) . "\n";

		my $query = sprintf( "INSERT INTO $TABLE ".
		    "(time_sec, agent_addr, src_addr, src_as, dst_addr, dst_as, ".
		    " src_port, dst_port, octets, packets, protocol, tcp_flags, tos, if_index_in, if_index_out) VALUES ".
		    "(%s, %s, %s, %u, %s, %u, %u, %u, %u, %u, %u, %u, %u, %u, %u)" ,
		    $db->quote(Flowd::iso_time($flow->{time_sec})),
		    $db->quote($flow->{agent_addr}), 
		    $db->quote($flow->{src_addr}), 
		    $flow->{src_as},
		    $db->quote($flow->{dst_addr}),
		    $flow->{dst_as},
		    $flow->{src_port},
		    $flow->{dst_port},
		    $flow->{flow_octets},
		    $flow->{flow_packets},
		    $flow->{protocol},
		    $flow->{tcp_flags},
		    $flow->{tos},
		    $flow->{if_index_in},
		    $flow->{if_index_out} );

#		print "$query\n";
		$db->do($query) or die "db->do failed: " . $DBI::errstr;
	}
	$flow_handle->finish();

	unlink($flow_log_import);
}
