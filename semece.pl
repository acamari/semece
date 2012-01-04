#!/usr/bin/perl
#
# Copyright (c) 2011 Rafael Díaz de León Plata <leon@elinter.net>
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

use Mojolicious::Lite;

use utf8;

use constant {
	POSTS => '/var/www/sentx/postd'
};

# Fix this, obviously.
# should load it from config file
app->secret('4');

get '/' => sub {
	my $self	= shift;
	my $files	= [];
	my $path	= POSTS;

	unless (-d $path) {
		$path = dirname($path);
	}

	$files = ls($path, 1);

	$self->content_for('menu', $files);
	$self->render(
	    template	=> 'index',
	    );
} => 'index';

get '/(*rpath)' => sub {
	my $self	= shift;
	my $path	= $self->param('rpath');
	my $raw		= 0; # Format the mkd
	my $fh;

	$path = POSTS . "/$path";

	if ($path =~ /\.mkd$/) {
		$raw = 1;
	} elsif ($path =~ m|/$|) {
		$path .= 'index.mkd';
	} else {
		$path .= ".mkd";
	}

	if ($raw && -r $path && -f $path) {
		open $fh, '<:utf8', $path;
		$self->render(
		    format	=> 'text',
		    template	=> 'plain',
		    unformatted	=> join '', <$fh>
		    );
		close $fh;
		return;
	} elsif (-r $path && -f $path) {
		open $fh, '<:utf8', $path;
		$self->render(
		    template	=> 'post',
		    unformatted	=> join '', <$fh>
		    );
		close $fh;
		return;
	} 

	$self->render(
	    template	=> 'post',
	    unformatted	=> "## Archivo no encontrado", 
	    status	=> 404
	    );
	return;
};

app->start;

sub ls {
	my $fs	    = shift; # Filesystem path.
	my $recurse = shift;
	
	my $dh	= undef; # Directory handler.
	my $f	= []; # Files in $fs
	my $t	= {}; # File tree

	return [$fs] if -f $fs;	
	return undef if !-d $fs or !-r $fs or !-x $fs; # Couldn't read $fs

	opendir($dh, $fs) or return undef;
	# Don't show files beginning with a dot
	$f = [grep { m|^[^\.]| } (readdir $dh)];
	for (@$f) {
		my $npath = "$fs/$_";
		app->log->debug("Reading $npath");
		if ($recurse and -d $npath) {
			$t->{$_} = ls($npath);
		} elsif (-d $npath) {
			$t->{$_} = 'dir';
		} elsif (-r $npath) {
			$t->{$_} = 'file';
		}
	}
	closedir $dh or die "Couldn't closedir()!, $!; stopped";

	return $t;
}

sub dirname {
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

helper menu => sub {
	my $self	= shift;
	my $path	= POSTS;

	unless (-d $path) {
		$path = dirname($path);
	}

	return bmenu(ls($path, 1));
};

# Build menu in nested ul's
sub bmenu {
	my $t		= shift;
	my $prev	= shift;
	my $ul		= '';

	$prev |= '';

	unless ($prev) {
		$ul .= '<li><a href="/">/</a><li>';
	}

	while (my ($file, $type) = each %$t) {
		app->log->debug("building $file");
		my $rpath = "$prev/$file";

		if (ref $type eq 'HASH' && -f POSTS . "$rpath/index.mkd") {
			# Directory with index file
			$ul .= "<li><a href=\"$rpath/\">$file</a>/\n";
			$ul .= bmenu($type, $rpath);
			$ul .= "</li>\n";
		} elsif (ref $type eq 'HASH') {
			# Directory with out an index file
			$ul .= "<li>$file/\n";
			$ul .= bmenu($type, $rpath);
			$ul .= "</li>\n";
		} else {
			# Normal post
			next unless $file =~ s/\.mkd$//;
			next if $file eq 'index';

			$ul .= "<li><a href=\"$prev/$file\">";
			$ul .= "$file</a></li>";
		}
	}
	
	return "<ul>\n$ul</ul>\n";
};

app->start();
