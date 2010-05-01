package Semece::Tool;

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

# Stores common functions

use Carp;

# get uri
# normalize an url
sub
g_uri
{
	my $q		= shift;

	my $uri		= undef;	# stores normalized uri
$uri = $q->uri; $uri =~ s!/+!/!g;	# normalization

	print STDERR "g_uri: da uri (", $uri, ")\n";

	return $uri;
}

# get short uri
# get $q->uri minus $q->location
sub
g_suri
{
	my $q		= shift;

	my $uri		= undef;	# stores short uri

	$uri = substr $q->uri, (length &g_location($q));
	$uri =~ s!/+!/!g;	# normalization

	print STDERR "g_suri: da suri (", $uri, ")\n";

	return $uri;
}

# returns the postd (fs directory where the posts are)
sub
g_postd
{
	my $q		= shift;

	# reads SemecePostd from apache configuration
	if (my $tmp = $q->dir_config('SemecePostd')) {
		# sends directory names without final slash
		$tmp =~ s!/+$!!;	
		return $tmp;
	} else {
		print STDERR "keys:", (join(',', keys %ENV)), "\n";
		croak "I cannot get SemecePostd, stopped";
		return undef;	# NOTREACHED
	}
	# NOTREACHED
}


# returns the <Location > from the apache conf
sub
g_location
{
	my $q		= shift;


	# reads Current Working Dir from apache configuration
	if (my $tmp = $q->location) {
		print STDERR "g_location: location ($tmp)\n";
		# sends directory names without final slash
		$tmp =~ s!/+$!!;	
		return $tmp;
	} else {
		croak "I cannot get Location, stopped";
		return undef;	
		# NOTREACHED
	}
	# NOTREACHED
}

1;
