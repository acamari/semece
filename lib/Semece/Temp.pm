package Semece::Temp;

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

use utf8;
use strict;
use warnings;

use Carp; 

sub
temp
{
	my %opts	= @_;

	my $html	= undef;

	croak "\$opts{'based'} doesn't exist!, stopped" 
	    unless exists $opts{'based'};
	croak "\$opts{'content'} doesn't exist!, stopped" 
	    unless exists $opts{'content'};

	$opts{'head'} = "" unless $opts{'head'};

	$html = <<HTML;
<!DOCTYPE html>
<html>
<head>
<title>SeNTX</title>
<link rel="stylesheet" type="text/css" href="$opts{based}/static/css/semece.css" />
$opts{head}
</head>
<body>
<div id="container">
	<div id="banner">
	<h1> #SeNTX </h1>
	</div><!-- #banner -->
	<div id="menu">
	$opts{menu}
	</div><!-- #menu -->
	<div id="content">
	$opts{content}
	</div><!-- #content -->
</div><!-- #container -->
</body>
</html>
HTML

	return $html;
}

1;
