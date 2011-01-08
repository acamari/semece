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
use Carp; 
use Encode;

# Sets all streams to utf-8.
use open OUT => ':utf8';

use HTTP::Status qw(:constants :is);

use Semece::Debug;
#use Semece::Conf;
use Semece::MIME;
#use Semece::Parse;
use Semece::Temp;
#use Semece::Tool;

our $debug	= undef; # Semece::Debug object.
$debug = Semece::Debug->new or die "I couldn't Semece::Debug->new()!, stopped";
$debug->isdebug(1) or die "I couldn't isdebug(), stopped"; # Starts debugging

my $conf	= undef;


# Serves a user: first semece entry point, currently, distinguish if we are
# going to serve an static file or we are going to parse some markdown.
# This function returns a proper PSGI request when Ok, dies when there is an
# (unrecovereable) error.
sub
serv
{
	my $r		= shift; # Initial PSGI request.

	my $uroot; # Root of the uri paths ("location" on server docs)
	my $uri;  # The uri that the client requested
	my $suri; # Short uri: uri minus location.
	my $fs; # Filesystem path corresponding to a $suri.

	# Normalize paths, ensures that there aren't empty vars or duplicated
	# slashes, but at least one starting slash
	for my $path (@{$r}{qw(SCRIPT_NAME PATH_INFO REQUEST_URI)}) {
		$path = '/' unless $path;
		$path = '/'. $path unless $path =~ m!^/!;
		$path = strip_traslash($path);
	}
	$uroot = $r->{SCRIPT_NAME};
	$uri   = $r->{PATH_INFO};

	$debug->prntf("serv: \$r = {\n");
	for (sort keys %$r) {
		$debug->prntf("serv:\t'%s' => '%s'\n", $_, ($r->{$_} ? $r->{$_} : ""));
	}
	$debug->prntf("serv: };\n");

	$debug->prntf("serv: call \$conf = check_conf('%s')\n", $r->{"semece.conf"}); 
	$conf	= check_conf($r->{"semece.conf"});
	$debug->prntf("serv: \$conf = {\n");
	for (sort keys %$conf) {
		$debug->prntf("serv:\t'%s' => '%s'\n", $_, $conf->{$_});
	}
	$debug->prntf("serv: };\n");
	&Semece::MIME::conf($conf); # Syncs configuration

	$debug->prntf("serv: call \$suri = g_relpath('%s', '%s')\n", 
	    $uroot, $uri);
	if (not $suri = &g_relpath($uroot, $uri)) {
		die "I couldn't g_relpath()!; stopped";
	} elsif (not $suri = strip_traslash($suri)) {
		die "I couldn't strip_traslash()!; stopped";
	}
	$debug->prntf("serv: \$suri = '%s'\n", $suri);

	$debug->prntf("serv: call \$fs = uri2fs('%s')\n", $suri);
	if (not $fs = uri2fs($suri)) {
		die "I couldn't uri2fs()!; stopped";
	} elsif (not $fs = compress_p($fs)) {
		die "I couldn't compress_p()!; stopped";
	} elsif ($fs !~ m!^/!) {
		die "\$fs ($fs) must be an absolute path!, stopped";
	} elsif ($fs =~ /\.\./) { 
		die "\$fs ($fs) must not include parent dir references ".
		    "(..)!, stopped";
	}
	$debug->prntf("serv: \$fs = '%s'\n", $fs);

	# File printing heuristics: first we try to serve things that the user
	# explicity requested, if we can't find them, then we try to guess what
	# the user meant, if we can't still find them, then sends error to user.
	if (-f $fs and -r $fs) { # The user requested a regular existing file, and it's
				 # readable
		$debug->prntf("serv: call show_f(%s).\n", $fs);
		return show_f($fs);
	} elsif (-f $fs) { # File isn't readable
		$debug->prntf("serv: ret HTTP_INTERNAL_SERVER_ERROR; ".
		              "\$fs = (%s)\n", $fs);
		return [
		    HTTP_INTERNAL_SERVER_ERROR,
		    ["Content-Type" => $conf->{plain_ct}],
		    [sprintf("ERROR: File '%s' isn't readable!", $fs)]
		];
	} elsif (-d $fs and (!-r $fs or !-x $fs)) {	# File requested is a
							# directory and it isn't
							# readable
		$debug->prntf("serv: ret HTTP_INTERNAL_SERVER_ERROR; ".
			      "\$fs = (%s)\n", $fs);
		return [
		    HTTP_INTERNAL_SERVER_ERROR,
		    ["Content-Type" => $conf->{plain_ct}],
		    [sprintf("ERROR: Directory '%s' isn't readable!", $fs)]
		];
	} elsif (isstatic($suri)) { # Heuristics for directories under /static
		if (-d $fs) {
			$debug->prntf("serv: call show_d(dir => '%s', ".
					                "uri => '%s').\n", 
							$fs, $suri);
			return show_d(dir => $fs, 
			              uri => $suri);
		} else {
			$debug->prntf("serv: ret (static) HTTP_NOT_FOUND; ".
			              "\$fs = (%s).\n", $fs);
			return [
			    HTTP_NOT_FOUND, 
			    ["Content-Type" => $conf->{plain_ct}], 
			    [sprintf("ERROR: File '%s' doesn't exist!", $fs)]
			];
		}
	} elsif (-d $fs and -f $fs. "/". $conf->{mkd_idx}) {	
		# If the user requested a directory in the postd and under that
		# directory exists a regular file named $conf->{idx} (ex.
		# 'index.mkd')
		$debug->prntf("serv: call show_ffmt(file => '%s', ".
						   "uri => '%s');\n", 
						   $fs. "/". $conf->{mkd_idx},
						   $uri);
		return show_ffmt(file => $fs. "/". $conf->{mkd_idx},
				 uri  => $uri);
	} elsif (-d $fs and -d $fs. "/". $conf->{mkd_idx}) { 
		# If the user requested a directory and under that directory
		# exists a directory named $conf->{idx} (ex. 'index.mkd/')
		$debug->prntf("serv: call show_dfmt(%s).\n", $fs);
		return show_dfmt($fs);
	} elsif (-d $fs) {
		$debug->prntf("serv: call show_dfmt(%s).\n", $fs);
		return show_dfmt($fs);
	} elsif (-f $fs. $conf->{mkd_sufx}) {
		$debug->prntf("serv: call show_ffmt(%s).\n", 
		    $fs. $conf->{mkd_sufx});
		return show_ffmt($fs. $conf->{mkd_sufx});
	} else {
		$debug->prntf("serv: ret (postd) HTTP_NOT_FOUND; \$fs = (%s).\n", $fs);
		return [
		    HTTP_NOT_FOUND, 
		    ["Content-Type" => $conf->{plain_ct}], 
		    [sprintf("ERROR: File '%s' doesn't exist!", $fs)]
		];
	}
}

# Checks the configuration for validity, _dies_ if there is an unrecognized
# option, or if an option has an invalid value. Returns $conf otherwise.
sub
check_conf
{
	my $conf	= shift;

	my %valid_c; # Valid keys, made a hash (for fast lookup), we currently
		     # only the key and an empty value.
	%valid_c = (
			html_ct		=> undef,
			fb_ct		=> undef,
			mkd_ct		=> undef,
			mkd_idx		=> undef,
			mkd_sufx	=> undef,
			plain_ct	=> undef,
			postd		=> undef,
			srcd		=> undef,
			uri2fs		=> undef,
			userd		=> undef,
	);

	$debug->prntf("check_conf: args \$conf = '%s'.\n", $conf);
	die "\$conf mustn't be undef!, stopped" unless $conf;

	for (sort keys %valid_c) {
		if (not $conf->{$_}) {
			die "check_conf: \$conf must contain a '$_' key!, ".
			    "stopped";
		}
	}

	for (sort keys %$conf) {
		if (not exists $valid_c{$_} ) {
			die "check_conf: option '$_' unrecognized!; stopped";
		} elsif (!$conf->{$_}) {
			die "check_conf: \$conf->{$_} () mustn't be empty ".
			    "or undef!, stopped"; 
		} elsif (($_ eq 'srcd' or $_ eq 'postd' 
			or $_ eq 'userd') and $conf->{$_} !~ m!^/!) {
			#  Checks that the paths aren't empty and start with slash.
			die sprintf("check_conf: \$conf->{$_} (%s) must start with an ".
				    "slash '/'!, stopped", $conf->{$_});
		}

		$debug->prntf("check_conf: \$conf->{$_} = '%s'; OK.\n",
		    $conf->{$_});

	}
	$debug->prntf("check_conf: ret \$conf = '%s'.\n", $conf);
	return $conf;
}

# Gets the relative path: The relative path is equal to the path that $path
# would have if it would be rooted in $root, for this $path and $root must be absolute
# path names. This 'returns;' if $path isn't inside $root or if any of $path or
# $root is undef or empty; otherwise this function returns a normalized (without
# duplicated slashes) and compressed (see compress_p() below) path.
sub
g_relpath
{
	my $root		= shift;
	my $path		= shift;

	my $relp; # Relative path.

	$debug->prntf("g_relpath: arg \$root = '%s'\n", $root ? $root : "");
	$debug->prntf("g_relpath: arg \$path = '%s'\n", $path ? $path : "");

	return	unless $root and $path;
	return  unless $root =~ m!^/! and $path =~ m!^/!;


	if ($path eq '/') {
		$relp = $root;
	} elsif ($root eq '/') {
		$relp = $path;
	} elsif (not $relp = substr($path, length($root))) {
		die "I couldn't substr()!, stopped";
	}

	$relp = compress_p($relp);
	$relp =~ s!/+!/!g; # Prunes duplicated slashes anywhere
	return $relp;
}

# Is static file: returns true is the uri argument must be fetch from the
# filesystem and displayed "verbatim", or false in case it's a post file that
# must be parsed.
sub
isstatic
{
	my $uri		= shift;

	my $regex;
	my $href;
	my $i;
	my $j;

	$debug->prntf("isstatic: arg \$uri = '%s'\n", $uri);
	return unless $uri; # Must be defined and non-empty.

	# See check_conf_uri2fs() for more info.
	for ($i = 0, $j = 1; 
	    ($regex, $href) = @{$conf->{uri2fs}}[$i, $j]; 
	    $i+=2, $j+=2) {
		$debug->prntf("isstatic:\turi2fs['%s', '%s'] = ('%s', '%s')\n",
			      $i, $j, $regex, $href);
		if (not $href) {
			next;
		} elsif (not $uri =~ $regex) {
			next;
		} elsif ($href->{name} ne 'postd') {
			return 1;
		} else {
			return 0;
		}

	}
	return 0;

}

# Strips trailing slash from a variable: this function 'return;' when it
# receives an undef or empty string as argument; otherwise it removes any
# slashes '/' at the end of it's argument, except when it's argument consists
# only of slashes '///', '/', etc. In which case it returns a lonely slash '/'.
sub
strip_traslash
{
	my $path	= shift;

	return unless $path; # Must be defined and non-empty.
	if ($path =~ m!^/+$!) {
		return "/";
	} else {
		$path =~ s!/+$!!;
		return $path;
	}
	# NOTREACHED
}

# URI to filesystem path: translates an URI to the corresponding filesystem
# path. This function receives two arguments a directory $root, which is a
# filesystem path that will be prepended to all the values returned by this
# function; and $uri which is a path which is going to be appended to $root.
# This function makes no attempt to see if the files that it returns even exist,
# it's the caller responsability to check that. If any argument is undef or an
# empty string, this program 'return;'. This function does guarantee, however,
# that it's return value doesn't have any duplicated slashes ('//').
sub
uri2fs
{
	my $uri		= shift;
	
	my $fs;
	my $regex;
	my $href;
	my $i;
	my $j;

	$debug->prntf("uri2fs: arg \$uri = '%s'\n", $uri);
	return unless $uri; # Must be defined and non-empty.

	# See check_conf_uri2fs() for more info.
	for ($i = 0, $j = 1; 
	    ($regex, $href) = @{$conf->{uri2fs}}[$i, $j]; 
	    $i+=2, $j+=2) {
		$debug->prntf("uri2fs:\turi2fs['%s', '%s'] = ('%s', '%s')\n",
			      $i, $j, $regex, $href);
		if (not $href) {
			next;
		} elsif (not $uri =~ $regex) {
			next;
		} elsif (not $fs = $href->{fs}->($uri, $regex)) {
			die "Couldn't run $regex->('$uri', '$regex'), stopped";
		} else { 
			last; 
		}
	}

	return unless $fs;
	$fs =~ s!/+!/!g; # Prunes duplicated slashes
	$debug->prntf("uri2fs: ret \$fs = '%s'\n", $fs);
	return $fs;
}

# Sends a fucken HTTP_MOVED_PERMANENTLY. Returns a PSGI response redirecting the
# user to $uri. 
sub
rdr
{
	my $uri		= shift;	# where to 301'

	$debug->prntf("rdr ('%s')\n", $uri);
	return [HTTP_MOVED_PERMANENTLY, [Location => $uri], []];
}

# Shows a directory "unformatted", it means that we print a directory listing
# without calling for our common template. Returns a PSGI response, containing
# the directory listings on $dir. Returns undef if there is an error.
sub
show_d
{
	my %args = @_;

	my $dir;  # Directory to show
	my $uri;  # URI path, it's prepended to all links.
	my $body; # PSGI body

	$dir = $args{dir};
	$uri = $args{uri} ? $args{uri} : "/";

	$body = ["<html><body>\n"];
	for (sort @{ls($dir)}) {
		push @$body, sprintf(qq!<a href="%s">%s</a><br />\n!, 
		                     $uri. "/". $_, $_);
	}
	push @$body, "</body></html>";

	return [
	    HTTP_OK, 
	    ["Content-Type" => $conf->{html_ct}],
	    $body
	];
}

# Shows a file without doing any parsing on it. We only try to guess it's MIME
# type. This returns a PSGI response containing the file. Returns undef if there
# is an error.
sub
show_f
{
	my $file	= shift;

	my $mime;	# MIME type
	my $ct;		# Content-Type
	my $psgi;	# PSGI response
	my $fd;		# File descriptor for $file

	if (not $mime = &Semece::MIME::mime_t($file)) {
		die "Couldn't mime_t(), stopped";
	} elsif (not $ct = mime2ct($mime)) {
		die "Couldn't mime2ct(), stopped";
	} elsif (not open($fd, "<:bytes", $file)) {
		die "Couldn't open(), $!, stopped";
	}
	$psgi = [HTTP_OK, ["Content-Type" => $ct], [<$fd>]];
	return unless close($fd);
	return $psgi;
}

# Shows a markdown file parsing it first. This receives as argument the uri that
# matched it and the filename. Returns a PSGI response or undef is there is any
# error.
sub
show_ffmt
{
	my %args	= @_;

	my $fd;	# file descriptor
	my $content;

	$fd = undef;
	$content = undef;

	$debug->prntf("show_ffmt: arg \$file = '%s'\n", $args{file});
	$debug->prntf("show_ffmt: arg \$uri  = '%s'\n", $args{uri});

	return unless $args{file}; 

	if (not open($fd, "<:bytes", $args{file})) {
		die "I couldn't open($args{file}); $!; stopped";
	}

	# if you requested the parsing of a markdown	
#content => &Semece::Parse::parse($q, join('', <$fd>)),
	$content = &Semece::Temp::temp(based => $args{uri}, 
			menu	=> gen_menu($args{uri}, $args{file}),
			content => "herpa derpa",
			mkurl	=> $args{uri});
	$content = encode_utf8($content);
	$debug->prntf("show_ffmt: \$content = '%s'\n", $content);
	return [
	    HTTP_OK, 
	    ["Content-Type" => $conf->{html_ct}],
	    [$content]
	];
}

sub
show_dfmt
{
	return [HTTP_OK, ["Content-Type" => "text/plain"], ["show_dfmt(@_)"]];
}

# List directory contents: this function behaves like unix ls(1). This function
# returns as an array ref containing it's argument if it was called with a
# non-directory argument (file); it returns undef in case of error; otherwise
# it returns as an array ref the contents of the directory $fs (non recursively).
# The array ref returned by this function is not guaranted to be sorted on any
# way.
sub
ls
{
	my $fs	= shift; # Filesystem path.
	
	my $dh	= undef; # Directory handler.
	my $f	= []; # Files in $fs

	return [$fs] if -f $fs;	
	return undef if !-d $fs or !-r $fs or !-x $fs; # Couldn't read $fs

	opendir($dh, $fs) or return undef;
	$f = [readdir $dh];
	closedir $dh or die "Couldn't closedir()!, $!; stopped";

	return $f;
}


# Compress a path: this function receives a path as unique argument. This
# function returns it's argument after "expanding" the parent directories on it
# ('..'). If this function is called with undef argument it returns undef. If
# this function is called with an empty argument it returns ".". If this
# function is called with an absolute path name (path starting with '/') this
# function returns _at least_ '/". If this function is called with a relative
# path name it returns _at least_ "." if otherwise it would return an empty
# string. Examples: 
#	"/var/tmp/.."		returns "/var"
#	"/var/tmp/../.."	returns "/"
#	"/var/tmp/../../.."	returns "/"
#	"/var/tmp/../../../"	returns "/"
#	"var/tmp/"		returns "var/tmp/"
#	""			returns "."
#	"hello/world/.."	returns "hello"
#	"hello/world/../.."	returns "."
sub
compress_p
{
	my $path	= shift; # Path.

	my $npath; # New path
	my @p; # Each field of the path.
	my @q; # Each field of the new path.
	my $abs; # True if $path is an absolute path, false otherwise

	$debug->prntf("compress_p: arg \$path = '%s'\n", $path);
	return "." if defined($path) and $path eq "";
	return unless $path = strip_traslash($path);

	$abs = 1 if $path =~ m!^/!; # Remember if we had a leading slash
	$path =~ s!^/!!;	# Strips a leading  slash, so we don't split "/" 
			# into "", "".
	@p = split '/', $path;
	for (@p) {
		if ($_ eq '..') {
			pop @q;
		} else {
			push @q, $_;
		}
	}

	if ($abs) {
		$npath = "/". join("/", @q);
	} elsif (scalar @q == 0) {
		$npath = ".";
	} else {
		$npath = join("/", @q);
	}
	$debug->prntf("compress_p: ret \$npath = '%s'\n", $npath);
	return $npath;
}

# MIME to Content-Type: mainly established full content-type strings to use per
# MIME Type. Currently only adds: '; charset=...' to a MIME. Returns the
# fallback Content-Type in case of doubt.
sub
mime2ct
{
	my $mime	= shift;
	
	my $ct		= undef;

	$debug->prntf("mime2ct: arg '%s'\n", $mime);
	if (not $mime) {
		$ct = $conf->{fb_ct};
	} elsif ($mime eq 'text/plain') {
		$ct = $conf->{plain_ct}	
	} elsif ($mime eq 'text/html') {
		$ct = $conf->{html_ct}	
	} else {
		$ct = $mime;
	}

	$debug->prntf("mime2ct: ret '%s'\n", $ct);
	return $ct;
}

# From dirname(1): dirname deletes the filename portion, beginning with the last
# slash (`/') character to the end of pathname, and returns the result. This
# function 'return;'s if there is any error. 
sub
dirname
{
	my $path	= shift;

	my $dirname;

	return unless $path;
	if ($path =~ s!/+[^/]+$!!) {
		$dirname = $path;
	} elsif ($path =~ s!/+$!!) {
		$dirname = $path;
	} else {
		$dirname = undef;
	}
	return unless $dirname;
	return $dirname;
}

# Generate menu:  given a $uri and a $path, we display all the directories and
# file under that $path, if $path is a directory, if $path is a file then we
# display all the files in it's parent directory.
sub
gen_menu
{
	my $uri		= shift; # Uri that matches $path.
	my $path	= shift; # Current path to highlight on the menu.

	my $html; # Generated HTML
	my @menu; # Temporary menu array
	my $dirn; # (Parent) Directory name.
	my $tmp;
	my $relp; # $path relative to $uri

	$debug->prntf("gen_menu: arg \$uri = '%s'\n", $uri);
	$debug->prntf("gen_menu: arg \$path = '%s'\n", $path);

	$uri = "" if $uri eq '/'; # Simplifies URI generation.

	if (-d $path) {
		$dirn = $path;
	} elsif (not -f $path && ($dirn = dirname($path))) {
		die "I couldn't dirname('$path')!, stopped";
	}

	if (not $tmp = ls($dirn)) {
		die "I couldn't ls('$dirn')!, stopped";
	} 

	@menu = grep {!/^.git/} sort @{$tmp};
	$debug->prntf("gen_menu: \@menu = (\n");
	for (@menu) {
		$debug->prntf("gen_menu:\t'$_',\n");
	}
	$debug->prntf("gen_menu: )\n");

	$html  = '<ul id="menu">';
	for (@menu) {
		$html .= qq!<li id="menu">\n!;
		if (-f $dirn. "/". $_) {
			$html .= sprintf(qq!  <a href="%s">%s</a>!,
					 $uri. "/". $_,
					 g_relpath($uri, $_));
		} elsif (-d $dirn. "/". $_ and ($_ eq '.' or $_ eq '..')) {
			$html .= sprintf(qq!  <a href="%s">%s</a>!,
					 $uri. "/". $_,
					 g_relpath($uri, $_));
		} elsif (-d $dirn. "/". $_) {
			$html .= "  ". gen_menu($uri. "/". $_, 
						$dirn. "/". $_);
		}
		$html .= "\n</li>\n";
	}
	$html .= '</ul>';

	return $html;
}

1;

__END__
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
	print &Semece::Temp::temp(based => &Semece::Tool::g_location($q), 
			menu	=> &gen_menu($q, &Semece::Tool::g_postd($q)),
			content => (&Semece::Parse::parse($q, (join '', <$fd>))),
			mkurl	=> &g_mk_u($q));
	return OK;
}

1;
