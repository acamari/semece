#!/usr/bin/env perl

#Usage:
# git log --name-only --date=short | gilog2mkd.pl

use strict;
use warnings;

use constant MAXCOMMIT => 10;
# Length of the nit hash in characters
use constant GITSHALEN => 40;

my $progn	= $0; # Current program name
my $hdr		= "#Noticias:\n";
my $git_cr	= undef; # Git commit regex, if a line matches this regex then
			 # it's the start of a commit message
my $i		= 0; # Commit counter
my $tmp		= undef;

$tmp = sprintf('^commit ([[:digit:]abcdef]{%s})$', GITSHALEN);
$git_cr = qr/$tmp/o;

print $hdr;

$_ = <>; # Reads first line

# Iterates over commits
for ($i = 0; $i < MAXCOMMIT && !eof; $i++) {
	my $hash	= undef; # Commit hash
	my $authn	= undef; # Author name
	my $authm	= undef; # Author mail
	my $date	= undef; # Commit date
	my $msg		= undef; # Commit message
	my $file	= undef; # First changed file

	if (not scalar(($hash) = /$git_cr/)) {
		die sprintf("This doesn't look like a commit message!, ".
		            "stopped at %s line %s; reading %s line %s.\n",
			    $progn, __LINE__, $ARGV, $.);
	} elsif (not scalar(($authn, $authm) 
			    = <> =~ /^Author:\s+([^<]+)<([^>]*)>$/)) {
		die sprintf("This doesn't look like an 'Author:' line!, ".
		            "stopped at %s line %s; reading %s line %s.\n",
			    $progn, __LINE__, $ARGV, $.);
	} elsif (not scalar(($date) = <> =~ /^Date:\s+(.+)$/)) {
		die sprintf("This doesn't look like a 'Date:' line!, ".
		            "stopped at %s line %s; reading %s line %s.\n",
			    $progn, __LINE__, $ARGV, $.);
	}

	# Iterating over a single commit
	while (<>) {
		last if /$git_cr/;
		if(/^\s/){
			/^\s(.*?)/;
			$msg .= $_ ;
		}elsif(!$file){
			chomp;
			$file = $_;
		}
	}

	printf(STDERR "\$hash: $hash\n");
	printf(STDERR "\$authn: $authn\n");
	printf(STDERR "\$authm: $authm\n");
	printf(STDERR "\$date: $date\n");
	printf(STDERR "\$msg: $msg\n");
	if($file){
		printf(STDERR "\$file: $file\n");
	}

	if (not $msg) {
		die sprintf("Empty commit msg!, ".
		            "stopped at %s line %s; reading %s line %s.\n",
			    $progn, __LINE__, $ARGV, $.);
	}

	chomp $date;
	print <<EOF
  *$date: $msg [Ir.][$file]
EOF
;
}
