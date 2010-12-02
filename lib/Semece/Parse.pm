package Semece::Parse;

# Copyright (c) 2010 Abel Abraham Camarillo Ojeda <acamari@the00z.org>
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

# Currently parses a markdown file previously expanding some macros
# and returns the parsed markdown file
use Semece::Sublatex; 
use Semece::Markdown; 

sub
parse
{
	my $q		= shift;	# Apache::Request object
	my $in		= shift;	# input text

	my $out		= undef;	# output text
	
	$out = $in;

	# XXX: Use a hash of macro -> expansion
	$out =~ s!\$%!&Semece::Tool::g_location($q)!ge;

	# Parse sublatex code
	$out = &Semece::Sublatex::sublatex($out);
	$out = &Semece::Markdown::markdown($out);
	return $otxt;
}

1;
