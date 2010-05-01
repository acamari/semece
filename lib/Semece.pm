package Semece;

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

# nomenclature:
# 'markdown'	= Source code file of a post.
# 'post'	= The HTML code generated from a 'markdown' file
use strict;
use warnings;

use utf8;

use open IO => ':utf8';

use Carp; 

use CGI qw(:standard);
use Apache::Constants qw(:response :http);
use Apache::Request;
use File::Find;
use Text::Markdown qq(markdown);

use Semece::Conf;
use Semece::Temp;

my $cthtml	= "text/html; charset=UTF-8";
my $ctplain	= "text/plain; charset=UTF-8";

my $mk_sufx	= $Semece::Conf::mk_sufx;

# default handler
sub
handler
{
	my $r		= shift;	# Apache request
	my $q		= Apache::Request->new($r);	# libapreq object

	return &serv($q);
}

# sends a fucken 301
sub
rdr
{
	my $q		= shift;
	my $uri		= shift;	# where to 301'

	print STDERR "rdr (", REDIRECT, ")\n";
	$q->custom_response(REDIRECT, $uri);

	return REDIRECT;
}

# serves a user
sub
serv
{
	my $q		= shift;

	my $uri		= undef;

	print STDERR "serv: da old uri = (", $q->uri, ")\n";

	$uri = &g_suri($q);

	if ($uri =~ m!^/post/(.*)?$!) {
		print STDERR "entering p_post;\n";
		return &p_post($q);	# prints a post
	} elsif ($uri =~ m!^/static(/.*)?$!) {
		# give the user what he requested
		return DECLINED;
	} else {
		# the user send a uri that i don't know what to do with
		# (send he to the post dir)

		print STDERR "301'ing;\n";
		return &rdr($q, (&g_location($q). "/post/"));
	}
}

# get uri
# normalize an url
sub
g_uri
{
	my $q		= shift;

	my $uri		= undef;	# stores normalized uri

	$uri = $q->uri;
	$uri =~ s!/+!/!g;	# normalization

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

# get markdown uri
# gets the uri of a markdown file, corresponding to a post
# g_mk_u($posturi) -> $markdown_uri
sub
g_mk_u
{
	my $q		= shift;

	my $uri		= undef;

	$uri = &g_uri($q);

	print STDERR "g_mk_u: in = (", $uri , ")\n";

	# XXX: markdown obtention heuristics...
	if ($uri =~ m!/$!) {
		# if he requested a directory
		# returns an index.mkd in that directory
		# in '/post/lol/' -> '/post/lol/index.mkd'
		print STDERR "g_mk_u: out = (", $uri.  "index". $mk_sufx,
		      ")\n";
		return $uri. "index". $mk_sufx;
	} else {
		# if you requested something else
		# ej: if /post/helloworld returns /post/helloword.mkd 
		print STDERR "g_mk_u: out = (", $uri. $mk_sufx, ")\n";
		return $uri. $mk_sufx;
	}
	# NOTREACHED
}

# get markdown path
# gets the absolute *filesystem* path of a post (.markdown) using only the uri
sub
g_mk_p
{
	my $q		= shift;

	my $postd	= undef;	# fs dir where are the posts
	my $uri		= undef;

	$postd = &g_postd($q);
	$uri = &g_suri($q);

	# stripp of /post prefix from uri
	$uri =~ s!^/post/?!/!;

	print STDERR "g_mk_p: postd = (", $postd , ")\n";
	print STDERR "g_mk_p: uri = (", $uri , ")\n";

	# XXX: markdown obtention heuristics...
	# XXX: we do the fucking uri -> filename translation here... nasty
	if ($uri =~ m!/$!) {
		# if he requested a directory
		# see if there exits index.mkd in that directory
		print STDERR "g_mk_p: path = (", $postd. "/". $uri. "/". 
			"index". $mk_sufx, ")\n";
		if (-e ($postd. "/". $uri. "/". "index". $mk_sufx)) {
			return $postd. "/". $uri. "/". "index". $mk_sufx;
		} else {
			return undef;
		}
	} elsif ($uri !~ m!\..+$!) {
		# if you requested something without prefix
		# see if there exists an according markdown
		# ej: if /post/helloworld check if /post/helloword.mkd exists
		print STDERR "g_mk_p: path = (", $postd. "/". $uri. "/".
			$mk_sufx, ")\n";
		if (-e ($postd. "/". $uri. $mk_sufx )) {
			return $postd. "/". $uri. $mk_sufx;
		} else {
			# returns a file with that name... if it exists
			return undef;
		}
	} else {
		# if you requested something with prefix 
		# do uri -> filename translation and return the corresponding
		# shit, to this request
		print STDERR "g_mk_p: path_info = (", $q->path_info(undef), ")\n";
		print STDERR "g_mk_p: path = (", ($postd. $uri), ")\n";

		$q->filename($postd. $uri);
		return undef;
	}
	# NOTREACHED
}

	
# generate menu
# returns a hash ref
sub
gen_menu
{
	my $q		= shift;
	my $dir		= shift;	# directory to root menu in

	my $html	= undef;
	my %menu	= ();	# menu to return
	my @tmp		= ();	# tmp tree hierarchy

	print STDERR "gen_menu: dir = ($dir)\n";

	$dir =~ s!/+$!!g;

	find(sub {
		my $name	= undef;

		return if $_ eq '.' or $_ eq '..';

		$name = $File::Find::name; 
		$name .= "/" if -d $name;
		$name =~ s!/+$!/!;

		push @tmp, $name;
	}, ($dir));

	# XXX: menu generation heuristics
	%menu = 
	    # adds a pretty leading slash	
	    map {("/$_", &g_location($q). "/post/$_")} 
	    # strips all .mkd
	    map {s/$mk_sufx$//; $_}
	    # if you see a file called /dir/index.mkd just show /dir/
	    map {s!(^|/)index$mk_sufx$!$1!; $_}
	    # show only markdown files
	    grep {m!$mk_sufx$!}
	    # removes top dir name
	    map {$_ = substr $_, (length $dir); s!^/+!!; $_} @tmp;

	print STDERR "gen_menu: superhier k = (", (join ' ', keys %menu), ")\n";
	print STDERR "gen_menu: superhier v = (", (join ' ', values %menu), ")\n";

	print STDERR "gen_menu: hier = (", join (', ', sort @tmp), ")\n";

	$html = '<ul id="menu">'. 
		(join ('', 
		map {qq!<li id="menu">$_</li><br />\n!}
		map {if ($q->uri eq $menu{$_}) { 
			qq!$_<span class="here"> _</span>!;
			} else {qq!<a href="$menu{$_}">$_</a>!}}
		 sort keys %menu)). '</ul>';
	return $html;

}

# prints post
# prints a post page (template + markdown content)
sub
p_post
{
	my $q		= shift;

	my $fd		= undef;	# file descriptor
	my $post	= undef;	# post (.markdown) to show

	$post = &g_mk_p($q);

	print STDERR "p_post: uri(", $q->uri , ")\n";
	print STDERR "p_post: post(", ($post ? $post : ""), ")\n";

	return DECLINED unless $post; # i couldn't find a filename

	open $fd, "<", $post or croak "$!, stopped";

	$q->content_type($cthtml);
	$q->send_http_header();

	# if you requested the parsing of a markdown	
	print &Semece::Temp::temp(based => &g_location($q), 
			menu	=> &gen_menu($q, &g_postd($q)),
			content => (markdown(join '', <$fd>)),
			mkurl	=> &g_mk_u($q));
	return OK;
}

1;
