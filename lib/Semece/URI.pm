package Semece::URI;
# Copyright (c) 2010 Abel Abraham Camarillo Ojeda <acamari@verlet.org>
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

# Get uri: Receives an URI has an argument, it returns the same URI but
# normalized, or return; if there is no argument. Currently the normalization
# process consists on making sure that all trailing slashes aren't duplicated.
sub
norm
{
	my $uri		= shift;	# stores normalized uri

	$Semece::debug->prntf("g_uri: da uri (%s)\n", 
	    defined($uri) ? $uri : "") or 
		die "I couldn't prntf()!; $!; stopped";
	return unless $uri;

	$uri =~ s!/+!/!g;	# normalization

	return $uri;
}
