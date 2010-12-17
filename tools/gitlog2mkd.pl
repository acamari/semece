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
	my $commit = {
		hash	=> undef, # Commit hash
		authn	=> undef, # Author name
		authm	=> undef, # Author mail
		date	=> undef, # Commit date
		msg	=> undef, # Commit message
		file	=> undef  # First changed file
	};

	if (not scalar(($commit->{hash}) = /$git_cr/)) {
		die sprintf("This doesn't look like a commit message!, ".
		            "stopped at %s line %s; reading %s line %s.\n",
			    $progn, __LINE__, $ARGV, $.);
	} elsif (not scalar(($commit->{authn}, $commit->{authm}) 
			    = <> =~ /^Author:\s+([^<]+)<([^>]*)>$/)) {
		die sprintf("This doesn't look like an 'Author:' line!, ".
		            "stopped at %s line %s; reading %s line %s.\n",
			    $progn, __LINE__, $ARGV, $.);
	} elsif (not scalar(($commit->{date}) = <> =~ /^Date:\s+(.+)$/)) {
		die sprintf("This doesn't look like a 'Date:' line!, ".
		            "stopped at %s line %s; reading %s line %s.\n",
			    $progn, __LINE__, $ARGV, $.);
	}

	# Iterating over a single commit
	while (<>) {
		last if /$git_cr/;
		if(/^\s+/){
			$commit->{msg} .= $_;
		}elsif(!$commit->{file} && /^\w/){
			chomp;
			$commit->{file} = $_;
		}
	}

	for (sort keys %$commit) {
		printf(STDERR "\$%s: %s\n", 
		       $_, ($commit->{$_} ? $commit->{$_} : ""));
	}

	if ($commit->{file}) {
		printf(STDERR "\$file: $commit->{file}\n");
	}

	if (not $commit->{msg}) {
		die sprintf("Empty commit msg!, ".
		            "stopped at %s line %s; reading %s line %s.\n",
			    $progn, __LINE__, $ARGV, $.);
	}

	print <<EOF;
* ###$commit->{date}: 

$commit->{msg} 

\t[Ir.]($commit->{file})

EOF

}
