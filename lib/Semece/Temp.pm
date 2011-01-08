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

# opts:
#	based		=> Base directory
#	content		=> Text to put in #content
#	mkurl		=> markdown source url
sub
temp
{
	my %opts	= @_;

	my $html	= undef;

	croak "\$opts{'based'} doesn't exist!, stopped" 
	    unless exists $opts{'based'};
	croak "\$opts{'content'} doesn't exist!, stopped" 
	    unless exists $opts{'content'};
	croak "\$opts{'mkurl'} doesn't exist!, stopped" 
	    unless exists $opts{'mkurl'};

	$opts{'head'} = "" unless $opts{'head'};
	$opts{'based'} = "" if $opts{based} eq '/';

	$html = <<HTML;
<!DOCTYPE html>
<html lang="es">
<head>
<title>SeNTX</title>
<link rel="stylesheet" type="text/css" href="$opts{based}/static/css/semece.css" />
<script src="$opts{based}/static/js/Hyphenator.js" type="text/javascript">
</script>  
<script type="text/javascript">
	Hyphenator.run();
</script>
$opts{head}
</head>
<body class="hyphenate">
<div id="container"> 
	<div id="banner">
	<h1> #SeNTX </h1>
	</div><!-- #banner -->
	<div id="menu">
	$opts{menu}
	</div><!-- #menu -->
	<div id="content">
	$opts{content}
	--<br />
	<div id="footer">
	Para ver el código fuente de esta página entre
	<a href="$opts{mkurl}">aquí</a>.
	</div><!-- #footer -->
	</div><!-- #content -->
</div><!-- #container -->
</body>
</html>
HTML

	return $html;
}

1;
