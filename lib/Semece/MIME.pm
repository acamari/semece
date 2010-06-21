package Semece::MIME;

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

use strict;
use warnings;

use MIME::Types;

# Default MIME type
my $def_t	= "application/octect-stream"; # If I cannot got correct MIME
my $types	= undef;	# MIME::Types object (note 'Types' vs 'Type')

$types = MIME::Types->new();
die "I cannot init MIME::Types->new()!, $!, stopped" unless $types;

# gets the MIME type corresponding to a $filename, $filename doesn't need to
# exist, returns a string
# ex: mime_t("lol.pdf") -> 'application/pdf'
sub
mime_t
{
	my $f		= shift; # filename
	
	my $m		= undef; # MIME::Type object
	my $r		= undef; # MIME type get (example: $r = 'text/plain')

	$m = $types->mimeTypeOf($f);

	if ($m) {
		$r = $m->type();
	} else {
		$r = $def_t;
	}
	print STDERR "mime_t($f) = $r;\n";

	return $r;
}

1;
