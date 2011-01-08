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

my $debug	= undef; # References a Semec::Debug object
# Default MIME type
my $fb_mime	= "application/octect-stream"; # Fallback MIME Type
my $types	= undef; # MIME::Types object (note 'Types' vs 'Type')
my $mkd_sufx	= [];	# Suffix for markdown files
my $mkd_t	= undef; # MIME::Type object for markdown files

$types = MIME::Types->new() or
    die "I cannot init MIME::Types->new()!, $!, stopped"; 

# Configurates our MIME module, currently it stablishes what extension is the
# default for markdown files, returns true if all is OK, undef in case of error.
sub
conf
{
	my $conf	= shift; # Semece configuration object

	$debug = $Semece::debug;

	return unless $conf->{mkd_sufx} or $conf->{mkd_ct};
	$mkd_t = MIME::Type->new(type => 'text/plain',
				 extensions => [$conf->{mkd_sufx}]);
	$types->addType($mkd_t);
	return 1;
}

# Gets the MIME type corresponding to a $filename, $filename doesn't need to
# exist, returns a MIME type as string if everything is OK. Returns undef
# otherwise.
# ex: mime_t("lol.pdf") -> 'application/pdf'
sub
mime_t
{
	my $f		= shift; # filename
	
	my $m		= undef; # Temporary MIME::Type object
	my $r		= undef; # MIME type get (example: $r = 'text/plain')

	$debug->prntf("mime_t: arg '%s';\n", $f);
	$m = $types->mimeTypeOf($f);

	if ($m) {
		$r = $m->type();
	} else {
		$r = $fb_mime;
	}
	$debug->prntf("mime_t: ret '%s';\n", $r);

	return $r;
}

1;
