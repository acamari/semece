package Semece::Debug;

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
# Semece::Debug: Prints messages on stderr if we are on debugging mode, does
# nothing if we are not.

use strict;
use warnings;

# Creates a new empty object and sets debugging to false, by default.
# This method blesses a hash on the current Package name (class).
sub
new
{
	my $class	= shift;

	my $self	= {}; # Empty object (hashref)

	$self->{isdebug} = 0;

	return bless $self, $class;
}
	
	
# Sets debugging flag. It can receive one argument, a boolean set to true if we
# are on debugging mode or false if we are not. If this function don't receives
# an argument (or receives an undef argument) it does not set any value. This
# function always returns the value of the current debugging flag.
sub
isdebug
{
	my $self	= shift;
	my $arg		= shift;

	if (defined $arg) {
		$self->{isdebug} = $arg;
	}

	return $self->{isdebug};
}

# Debugging print, print() wrapper. Prints only if isdebug is true. Returns true
# if isdebug is true and it could print, undef otherwise.
sub
prnt
{
	my $self	= shift;

	my $tmp		= undef; # Stores print() return value

	if ($self->isdebug) {
		if (not $tmp = print STDERR @_) {
			die "I couldn't print(@_)!, $!, stopped";
		}
	} else {
		return undef;
	}
}

# Debugging print, printf() wrapper. Prints only if isdebug is true. Returns
# true if it could print, false otherwise.
sub
prntf
{
	my $self	= shift;

	my $tmp		= undef;

	if ($self->isdebug) {
		if (not $tmp = printf STDERR @_) {
			die "I couldn't print(@_)!, $!, stopped";
		}
	} else {
		return undef;
	}
}

1;
