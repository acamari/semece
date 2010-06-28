package Semece::Sublatex;

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
#

use utf8;

use strict;
use warnings;

# sublatex: 
#
# Unicode code points from the Unicode Standard
# (http://www.unicode.org/charts/PDF/U0080.pdf)
#
# \A	LATIN CAPITAL LETTER A WITH ACUTE;	U+00C1
# \a	LATIN SMALL LETTER A WITH ACUTE;	U+00E1
# \:A	LATIN CAPITAL LETTER A WITH DIAERESIS;	U+00C4
# \:a	LATIN SMALL LETTER A WITH DIAERESIS;	U+00E4
# \E	LATIN CAPITAL LETTER E WITH ACUTE;	U+00C9
# \e	LATIN SMALL LETTER E WITH ACUTE;	U+00E9
# \:E	LATIN CAPITAL LETTER E WITH DIAERESIS;	U+00CB 
# \:e	LATIN SMALL LETTER E WITH DIAERESIS;	U+00EB 
# \I	LATIN CAPITAL LETTER I WITH ACUTE;	U+00CD
# \i	LATIN SMALL LETTER I WITH ACUTE;	U+00ED
# \:I	LATIN CAPITAL LETTER I WITH DIAERESIS;	U+00CF 
# \:i	LATIN SMALL LETTER I WITH DIAERESIS;	U+00EF 
# \N	LATIN CAPTIAL LETTER N WITH TILDE;	U+00D1
# \n	LATIN SMALL LETTER N WITH TILDE;	U+00F1
# \O	LATIN CAPITAL LETTER O WITH ACUTE;	U+00D3
# \o	LATIN SMALL LETTER O WITH ACUTE;	U+00F3
# \:O	LATIN CAPITAL LETTER O WITH DIAERESIS;	U+00D6 
# \:o	LATIN SMALL LETTER O WITH DIAERESIS;	U+00F6 
# \U	LATIN CAPITAL LETTER U WITH ACUTE;	U+00DA
# \u	LATIN SMALL LETTER U WITH ACUTE;	U+00FA
# \:U	LATIN CAPITAL LETTER U WITH DIAERESIS;	U+00DC
# \:u	LATIN SMALL LETTER U WITH DIAERESIS;	U+00FC
# \?	INVERTED QUESTION MARK;			U+00BF
# \!	INVERTED EXCLAMATION MARK;		U+00A1
# \<	RIGHT-POINTING DOUBLE ANGLE QUOTATION;	U+00AB
# \<	LEFT-POINTING DOUBLE ANGLE QUOTATION;	U+00BB

my $debug = 0;

my $magic	= chr(0x0);	# a str can never come with '\n' so we
				# use it as magical placeholder

# this expands to a single \ in a m/$esc/
# backslash ascii character
my $esc = chr(0x5c);

# the keys in this hash are chars that appear after a $escape_char
my %latextou		= ();

%latextou =  (
	'A'	=> "\N{U+00C1}",
	'a'	=> "\N{U+00E1}",
	':A'	=> "\N{U+00C4}",
	':a'	=> "\N{U+00E4}",
	'E'	=> "\N{U+00C9}",
	'e'	=> "\N{U+00E9}",
	':E'	=> "\N{U+00CB}",
	':e'	=> "\N{U+00EB}",
	'I'	=> "\N{U+00CD}",
	'i'	=> "\N{U+00ED}",
	':I'	=> "\N{U+00CF}",
	':i'	=> "\N{U+00EF}",
	'N'	=> "\N{U+00D1}",
	'n'	=> "\N{U+00F1}",
	'O'	=> "\N{U+00D3}",
	'o'	=> "\N{U+00F3}",
	':O'	=> "\N{U+00D6}",
	':o'	=> "\N{U+00F6}",
	'U'	=> "\N{U+00DA}",
	'u'	=> "\N{U+00FA}",
	':U'	=> "\N{U+00DC}",
	':u'	=> "\N{U+00FC}",
	'\?'	=> "\N{U+00BF}",
	'!'	=> "\N{U+00A1}",
	'<'	=> "\N{U+00AB}",
	'>'	=> "\N{U+00BB}",
);

sub 
sublatex 
{
	my $str		= shift;

	my $dst		= undef;
	my $i		= 0;
	my $q		= undef;

	$str =~ s!$esc$esc$esc$esc!$magic!g;
	while (my ($k, $v) = each %latextou) {
		$str =~ s!$esc$esc$k!$v!g;
	}
	$str =~ s!$magic!$esc!g;

	$dst = $str;

	return $dst;
}

# returns the hexdump of a string
sub 
hdump 
{
	my $str 	= shift;
	my $r 		= undef;
	
	$r = "";

	use bytes;
	$r .= sprintf("%x", ord($_)) for split "", $str;
	no bytes;

	return $r;
}

1;
