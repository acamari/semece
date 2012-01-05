#!/usr/bin/env perl
#
# Copyright (c) 2011 Abel Abraham Camarillo Ojeda <acamari@verlet.org>
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

# formats git-log output into a nice markdown text
# Usage:
# git log --name-only --date=iso | gitlog2mkd.pl

use strict;
use warnings;

use File::Basename;

use constant DEBUG	=> 1;
use constant MAXCOMMIT	=> 999999;
# Length of the git hash in characters
use constant GITSHALEN	=> 40;

my $prog	= basename($0); # Current program name
my $hdr		= "#Noticias:\n";
my $git_cr;	# Git commit regex, if a line matches this regex then it's the
		# start of a commit message
my $i		= 0; # Commit counter
my $tmp;

$tmp = sprintf('^commit ([[:digit:]abcdef]{%s})$', GITSHALEN);
$git_cr = qr/$tmp/o;

print $hdr;

$_ = <>; # Reads first line

# Iterates over commits
for ($i = 0; $i < MAXCOMMIT && !eof; $i++) {
	my $commit = {
		hash	=> undef, # Commit hash
		authn	=> "herp", # Author name
		authm	=> "derp", # Author mail
		date	=> undef, # Commit date
		msg	=> undef, # Commit message
		file	=> []	  # changed files
	};

	if ((($commit->{hash}) = /$git_cr/) == 0) {
		die "$prog: does not look like a commit message, stopped";
	}

	while (<>) { # iterate headers, ignores non Author or Date headers
		last if /^$/;
		DEBUG && warn "\$_: $_";
		@{$commit}{qw(authn authm)} = ($1, $2) if /^Author:\s+([^<]+)\s+<([^>]*)>$/;
		$commit->{date} = $1 if /^Date:\s+(.+)$/;
	}
	die "$prog: no 'Date:' header, stopped" unless $commit->{date};
	die "$prog: no 'Author:' header, stopped" unless $commit->{authn};

	while (<>) { # iterate commit msg and commit files
		last if /$git_cr/;
		next if /^$/; # empty line
		if (/^\s+/) { # in git log --name-only commit messages are
				# indented, this marks a commit message start
			$commit->{msg} .= $_;
		} else {
			chomp;
			push @{$commit->{file}}, $_;
		}
	}

	die "$prog: empty commit msg" if not $commit->{msg};

	DEBUG && warn "\$commit = {\n";
	for (qw(hash	
		authn
		authm
		date
		msg
		file)) {
		DEBUG && warn sprintf("\t%s: '%s'\n", 
		       $_, ($commit->{$_} ? $commit->{$_} : ""));
	}
	DEBUG && warn "};\n";

	print <<MARKDOWN;
* ###$commit->{date}: 

$commit->{msg} 
MARKDOWN

	print <<MARKDOWN for @{$commit->{file}};
  [Ir.]($_)
MARKDOWN

}
