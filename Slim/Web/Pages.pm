package Slim::Web::Pages;

# $Id$

# SlimServer Copyright (c) 2001-2004 Sean Adams, Slim Devices Inc.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License, 
# version 2.

use strict;

use File::Spec::Functions qw(:ALL);
use POSIX ();
use Slim::Utils::Misc;
use Slim::Utils::Strings qw(string);

our %additionalLinks = ();

our %fieldInfo = ();

sub init {

	%fieldInfo = (
		'track' => {

			'title' => 'BROWSE_BY_SONG',
			'allTitle' => 'ALL_SONGS',
			'idToName' => sub {
				my $ds  = shift;
				my $id  = shift;
				my $obj = $ds->objectForId('track', $id) || return '';

				return $obj->title();
			},

			'resultToId' => sub {
				my $obj = shift;
				return $obj->id;
			},

			'resultToName' => sub {
				my $obj = shift;
				return $obj->title;
			},

			'find' => sub {
				my $ds = shift;
				my $level = shift;
				my $findCriteria = shift;
				return $ds->find('track', $findCriteria, exists $findCriteria->{'album'} ? 'tracknum' : 'title');
			},

			'listItem' => sub {
				my $ds   = shift;
				my $form = shift;
				my $item = shift;

				my $webFormat = Slim::Utils::Prefs::getInd("titleFormat",Slim::Utils::Prefs::get("titleFormatWeb"));

				$form->{'text'} = Slim::Music::Info::standardTitle(undef, $item);

				if (my ($contributor) = $item->contributors()) {
					$form->{'artist'}   = $contributor->name();
					$form->{'artistid'} = $contributor->id();
				}

				if (my $album = $item->album()) {
					$form->{'album'}   = $album->title();
					$form->{'albumid'} = $album->id();
				}

				$form->{'includeArtist'}       = ($webFormat !~ /ARTIST/);
				$form->{'includeAlbum'}        = ($webFormat !~ /ALBUM/) ;
				$form->{'item'}	               = $item->id;
				$form->{'itempath'}	       = $item->url;
				$form->{'mixable_not_descend'} = Slim::Music::Info::isSongMixable($item->url);

				my ($body, $type, $mtime) =  Slim::Music::Info::coverArt($item->url);

				if (defined($body)) {
					$form->{'coverart'} = 1;
					$form->{'coverartpath'} = $item->url();
				}
			},

			'ignoreArticles' => 1,
		},

		'genre' => {
			'title' => 'BROWSE_BY_GENRE',
			'allTitle' => 'ALL_GENRES',

			'idToName' => sub {
				my $ds  = shift;
				my $id  = shift;
				my $obj = $ds->objectForId('genre', $id) || return '';

				return $obj->name();
			},

			'resultToId' => sub {
				my $obj = shift;
				return $obj->id;
			},

			'resultToName' => sub {
				my $obj = shift;
				return $obj->name;
			},

			'find' => sub {
				my $ds = shift;
				my $level = shift;
				my $findCriteria = shift;

				return $ds->find('genre', $findCriteria, 'genre');
			},

			'listItem' => sub {
				my $ds = shift;
				my $list_form = shift;
				my $item = shift;
				my $itemname = shift;
				my $descend = shift;

				$list_form->{'mixable_descend'} = Slim::Music::Info::isGenreMixable($itemname) && ($descend eq "true");
			},

			'ignoreArticles' => 0,
			'alphaPageBar' => 1
		},

		'album' => {
			'title' => 'BROWSE_BY_ALBUM',
			'allTitle' => 'ALL_ALBUMS',

			'idToName' => sub {
				my $ds  = shift;
				my $id  = shift;
				my $obj = $ds->objectForId('album', $id) || return '';

				return $obj->title();
			},

			'resultToId' => sub {
				my $obj = shift;
				return $obj->id;
			},

			'resultToName' => sub {
				my $obj = shift;
				return $obj->title;
			},

			'find' => sub {
				my $ds = shift;
				my $level = shift;
				my $findCriteria = shift;

				return $ds->find('album', $findCriteria, 'album');
			},

			'listItem' => sub {
				# XXX FIXME "showYear" functionality broken
			},

			'ignoreArticles' => 1,
			'alphaPageBar' => 1
		},

		'artwork' => {
			'title' => 'BROWSE_BY_ARTWORK',

			'idToName' => sub {
				my $ds  = shift;
				my $id  = shift;
				my $obj = $ds->objectForId('album', $id) || return '';

				return $obj->title();
			},

			'resultToId' => sub {
				my $obj = shift;
				return $obj->id;
			},

			'resultToName' => sub {
				my $obj = shift;
				return $obj->title;
			},

			'find' => sub {
				my $ds = shift;
				my $level = shift;
				my $findCriteria = shift;

				if (Slim::Utils::Prefs::get('includeNoArt')) {
					return $ds->find('album', $findCriteria, 'album');
				}
				
				return $ds->albumsWithArtwork()
			},

			'listItem' => sub {
				my $ds   = shift;
				my $form = shift;
				my $item = shift;
				my $itemname = shift;

				if ($item->artwork_path()) {
					$form->{'coverthumb'} = 1;
					$form->{'thumbartpath'} = $item->artwork_path;
				} else {
					$form->{'coverthumb'}   = 0;
				}

				# XXX FIXME "showYear" functionality broken
				$form->{'item'}    = $itemname;
				$form->{'artwork'} = 1;
				$form->{'size'}	   = Slim::Utils::Prefs::get('thumbSize');
			},

			'nameTransform' => 'album',
			'ignoreArticles' => 1,
			'alphaPageBar' => 0,
			'suppressAll' => 1
		},

		'artist' => {
			'title' => 'BROWSE_BY_ARTIST',
			'allTitle' => 'ALL_ARTISTS',

			'idToName' => sub {
				my $ds = shift;
				my $id = shift;
				my $obj = $ds->objectForId('contributor', $id) || return '';

				return $obj->name();
			},

			'resultToId' => sub {
				my $obj = shift;
				return $obj->id;
			},

			'resultToName' => sub {
				my $obj = shift;
				return $obj->name;
			},

			'find' => sub {
				my $ds = shift;
				my $level = shift;
				my $findCriteria = shift;

				return $ds->find('artist', $findCriteria, 'artist');
			},

			'listItem' => sub {
				my $ds   = shift;
				my $form = shift;
				my $item = shift;
				my $itemname = shift;
				my $descend = shift;

				$form->{'mixable_descend'} = Slim::Music::Info::isArtistMixable($itemname) && ($descend eq "true");
			},

			'ignoreArticles' => 1,
			'alphaPageBar' => 1
		},

		'year' => {
			'title' => 'BROWSE_BY_YEAR',
			'allTitle' => 'ALL_YEARS',

			'idToName' => sub {
				my $ds  = shift;
				my $id  = shift;
				return $id;
			},

			'resultToId' => sub {
				my $obj = shift;
				return $obj;
			},

			'resultToName' => sub {
				my $obj = shift;
				return $obj;
			},

			'find' => sub {
				my $ds = shift;
				my $level = shift;
				my $findCriteria = shift;

				return $ds->find($level, $findCriteria, $level);
			},

			'listItem' => sub {
				my $ds = shift;
				my $list_form = shift;
				my $item = shift;
				my $itemname = shift;
				my $descend = shift;

				$list_form->{'mixable_descend'} = Slim::Music::Info::isGenreMixable($itemname) && ($descend eq "true");
			},

			'ignoreArticles' => 1,
			'alphaPageBar' => 0
		},

		'default' => {
			'title' => 'BROWSE',
			'allTitle' => 'ALL',
			'idToName' => sub { my $ds = shift; return shift },
			'resultToId' => sub { return shift },
			'resultToName' => sub { return shift },

			'find' => sub { 
				my $ds = shift;
				my $level = shift;
				my $findCriteria = shift;
				return $ds->find($level, $findCriteria, $level);
			},

			'listItem' => sub { },
			'ignoreArticles' => 0
		}
	);
}

sub home {
	my ($client, $params) = @_;

	my %listform = %$params;

	if (defined $params->{'forget'}) {
		Slim::Player::Client::forgetClient($params->{'forget'});
	}

	$params->{'nosetup'} = 1   if $::nosetup;
	$params->{'newVersion'} = $::newVersion if $::newVersion;

	if (!exists $additionalLinks{"browse"}) {
		# Uncomment these lines and comment the ones following to enable
		# the new web interface scheme using browsedb. Look a few lines
		# below for cover art related browsing.
		addLinks("browse",{'BROWSE_BY_ARTIST' => "browsedb.html?hierarchy=artist,album,track&level=0"});
		addLinks("browse",{'BROWSE_BY_GENRE'  => "browsedb.html?hierarchy=genre,artist,album,track&level=0"});
		addLinks("browse",{'BROWSE_BY_ALBUM'  => "browsedb.html?hierarchy=album,track&level=0"});
		addLinks("browse",{'BROWSE_BY_YEAR'   => "browsedb.html?hierarchy=year,album,track&level=0"});
		#addLinks("browse",{'BROWSE_BY_ARTIST' => "browseid3.html?genre=*"});
		#addLinks("browse",{'BROWSE_BY_GENRE'  => "browseid3.html"});
		#addLinks("browse",{'BROWSE_BY_ALBUM'  => "browseid3.html?genre=*&artist=*"});
	}

	if (!exists $additionalLinks{"search"}) {
		addLinks("search",{'SEARCHFOR_ARTIST' => "search.html?type=artist"});
		addLinks("search",{'SEARCHFOR_ALBUM' => "search.html?type=album"});
		addLinks("search",{'SEARCHFOR_SONGTITLE' => "search.html?type=song"});
	}

	if (!exists $additionalLinks{"help"}) {
		addLinks("help",{'GETTING_STARTED' => "html/docs/quickstart.html"});
		addLinks("help",{'PLAYER_SETUP' => "html/docs/ipconfig.html"});
		addLinks("help",{'USING_REMOTE' => "html/docs/interface.html"});
		addLinks("help",{'HELP_REMOTE' => "html/help_remote.html"});
		addLinks("help",{'HELP_RADIO' => "html/docs/radio.html"});
		addLinks("help",{'REMOTE_STREAMING' => "html/docs/remotestreaming.html"});
		addLinks("help",{'FAQ' => "html/docs/faq.html"});
		addLinks("help",{'SOFTSQUEEZE' => "html/softsqueeze/index.html"});
		addLinks("help",{'TECHNICAL_INFORMATION' => "html/docs/index.html"});
	}

	if (Slim::Utils::Prefs::get('lookForArtwork')) {
		# Uncomment the next lines and comment the one following to enable
		# the new web interface scheme using browsedb.
		addLinks("browse",{'BROWSE_BY_ARTWORK' => "browsedb.html?hierarchy=artwork,track&level=0"});
		#addLinks("browse",{'BROWSE_BY_ARTWORK' => "browseid3.html?genre=*&artist=*&artwork=1"});
	} else {
		addLinks("browse",{'BROWSE_BY_ARTWORK' => undef});
		$params->{'noartwork'} = 1;
	}
	
	if (Slim::Utils::Prefs::get('audiodir')) {
		addLinks("browse",{'BROWSE_MUSIC_FOLDER' => "browse.html?dir="});
	} else {
		addLinks("browse",{'BROWSE_MUSIC_FOLDER' => undef});
		$params->{'nofolder'}=1;
	}
	
	if (Slim::Utils::Prefs::get('playlistdir') || Slim::Music::Import::countImporters()) {
		addLinks("browse",{'SAVED_PLAYLISTS' => "browse.html?dir=__playlists"});
	} else {
		addLinks("browse",{'SAVED_PLAYLISTS' => undef});
	}
	
	# fill out the client setup choices
	for my $player (sort { $a->name() cmp $b->name() } Slim::Player::Client::clients()) {

		# every player gets a page.
		# next if (!$player->isPlayer());
		$listform{'playername'}   = $player->name();
		$listform{'playerid'}     = $player->id();
		$listform{'player'}       = $params->{'player'};
		$listform{'skinOverride'} = $params->{'skinOverride'};
		$params->{'player_list'} .= ${Slim::Web::HTTP::filltemplatefile("homeplayer_list.html", \%listform)};
	}

	Slim::Buttons::Plugins::addSetupGroups();
	$params->{'additionalLinks'} = \%additionalLinks;

	_addPlayerList($client, $params);
	
	_addStats($params, [], [], [], []);

	my $template = $params->{"path"}  =~ /home\.(htm|xml)/ ? 'home.html' : 'index.html';
	
	return Slim::Web::HTTP::filltemplatefile($template, $params);
}

sub addLinks {
	my ($category, $links) = @_;

	return if (ref($links) ne 'HASH');

	while (my ($title, $path) = each %$links) {
		if (defined($path)) {
			$additionalLinks{$category}->{$title} = $path . 
				(($path =~ /\?/) ? '&' : '?');
		} else {
			delete($additionalLinks{$category}->{$title});
		}
	}
}

# Check to make sure the ref is valid, and not a wildcard.
sub _refCheck {
	my $ref = shift;

	return defined $ref && scalar @$ref && $ref->[0] && $ref->[0] ne '*' ? 1 : 0;
}

sub _lcPlural {
	my ($count, $singular, $plural) = @_;

	return sprintf("%s %s", $count, lc(($count == 1 ? string($singular) : string($plural))));
}

sub _addStats {
	my ($params, $genre, $artist, $album) = @_;
	
	return if Slim::Utils::Misc::stillScanning();

	my $count = 0;
	my $ds    = Slim::Music::Info::getCurrentDataStore();
	my $find  = {};

	$find->{'genre'}       = $genre  if _refCheck($genre);
	$find->{'contributor'} = $artist if _refCheck($artist);
	$find->{'album'}       = $album  if _refCheck($album);

	$params->{'song_count'}   = _lcPlural($ds->count('track', $find), 'SONG', 'SONGS');
	$params->{'artist_count'} = _lcPlural($ds->count('contributor', $find), 'ARTIST', 'ARTISTS');
	$params->{'album_count'}  = _lcPlural($ds->count('album', $find), 'ALBUM', 'ALBUMS');
}

sub browser {
	my ($client, $params, $callback, $httpClient, $response) = @_;

	my $dir = defined($params->{'dir'}) ? $params->{'dir'} : "";

	my ($item, $itempath, $playlist, $current_player);
	my  $items = [];

	my $fulldir = Slim::Utils::Misc::virtualToAbsolute($dir);

	$::d_http && msg("browse virtual path: " . $dir . "\n");
	$::d_http && msg("with absolute path: " . $fulldir . "\n");

	if (defined($client)) {
		$current_player = $client->id();
	}

	if ($dir =~ /^__playlists/) {

		$playlist = 1;
		$params->{'playlist'} = 1;

		if (!Slim::Utils::Prefs::get("playlistdir") && !Slim::Music::Import::countImporters()) {
			$::d_http && msg("no valid playlists directory!!\n");
			return Slim::Web::HTTP::filltemplatefile("badpath.html", $params);
		}

		if ($dir =~ /__current.m3u$/) {

			# write out the current playlist to a file with the special name __current
			if (defined($client)) {
				my $count = Slim::Player::Playlist::count($client);
				$::d_http && msg("Saving playlist of $count items to $fulldir\n");
				Slim::Control::Command::execute($client, ['playlist', 'save', '__current']) if $count;

			} else {
				$::d_http && msg("no client, so we can't save a file!!\n");
				return Slim::Web::HTTP::filltemplatefile("badpath.html", $params);
			}
		}

	} else {

		if (!Slim::Utils::Prefs::get("audiodir")) {
			$::d_http && msg("no audiodir, so we can't save a file!!\n");
			return Slim::Web::HTTP::filltemplatefile("badpath.html", $params);
		}
	}

	if (!$fulldir || !Slim::Music::Info::isList($fulldir)) {

		# check if we're just showing itunes playlists
		if (Slim::Music::Import::countImporters()) {
			browser_addtolist_done($current_player, $callback, $httpClient, $params, [], $response);
			return undef;
		} else {
			$::d_http && msg("the selected playlist $fulldir isn't good!!.\n");
			return Slim::Web::HTTP::filltemplatefile("badpath.html", $params);
		}
	}

	my $suffix = Slim::Formats::Parse::getPlaylistSuffix($fulldir);

	# if they are renaming the playlist, let 'em.
	if ($playlist && $params->{'newname'}) {

		my $newname = $params->{'newname'};

		# don't allow periods, colons, control characters, slashes, backslashes, just to be safe.
		$newname =~ tr|.:\x00-\x1f\/\\| |s;

		if (defined($suffix)) {
			$newname .= $suffix;
		};
		
		if ($newname) {

			my @newpath = splitdir(Slim::Utils::Misc::pathFromFileURL($fulldir));
			pop @newpath;

			my $container = Slim::Utils::Misc::fileURLFromPath(catdir(@newpath));

			push @newpath, $newname;

			my $newfullname = Slim::Utils::Misc::fileURLFromPath(catdir(@newpath));

			$::d_http && msg("renaming $fulldir to $newfullname\n");

			if ($newfullname ne $fulldir && (!-e Slim::Utils::Misc::pathFromFileURL($newfullname) || defined $params->{'overwrite'}) && rename(Slim::Utils::Misc::pathFromFileURL($fulldir), Slim::Utils::Misc::pathFromFileURL($newfullname))) {

				Slim::Music::Info::clearCache($container);
				Slim::Music::Info::clearCache($fulldir);

				$fulldir = $newfullname;

				$dir = Slim::Utils::Misc::descendVirtual(Slim::Utils::Misc::ascendVirtual($dir), $newname);

				$params->{'dir'} = $dir;
				$::d_http && msg("new dir value: $dir\n");

			} else {

				$::d_http && msg("Rename failed!\n");
				$params->{'RENAME_WARNING'} = 1;
			}
		}

	} elsif ($playlist && $params->{'delete'} ) {

		my $path = Slim::Utils::Misc::pathFromFileURL($fulldir);
		
		if ($path && -f $path && unlink $path) {

			$::d_http && msg("deleted playlist: $path\n");

			my @newpath  = splitdir(Slim::Utils::Misc::pathFromFileURL($fulldir));
			pop @newpath;
	
			my $container = Slim::Utils::Misc::fileURLFromPath(catdir(@newpath));
	
			Slim::Music::Info::clearCache($container);
			Slim::Music::Info::clearCache($fulldir);
	
			$dir = Slim::Utils::Misc::ascendVirtual($dir);
			$params->{'dir'} = $dir;
			$fulldir = Slim::Utils::Misc::virtualToAbsolute($dir);
			$suffix = Slim::Formats::Parse::getPlaylistSuffix($fulldir);

		} else {

			$::d_http && msg("couldn't delete playlist: $path\n");
		}
	}

	#
	# Make separate links for each component of the pwd
	#
	my %list_form = %$params;
	
	$list_form{'player'}        = $current_player;
	$list_form{'myClientState'} = $client;
	$list_form{'skinOverride'}  = $params->{'skinOverride'};
	$params->{'pwd_list'} = " ";

	my $lastpath;
	my $aggregate = $playlist ? "__playlists" : "";

	for my $c (splitdir($dir)) {

		if ($c ne "" && $c ne "__playlists" && $c ne "__current.m3u") {

			# incrementally build the path for each link
			$aggregate = (defined($aggregate) && $aggregate ne '') ? catdir($aggregate, $c) : $c;

			$list_form{'dir'} = Slim::Web::HTTP::escape($aggregate);
			
			$list_form{'shortdir'} = Slim::Music::Info::standardTitle(undef, Slim::Utils::Misc::virtualToAbsolute($c));

			$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("browse_pwdlist.html", \%list_form)};
		}

		$lastpath = $c if $c;
	}

	if (defined($suffix)) {

		$::d_http && msg("lastpath equals $lastpath\n");

		if ($lastpath eq "__current.m3u") {
			$params->{'playlistname'}   = string("UNTITLED");
			$params->{'savebuttonname'} = string("SAVE");
		} else {

			$lastpath =~ s/(.*)\.(.*)$/$1/;
			$params->{'playlistname'}   = $lastpath;
			$params->{'savebuttonname'} = string("RENAME");
			$params->{'titled'} = 1;
		}
	}

	# Scan the directories - don't recurse
	Slim::Utils::Scan::addToList(
		$items, $fulldir, 0, undef,  
		\&browser_addtolist_done, $current_player, $callback, 
		$httpClient, $params, $items, $response
	);

	# when this finishes, it calls the next function, browser_addtolist_done:
	#
	# return undef means we'll take care of sending the output to the
	# client (special case because we're going into the background)
	return undef;
}

sub browser_addtolist_done {
	my ($current_player, $callback, $httpClient, $params, $itemsref, $response) = @_;

	if (defined $params->{'dir'} && $params->{'dir'} eq '__playlists' && (Slim::Music::Import::countImporters())) {

		$::d_http && msg("just showing imported playlists\n");

		push @$itemsref, @{Slim::Music::Info::playlists()};

		if (Slim::Music::Import::stillScanning()) {
			$params->{'warn'} = 1;
		}
	}
	
	my $numitems = scalar @{$itemsref};
	
	$::d_http && msg("browser_addtolist_done with $numitems items (". scalar @{ $itemsref } . " " . $params->{'dir'} . ")\n");

	$params->{'browse_list'} = " ";

	if ($numitems) {

		my ($start, $end, $cover, $thumb, $lastAnchor) = '';

		my $otherparams = '&';
		
		$otherparams .= 'dir=' . Slim::Web::HTTP::escape($params->{'dir'}) . '&' if ($params->{'dir'});
		$otherparams .= 'player=' . Slim::Web::HTTP::escape($current_player) . '&' if ($current_player);

		if (defined $params->{'nopagebar'}) {

			($start, $end) = simpleHeader(
				$numitems,
				 \$params->{'start'},
				\$params->{'browselist_header'},
				$params->{'skinOverride'},
				$params->{'itemsPerPage'},
				0,
			);

		} else {

			($start, $end) = pageBar(
				$numitems,
				$params->{'path'},
				0,
				$otherparams,
				\$params->{'start'},
				\$params->{'browselist_header'},
				\$params->{'browselist_pagebar'},
				$params->{'skinOverride'},
				$params->{'itemsPerPage'},
			);
		}

		my $itemnumber = $start;
		my $offset     = $start % 2 ? 0 : 1;
		my $filesort   = Slim::Utils::Prefs::get('filesort');

		# don't look up cover art info if we're browsing a playlist.
		if ($params->{'dir'} && $params->{'dir'} =~ /^__playlists/) {

			$thumb = 1;
			$cover = 1;

		} else {

			if (scalar(@{$itemsref}) > 1) {

				my %list_form = %$params;

				$list_form{'title'}        = string('ALL_SUBFOLDERS');
				$list_form{'nobrowse'}     = 1;
				$list_form{'itempath'}     = Slim::Utils::Misc::virtualToAbsolute($params->{'dir'});
				$list_form{'player'}       = $current_player;
				$list_form{'descend'}      = 1;
				$list_form{'odd'}	   = 0;
				$list_form{'skinOverride'} = $params->{'skinOverride'};

				$itemnumber++;
				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browse_list.html", \%list_form)};
			}
		}
		
		for my $item (@{$itemsref}[$start..$end]) {
			
			# make sure the players get some time...
			::idleStreams();
			
			# don't display and old unsaved playlist
			next if $item =~ /__current.m3u$/;

			my %list_form = %$params;
			
			# There are different templates for directories and playlist items:
			my $shortitem = Slim::Utils::Misc::descendVirtual($params->{'dir'}, $item, $itemnumber);

			if (Slim::Music::Info::isList($item)) {

				$list_form{'descend'} = $shortitem;

			} elsif (Slim::Music::Info::isSong($item)) {

				$list_form{'descend'} = 0;

				if (!defined $cover) {

					if (my $body = (Slim::Music::Info::coverArt($item, 'cover'))[0]) {
						$params->{'coverart'} = 1;
						$params->{'coverartpath'} = $shortitem;
					}

					$cover = $item;
				}

				if (!defined $thumb) {

					if (my $body = (Slim::Music::Info::coverArt($item, 'thumb'))[0]) {
						$params->{'coverthumb'} = 1;
						$params->{'thumbpath'} = $shortitem;
					}

					$thumb = $item;
				}
			}

			if ($filesort) {

				$list_form{'title'}  = Slim::Music::Info::fileName($item);

			} else {

				my $webFormat = Slim::Utils::Prefs::getInd("titleFormat",Slim::Utils::Prefs::get("titleFormatWeb"));

				$list_form{'includeArtist'} = ($webFormat !~ /ARTIST/);
				$list_form{'includeAlbum'}  = ($webFormat !~ /ALBUM/) ;
				$list_form{'title'}         = Slim::Music::Info::standardTitle(undef, $item);
				$list_form{'artist'}        = Slim::Music::Info::artist($item);
				$list_form{'album'}         = Slim::Music::Info::album($item);
			}
			
			$list_form{'itempath'}            = Slim::Utils::Misc::virtualToAbsolute($item);
			$list_form{'odd'}	  	  = ($itemnumber + $offset) % 2;
			$list_form{'player'}	          = $current_player;
			$list_form{'mixable_not_descend'} = Slim::Music::Info::isSongMixable($item);

			my $anchor = anchor(Slim::Utils::Text::getSortName($list_form{'title'}),1);

			if ($lastAnchor && $lastAnchor ne $anchor) {
				$list_form{'anchor'} = $lastAnchor = $anchor;
			}

			$list_form{'skinOverride'} = $params->{'skinOverride'};

			$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile(
				($params->{'playlist'} ? "browse_playlist_list.html" : "browse_list.html"), \%list_form
			)};

			$itemnumber++;
		}

	} else {

		$params->{'browse_list'} = ${Slim::Web::HTTP::filltemplatefile(
			"browse_list_empty.html", {'skinOverride' => $params->{'skinOverride'}}
		)};
	}

	my $output = Slim::Web::HTTP::filltemplatefile(($params->{'playlist'} ? "browse_playlist.html" : "browse.html"), $params);

	$callback->($current_player, $params, $output, $httpClient, $response);
}

# Send the status page (what we're currently playing, contents of the playlist)
sub status_header {
	my ($client, $params, $callback, $httpClient, $response) = @_;

	$params->{'omit_playlist'} = 1;

	return status(@_);
}

sub status {
	my ($client, $params, $callback, $httpClient, $response) = @_;

	_addPlayerList($client, $params);

	$params->{'refresh'} = Slim::Utils::Prefs::get('refreshRate');
	
	if (!defined($client)) {

		# fixed faster rate for noclients
		$params->{'refresh'} = 10;
		return Slim::Web::HTTP::filltemplatefile("status_noclients.html", $params);

	} elsif ($client->needsUpgrade()) {

		$params->{'player_needs_upgrade'} = 1;
		$params->{'modestop'} = 'Stop';
		return Slim::Web::HTTP::filltemplatefile("status_needs_upgrade.html", $params);
	}

	my $current_player;
	my $songcount = 0;
	 
	if (defined($client)) {

		$songcount = Slim::Player::Playlist::count($client);
		
		if ($client->defaultName() ne $client->name()) {
			$params->{'player_name'} = $client->name();
		}

		if (Slim::Player::Playlist::shuffle($client) == 1) {
			$params->{'shuffleon'} = "on";
		} elsif (Slim::Player::Playlist::shuffle($client) == 2) {
			$params->{'shufflealbum'} = "album";
		} else {
			$params->{'shuffleoff'} = "off";
		}
	
		$params->{'songtime'} = int(Slim::Player::Source::songTime($client));

		if (Slim::Player::Playlist::song($client)) { 
			my $dur = Slim::Music::Info::durationSeconds(Slim::Player::Playlist::song($client));
			if ($dur) { $dur = int($dur); }
			$params->{'durationseconds'} = $dur; 
		}

		#
		if (!Slim::Player::Playlist::repeat($client)) {
			$params->{'repeatoff'} = "off";
		} elsif (Slim::Player::Playlist::repeat($client) == 1) {
			$params->{'repeatone'} = "one";
		} else {
			$params->{'repeatall'} = "all";
		}

		#
		if (Slim::Player::Source::playmode($client) eq 'play') {

			$params->{'modeplay'} = "Play";

			if (defined($params->{'durationseconds'}) && defined($params->{'songtime'})) {

				my $remaining = $params->{'durationseconds'} - $params->{'songtime'};

				if ($remaining < $params->{'refresh'}) {	
					$params->{'refresh'} = ($remaining < 5) ? 5 : $remaining;
				}
			}

		} elsif (Slim::Player::Source::playmode($client) eq 'pause') {

			$params->{'modepause'} = "Pause";
		
		} else {
			$params->{'modestop'} = "Stop";
		}

		#
		if (Slim::Player::Source::rate($client) > 1) {
			$params->{'rate'} = 'ffwd';
		} elsif (Slim::Player::Source::rate($client) < 0) {
			$params->{'rate'} = 'rew';
		} else {
			$params->{'rate'} = 'norm';
		}
		
		$params->{'rateval'} = Slim::Player::Source::rate($client);
		$params->{'sync'}    = Slim::Player::Sync::syncwith($client);
		$params->{'mode'}    = Slim::Buttons::Common::mode($client);

		if ($client->isPlayer()) {

			$params->{'sleeptime'} = $client->currentSleepTime();
			$params->{'isplayer'}  = 1;
			$params->{'volume'}    = int($client->volume() + 0.5);
			$params->{'bass'}      = int($client->bass() + 0.5);
			$params->{'treble'}    = int($client->treble() + 0.5);
			$params->{'pitch'}     = int($client->pitch() + 0.5);

			my $sleep = $client->sleepTime() - Time::HiRes::time();
			$params->{'sleep'} = $sleep < 0 ? 0 : int($sleep/60);
		}
		
		$params->{'fixedVolume'} = !Slim::Utils::Prefs::clientGet($client, 'digitalVolumeControl');
		$params->{'player'} = $client->id();
	}
	
	if ($songcount > 0) {
		my $song = Slim::Player::Playlist::song($client);
		$params->{'currentsong'} = Slim::Player::Source::currentSongIndex($client) + 1;
		$params->{'thissongnum'} = Slim::Player::Source::currentSongIndex($client);
		$params->{'songcount'}   = $songcount;
		$params->{'itempath'}    = $song;

		_addSongInfo($client, $params);

		# for current song, display the playback bitrate instead.
		my $undermax = Slim::Player::Source::underMax($client,$song);
		if (defined $undermax && !$undermax) {
			$params->{'bitrate'} = string('CONVERTED_TO')." ".Slim::Utils::Prefs::maxRate($client).Slim::Utils::Strings::string('KBPS').' CBR';
		}
		if (Slim::Utils::Prefs::get("playlistdir")) {
			$params->{'cansave'} = 1;
		}
	}
	
	if (!$params->{'omit_playlist'}) {

		$params->{'callback'} = $callback;

		$params->{'playlist'} = playlist($client, $params, \&status_done, $httpClient, $response);

		if (!$params->{'playlist'}) {
			# playlist went into background, stash $callback and exit
			return undef;
		} else {
			$params->{'playlist'} = ${$params->{'playlist'}};
		}
	} else {
		# Special case, we need the playlist info even if we don't want
		# the playlist itself
		if ($client && $client->currentPlaylist()) {
			$params->{'current_playlist'} = $client->currentPlaylist();
			$params->{'current_playlist_modified'} = $client->currentPlaylistModified();
			$params->{'current_playlist_name'} = Slim::Music::Info::standardTitle($client, $client->currentPlaylist());
		}
	}

	$params->{'nosetup'} = 1   if $::nosetup;

	return Slim::Web::HTTP::filltemplatefile($params->{'omit_playlist'} ? "status_header.html" : "status.html" , $params);
}

sub status_done {
	my ($client, $params, $bodyref, $httpClient, $response) = @_;

	$params->{'playlist'} = $$bodyref;

	my $output = Slim::Web::HTTP::filltemplatefile("status.html" , $params);

	$params->{'callback'}->($client, $params, $output, $httpClient, $response);
}

sub playlist {
	my ($client, $params, $callback, $httpClient, $response) = @_;
	
	if (defined($client) && $client->needsUpgrade()) {

		$params->{'player_needs_upgrade'} = '1';
		return Slim::Web::HTTP::filltemplatefile("playlist_needs_upgrade.html", $params);
	}

	$params->{'playercount'} = Slim::Player::Client::clientCount();
	
	my $songcount = 0;

	if (defined($client)) {
		$songcount = Slim::Player::Playlist::count($client);
	}

	$params->{'playlist_items'} = '';
	if ($client && $client->currentPlaylist()) {
		$params->{'current_playlist'} = $client->currentPlaylist();
		$params->{'current_playlist_modified'} = $client->currentPlaylistModified();
		$params->{'current_playlist_name'} = Slim::Music::Info::standardTitle($client,$client->currentPlaylist());
	}

	if ($songcount > 0) {

		my %listBuild = ();
		my $item;
		my %list_form;

		if (Slim::Utils::Prefs::get("playlistdir")) {
			$params->{'cansave'} = 1;
		}
		
		my ($start, $end);
		
		if (defined $params->{'nopagebar'}) {

			($start, $end) = simpleHeader(
				$songcount,
				\$params->{'start'},
				\$params->{'playlist_header'},
				$params->{'skinOverride'},
				$params->{'itemsPerPage'},
				0
			);

		} else {

			($start, $end) = pageBar(
				$songcount,
				$params->{'path'},
				Slim::Player::Source::currentSongIndex($client),
				"player=" . Slim::Web::HTTP::escape($client->id()) . "&", 
				\$params->{'start'}, 
				\$params->{'playlist_header'},
				\$params->{'playlist_pagebar'},
				$params->{'skinOverride'}
				,$params->{'itemsPerPage'}
			);
		}

		$listBuild{'start'} = $start;
		$listBuild{'end'}   = $end;

		$listBuild{'offset'} = $listBuild{'start'} % 2 ? 0 : 1; 

		my $webFormat = Slim::Utils::Prefs::getInd("titleFormat",Slim::Utils::Prefs::get("titleFormatWeb"));

		$listBuild{'includeArtist'} = ($webFormat !~ /ARTIST/);
		$listBuild{'includeAlbum'}  = ($webFormat !~ /ALBUM/) ;
		$listBuild{'currsongind'}   = Slim::Player::Source::currentSongIndex($client);
		$listBuild{'item'}          = $listBuild{'start'};

		if (buildPlaylist($client, $params, $callback, $httpClient, $response, \%listBuild)) {

			Slim::Utils::Scheduler::add_task(
				\&buildPlaylist,
				$client,
				$params,
				$callback,
				$httpClient,
				$response,
				\%listBuild,
			);
		}

		return undef;
	}

	return Slim::Web::HTTP::filltemplatefile("playlist.html", $params);
}

sub _addPlayerList {
	my ($client, $params) = @_;

	$params->{'playercount'} = Slim::Player::Client::clientCount();
	
	my @players = Slim::Player::Client::clients();

	if (scalar(@players) > 1) {

		my %clientlist = ();

		for my $eachclient (@players) {

			$clientlist{$eachclient->id()} =  $eachclient->name();

			if (Slim::Player::Sync::isSynced($eachclient)) {
				$clientlist{$eachclient->id()} .= " (".string('SYNCHRONIZED_WITH')." ".
					Slim::Player::Sync::syncwith($eachclient).")";
			}	
		}

		$params->{'player_chooser_list'} = options($client->id(), \%clientlist, $params->{'skinOverride'});
	}
}

sub buildPlaylist {
	my ($client, $params, $callback, $httpClient, $response, $listBuild) = @_;

	my $itemCount    = 0;
	my $itemsPerPass = Slim::Utils::Prefs::get('itemsPerPass');
	my $starttime    = Time::HiRes::time();

	my $ds           = Slim::Music::Info::getCurrentDataStore();

	while ($listBuild->{'item'} < ($listBuild->{'end'} + 1) && $itemCount < $itemsPerPass) {

		my %list_form = %$params;

		$list_form{'myClientState'} = $client;
		$list_form{'num'}           = $listBuild->{'item'};
		$list_form{'odd'}           = ($listBuild->{'item'} + $listBuild->{'offset'}) % 2;

		if ($listBuild->{'item'} == $listBuild->{'currsongind'}) {
			$list_form{'currentsong'} = "current";
		} else {
			$list_form{'currentsong'} = undef;
		}

		$list_form{'nextsongind'} = $listBuild->{'currsongind'} + (($listBuild->{'item'} > $listBuild->{'currsongind'}) ? 1 : 0);

		my $song = Slim::Player::Playlist::song($client, $listBuild->{'item'});

		$list_form{'player'}   = $params->{'player'};
		$list_form{'title'}    = Slim::Music::Info::standardTitle(undef,$song);

		# XXX - convert to use item/ds
		$list_form{'itempath'} = $song;

		my $track = $ds->objectForUrl($song) || do {
			$::d_info && Slim::Utils::Misc::msg("Couldn't retrieve objectForUrl: [$song] - skipping!\n");
			next;
		};

		$list_form{'artist'} = $listBuild->{'includeArtist'} ? $track->artist() : undef;
		$list_form{'album'}  = $listBuild->{'includeAlbum'}  ? $track->album()->title() : undef;

		$list_form{'start'}	   = $params->{'start'};
		$list_form{'skinOverride'} = $params->{'skinOverride'};

		push @{$listBuild->{'playlist_items'}}, ${Slim::Web::HTTP::filltemplatefile("status_list.html", \%list_form)};

		$listBuild->{'item'}++;
		$itemCount++;

		# don't neglect the streams for over 0.25 seconds
		if ((Time::HiRes::time() - $starttime) > 0.25) {
			::idleStreams() ;
		}
	}

	if ($listBuild->{'item'} < $listBuild->{'end'} + 1) {

		return 1;

	} else {

		if (defined $listBuild->{'playlist_items'}) {
			$params->{'playlist_items'} = join('', @{$listBuild->{'playlist_items'}});
		}

		undef %$listBuild;

		playlist_done($client, $params, $callback, $httpClient, $response);

		return 0;
	}
}

sub playlist_done {
	my ($client, $params, $callback, $httpClient, $response) = @_;
	$params->{'playercount'} = Slim::Player::Client::clientCount();
	my $body = Slim::Web::HTTP::filltemplatefile("playlist.html", $params);

	if (ref($callback) eq 'CODE') {

		$callback->($client, $params, $body, $httpClient, $response);
	}
}

# Call into the memory usage class - this will return live data about memory
# usage, opcodes, and more. Note that loading this takes up memory itself!
sub memory_usage {
	my ($client, $params) = @_;

	my $item    = $params->{'item'};
	my $type    = $params->{'type'};
	my $command = $params->{'command'};

	unless ($item && $command) {

		return Slim::Utils::MemoryUsage->status_memory_usage();
	}

	if (defined $item && defined $command && Slim::Utils::MemoryUsage->can($command)) {

		return Slim::Utils::MemoryUsage->$command($item, $type);
	}
}

# XXX - this should really be broken up into smaller functions.
sub search {
	my ($client, $params) = @_;

	$params->{'browse_list'} = " ";
	$params->{'numresults'}  = -1;

	my $player = $params->{'player'};
	my $query  = $params->{'query'};

	# short circuit
	unless ($query) {
		return Slim::Web::HTTP::filltemplatefile("search.html", $params);
	}

	my $ds = Slim::Music::Info::getCurrentDataStore();

	my $otherparams = 'player=' . Slim::Web::HTTP::escape($player) . 
			  '&type=' . ($params->{'type'} ? $params->{'type'} : ''). 
			  '&query=' . Slim::Web::HTTP::escape($params->{'query'}) . '&';

	my $searchStrings = searchStringSplit($query,$params->{'searchSubString'});

	# artist and album are similar enough - move them to their own function
	if ($params->{'type'} eq 'artist') {

		my $results = $ds->find('contributor', { "contributor.name" => $searchStrings }, 'name');

		_searchArtistOrAlbum($player, $params, $results, $otherparams);

	} elsif ($params->{'type'} eq 'album') {

		my $results = $ds->find('album', { "album.title" => $searchStrings }, 'title');

		_searchArtistOrAlbum($player, $params, $results, $otherparams);

	} elsif ($params->{'type'} eq 'song') {

		my $sortBy  = 'title';
		my %find    = ();

		for my $string (@{$searchStrings}) {
			push @{$find{'track.title'}}, [ $string ];
		}

		my $results = $ds->find('track', \%find, $sortBy);

		$params->{'numresults'} = scalar @$results;

		my $itemnumber = 0;
		my $lastAnchor = '';

		if ($params->{'numresults'}) {

			my ($start, $end);

			if (defined $params->{'nopagebar'}){

				($start, $end) = simpleHeader(
					$params->{'numresults'},
					\$params->{'start'},
					\$params->{'browselist_header'},
					$params->{'skinOverride'},
					$params->{'itemsPerPage'},
					0
				);

			} else {

				($start, $end) = pageBar(
					$params->{'numresults'},
					$params->{'path'},
					0,
					$otherparams,
					\$params->{'start'},
					\$params->{'searchlist_header'},
					\$params->{'searchlist_pagebar'},
					$params->{'skinOverride'},
					$params->{'itemsPerPage'},
				);
			}
			
			my $webFormat = Slim::Utils::Prefs::getInd("titleFormat",Slim::Utils::Prefs::get("titleFormatWeb"));

			for my $item (@$results[$start..$end]) {

				my %list_form = %$params;

				$list_form{'includeArtist'} = ($webFormat !~ /ARTIST/);
				$list_form{'includeAlbum'}  = ($webFormat !~ /ALBUM/) ;

				$list_form{'genre'}	   = $item->genre();
				$list_form{'artist'}       = $item->artist();
				$list_form{'album'}	   = $item->album();
				$list_form{'itempath'}     = $item->url();
				$list_form{'title'}        = Slim::Music::Info::standardTitle(undef, $item);
				$list_form{'descend'}      = undef;
				$list_form{'player'}       = $player;
				$list_form{'odd'}	   = ($itemnumber + 1) % 2;
				$list_form{'skinOverride'} = $params->{'skinOverride'};

				$itemnumber++;

				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_list.html", \%list_form)};
			}
		}
	}

	return Slim::Web::HTTP::filltemplatefile("search.html", $params);
}

sub _searchArtistOrAlbum {
	my ($player, $params, $searchresults, $otherparams) = @_;

	$params->{'numresults'} = scalar @$searchresults;

	my $descend    = 'true';
	my $itemnumber = 0;
	my $lastAnchor = '';

	if ($params->{'numresults'}) {
	
		my ($start, $end);

		if (defined $params->{'nopagebar'}) {

			($start, $end) = simpleHeader(
				$params->{'numresults'},
				\$params->{'start'},
				\$params->{'browselist_header'},
				$params->{'skinOverride'},
				$params->{'itemsPerPage'},
				0
			);

		} else {

			($start, $end) = alphaPageBar(
				$searchresults,
				$params->{'path'},
				$otherparams,
				\$params->{'start'},
				\$params->{'searchlist_pagebar'},
				1,
				$params->{'skinOverride'},
				$params->{'itemsPerPage'},
			);
		}

		# 
		for my $item (@$searchresults[$start..$end]) {

			# Contributor/Artist uses name, Album uses title.
			my $title     = $item->can('title') ? $item->title() : $item->name();
			my %list_form = %$params;

			$list_form{'genre'}	   = '*';
			$list_form{'artist'}       = $params->{'type'} eq 'artist' ? $title : '*';
			$list_form{'album'}        = $params->{'type'} eq 'album'  ? $title : '';
			$list_form{'song'}	   = '';
			$list_form{'title'}        = $title;
			$list_form{'descend'}      = $descend;
			$list_form{'player'}       = $player;
			$list_form{'odd'}	   = ($itemnumber + 1) % 2;
			$list_form{'skinOverride'} = $params->{'skinOverride'};

			my $anchor = anchor(Slim::Utils::Text::getSortName($title), 1);

			if ($lastAnchor ne $anchor) {
				$list_form{'anchor'} = $lastAnchor = $anchor;
			}

			$itemnumber++;

			$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_list.html", \%list_form)};
		}
	}
}

sub _addSongInfo {
	my ($client, $params) = @_;

	# 
	my $song = $params->{'itempath'};
	my $id   = $params->{'item'};

	# kinda pointless, but keeping with compatibility
	return unless $song || $id;

	my $ds = Slim::Music::Info::getCurrentDataStore();
	my $track;

	if ($song) {

		$track = $ds->objectForUrl($song, 0);

	} elsif ($id) {

		$track = $ds->objectForId('track', $id);
		$song  = $track->url() if $track;
	}

	if ($track) {

		# These are all lists
		$params->{'genre'}     = join(', ', map { $_->name() } $track->genres());
		$params->{'artist'}    = join(', ', map { $_->name() } $track->contributors());
		$params->{'composer'}  = join(', ', map { $_->name() } $track->contributorsOfType('composer'));
		$params->{'band'}      = join(', ', map { $_->name() } $track->contributorsOfType('band'));
		$params->{'conductor'} = join(', ', map { $_->name() } $track->contributorsOfType('conductor'));

		# Do we have an album associated with this track?
		if (my $album = $track->album()) {

			$params->{'album'}   = $album->title();
			$params->{'albumid'} = $album->id();
			$params->{'disc'}    = $album->disc();
		}

		# Generic items
		for my $item (qw(title track bpm year tagversion bitrate drm)) {

			$params->{$item} = $track->$item();
		}

		$params->{'filelength'} = Slim::Utils::Misc::delimitThousands($track->filesize());
		$params->{'songtitle'}  = Slim::Music::Info::standardTitle(undef, $track);
		$params->{'duration'}   = Slim::Music::Info::duration($song);
		$params->{'bitrate'}    = Slim::Music::Info::bitrate($song);
		$params->{'type'}       = string(uc($track->content_type()));
		$params->{'mixable'}    = Slim::Music::Info::isSongMixable($song);

		$params->{'modtime'}    = Slim::Utils::Misc::longDateF($track->timestamp()) . ", " .
					  Slim::Utils::Misc::timeF($track->timestamp());

		# make urls in comments into links
		for my $comment ($track->comments()) {

			if (!($comment =~ s!\b(http://[\-~A-Za-z0-9_/\.]+)!<a href=\"$1\" target=\"_blank\">$1</a>!igo)) {

				# handle emusic-type urls which don't have http://
				$comment =~ s!\b(www\.[\-~A-Za-z0-9_/\.]+)!<a href=\"http://$1\" target=\"_blank\">$1</a>!igo;
			}

			$params->{'comment'} .= $comment;
		}
	}
	
	# handle artwork bits
	# XXX - this should be a method on $track
	if (my $body = (Slim::Music::Info::coverArt($song,'cover'))[0]) {
		$params->{'coverart'} = 1;
	}

	# XXX - this should be a method on $track
	if (my $body = (Slim::Music::Info::coverArt($song,'thumb'))[0]) {
		$params->{'coverthumb'} = 1;
	}
	
	my $downloadurl;

	if (Slim::Music::Info::isHTTPURL($song)) {

		$downloadurl = $song;

	} else {

		my $loc  = $song;

		if (Slim::Music::Info::isFileURL($song)) {
			$loc = Slim::Utils::Misc::pathFromFileURL($loc);
		}

		my $curdir = Slim::Utils::Prefs::get('audiodir');

		if (!$curdir) {
			$downloadurl = undef;
		} elsif ($loc =~ /^\Q$curdir\E(.*)/i) {

			$downloadurl = '/music';

			for my $item (splitdir($1)) {
				$downloadurl .= '/' . Slim::Web::HTTP::escape($item);
			}

			$downloadurl =~ s/\/\//\//;

		} else {

			$downloadurl = $loc;
		}
	}

	$params->{'itempath'} = $song;
	$params->{'download'} = $downloadurl;
}

sub songInfo {
	my ($client, $params) = @_;

	_addSongInfo($client, $params);

	return Slim::Web::HTTP::filltemplatefile("songinfo.html", $params);
}

sub generate_pwd_list {
	my ($genre, $artist, $album, $player) = @_;

	my $pwd_list = "";

	if (defined($genre) && $genre eq '*' && defined($artist) && $artist eq '*') {

		my %list_form = (
			'song'    => '',
			'album'   => '',
			'artist'  => '*',
			'genre'   => '*',
			'player'  => $player,
			'pwditem' => string('BROWSE_BY_ALBUM'),
		);

		$pwd_list .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};

	} elsif (defined($genre) && $genre eq '*') {

		my %list_form = (
			'song'    => '',
			'artist'  => '',
			'album'   => '',
			'genre'   => '*',
			'player'  => $player,
			'pwditem' => string('BROWSE_BY_ARTIST'),
		);

		$pwd_list .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};

	} else {

		my %list_form = (
			'song'    => '',
			'artist'  => '',
			'album'   => '',
			'genre'   => '',
			'player'  => $player,
			'pwditem' => string('BROWSE_BY_GENRE'),
		);

		$pwd_list .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};
	}

	#
	if ($genre && $genre ne '*') {

		my %list_form = (
			'song'    => '',
			'artist'  => '',
			'album'   => '',
			'genre'   => $genre,
			'player'  => $player,
			'pwditem' => $genre,
		);

		$pwd_list .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};
	}

	#
	if ($artist && $artist ne '*') {

		my %list_form = (
			'song'    => '',
			'album'   => '',
			'artist'  => $artist,
			'genre'   => $genre,
			'pwditem' => $artist,
			'player'  => $player,
		);

		$pwd_list .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};
	}

	if ($album && $album ne '*') {

		my %list_form = (
			'song'    => '',
			'album'   => $album,
			'artist'  => $artist,
			'genre'   => $genre,
			'pwditem' => $album,
			'player'  => $player,
		);

		$pwd_list .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};
	}
	
	return $pwd_list;
}

# XXX FIXME The fieldInfo type structure, at some level, is going to
# be needed here, in the command code (for playlist commands), and in
# the browse menu code. The following method is a placeholder till we
# figure out how to share it.
sub queryFields {
	return keys %fieldInfo;
}

sub browsedb {
	my ($client, $params) = @_;

	# XXX - why do we default to genre?
	my $hierarchy = $params->{'hierarchy'} || "genre";
	my $level     = $params->{'level'} || 0;
	my $player    = $params->{'player'};

	$::d_info && msg("browsedb - hierarchy: $hierarchy level: $level\n");

	my @levels = split(",", $hierarchy);

	my $maxLevel = scalar(@levels) - 1;

	if ($level > $maxLevel)	{
		$level = $maxLevel;
	}

	my $ds = Slim::Music::Info::getCurrentDataStore();

	my $itemnumber = 0;
	my $lastAnchor = '';
	my $descend;
	my %names = ();
	my @attrs = ();
	my %findCriteria = ();	

	for my $field (@levels) {

		my $info = $fieldInfo{$field} || $fieldInfo{'default'};

		# XXX - is this the right thing to do?
		# For artwork browsing - we want to display the album.
		if (my $transform = $info->{'nameTransform'}) {
			push @levels, $transform;
		}

		# If we don't have this check, we'll create a massive query
		# for each level in the hierarchy, even though it's not needed
		next unless defined $params->{$field};

		$names{$field} = &{$info->{'idToName'}}($ds, $params->{$field});
	}

	# Just go directly to the params.
	_addStats($params, [$params->{'genre'}], [$params->{'artist'}], [$params->{'album'}], [$params->{'song'}]);

	# warn the user if the scanning isn't complete.
	if (Slim::Utils::Misc::stillScanning()) {
		$params->{'warn'} = 1;
	}

	if (Slim::Music::iTunes::useiTunesLibrary()) {
		$params->{'itunes'} = 1;
	}

	# This pulls the appropriate anonymous function list out of the
	# fieldInfo hash, which we then retrieve data from.
	my $firstLevelInfo = $fieldInfo{$levels[0]} || $fieldInfo{'default'};
	my $title = $params->{'browseby'} = $firstLevelInfo->{'title'};

	for my $key (keys %fieldInfo) {

		if (defined($params->{$key})) {

			# Populate the find criteria with all query parameters in the URL
			$findCriteria{$key} = $params->{$key};

			# Pre-populate the attrs list with all query parameters that 
			# are not part of the hierarchy. This allows a URL to put
			# query constraints on a hierarchy using a field that isn't
			# necessarily part of the hierarchy.
			if (!grep {$_ eq $key} @levels) {
				push @attrs, $key . '=' . Slim::Web::HTTP::escape($params->{$key});
			}
		}
	}

	my %list_form = (
		'player'       => $player,
		'pwditem'      => string($title),
		'skinOverride' => $params->{'skinOverride'},
		'title'	       => $title,
		'hierarchy'    => $hierarchy,
		'level'	       => 0,
		'attributes'   => (scalar(@attrs) ? ('&' . join("&", @attrs)) : ''),
	);

	$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("browsedb_pwdlist.html", \%list_form)};

	for (my $i = 0; $i < $level ; $i++) {

		my $attr = $levels[$i];

		# XXX - is this the right thing to do?
		# For artwork browsing - we want to display the album.
		if (my $transform = $firstLevelInfo->{'nameTransform'}) {
			$attr = $transform;
		}

		if ($params->{$attr}) {

			push @attrs, $attr . '=' . Slim::Web::HTTP::escape($params->{$attr});

			my %list_form = (
				 'player'       => $player,
				 'pwditem'      => $names{$attr},
				 'skinOverride' => $params->{'skinOverride'},
				 'title'	=> $title,
				 'hierarchy'	=> $hierarchy,
				 'level'	=> $i+1,
				 'attributes'   => (scalar(@attrs) ? ('&' . join("&", @attrs)) : ''),
			 );
			
			$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("browsedb_pwdlist.html", \%list_form)};
		}
	}

	my $otherparams = join('&',
		'player=' . Slim::Web::HTTP::escape($player || ''),
		"hierarchy=$hierarchy",
		"level=$level",
		@attrs,
	);

	my $levelInfo = $fieldInfo{$levels[$level]} || $fieldInfo{'default'};
	my $items     = &{$levelInfo->{'find'}}($ds, $levels[$level], \%findCriteria);

	if ($items && scalar(@$items)) {

		my ($start, $end);

		my $ignoreArticles = $levelInfo->{'ignoreArticles'};
		my $alpha = $levelInfo->{'alphaPageBar'};

		if (defined $params->{'nopagebar'}) {

			($start, $end) = simpleHeader(
				scalar(@$items),
				\$params->{'start'},
				\$params->{'browselist_header'},
				$params->{'skinOverride'},
				$params->{'itemsPerPage'},
				$ignoreArticles ? (scalar(@$items) > 1) : 0,
			);

		} elsif ($alpha) {
			
			my $alphaitems = [ map &{$levelInfo->{'resultToName'}}($_), @$items ];

			($start, $end) = alphaPageBar(
				$alphaitems,
				$params->{'path'},
				$otherparams,
				\$params->{'start'},
				\$params->{'browselist_pagebar'},
				$ignoreArticles, 
				$params->{'skinOverride'},
				$params->{'itemsPerPage'},
			);

		} else {

			($start, $end) = pageBar(
				scalar(@$items),
				$params->{'path'},
				0,
				$otherparams,
				\$params->{'start'},
				\$params->{'browselist_header'},
				\$params->{'browselist_pagebar'},
				$params->{'skinOverride'},
				$params->{'itemsPerPage'},
			);
		}

		$descend = ($level >= $maxLevel) ? undef : 'true';

		if (scalar(@$items) > 1 && !$levelInfo->{'suppressAll'}) {

			if ($params->{'includeItemStats'} && !Slim::Utils::Misc::stillScanning()) {
				# XXX include statistics
			}

			my $nextLevelInfo;

			if ($descend) {
				my $nextLevel  = $levels[$level+1];
				$nextLevelInfo = $fieldInfo{$nextLevel} || $fieldInfo{'default'};
			} else {
				$nextLevelInfo = $fieldInfo{'track'};
			}

			if ($level == 0) {
				$list_form{'hierarchy'}	= join(',', @levels[1..$#levels]);
				$list_form{'level'}	= 0;
			} else {
				$list_form{'hierarchy'}	= $hierarchy;
				$list_form{'level'}	= $descend ? $level+1 : $level;
			}

			$list_form{'text'} = string($nextLevelInfo->{'allTitle'});

			$list_form{'descend'}      = 1;
			$list_form{'player'}       = $player;
			$list_form{'odd'}	   = ($itemnumber + 1) % 2;
			$list_form{'skinOverride'} = $params->{'skinOverride'};
			$list_form{'attributes'}   = (scalar(@attrs) ? ('&' . join("&", @attrs)) : '');
				
			$itemnumber++;
				
			$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browsedb_list.html", \%list_form)};
		}

		for my $item ( @{$items}[$start..$end] ) {

			my %list_form = %$params;

			my $itemid   = &{$levelInfo->{'resultToId'}}($item);
			my $itemname = &{$levelInfo->{'resultToName'}}($item);
			my $attrName = $levelInfo->{'nameTransform'} || $levels[$level];

			$list_form{'hierarchy'}	    = $hierarchy;
			$list_form{'level'}	    = $level + 1;
			$list_form{'attributes'}    = (scalar(@attrs) ? ('&' . join("&", @attrs)) : '') . '&' .
				$attrName . '=' . Slim::Web::HTTP::escape($itemid);

			$list_form{'text'}	    = $itemname;
			$list_form{'descend'}	    = $descend;
			$list_form{'player'}	    = $player;
			$list_form{'odd'}	    = ($itemnumber + 1) % 2;
			$list_form{$levels[$level]} = $itemid;
			$list_form{'skinOverride'}  = $params->{'skinOverride'};
			$list_form{'itemnumber'}    = $itemnumber;

			# This is calling into the %fieldInfo hash
			&{$levelInfo->{'listItem'}}($ds, \%list_form, $item, $itemname, $descend);

			my $anchor = Slim::Web::Pages::anchor(Slim::Utils::Text::getSortName($itemname), $ignoreArticles);

			if ($lastAnchor && $lastAnchor ne $anchor) {
				$list_form{'anchor'} = $lastAnchor = $anchor;
			}

			$itemnumber++;

			if ($levels[$level] eq 'artwork') {
				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browsedb_artwork.html", \%list_form)};
			} else {
				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browsedb_list.html", \%list_form)};
			}

			main::idleStreams();
		}

		if ($level == $maxLevel && $levels[$level] eq 'track') {

			# XXX - this should be a method on $track
			if (my $body = (Slim::Music::Info::coverArt($items->[$start]->url))[0]) {
				$params->{'coverart'} = 1;
				$params->{'coverartpath'} = $items->[$start]->url;
			}
		}
	}

	$params->{'descend'} = $descend;
	
	return Slim::Web::HTTP::filltemplatefile("browseid3.html", $params);
}

# Implement browseid3 in terms of browsedb.
sub browseid3 {
	my ($client, $params) = @_;

	my @hierarchy  = ();
	my %categories = (
		'genre'  => 'genre',
		'artist' => 'artist',
		'album'  => 'album',
		'song'   => 'track'
	);

	my $find  = {
		'player' => $params->{'player'},
		'level'  => 0,
	};

	my $ds = Slim::Music::Info::getCurrentDataStore();

	# Turn the browseid3 params into something browsedb can use.
	for my $category (keys %categories) {

		next unless $params->{$category};

		$find->{ $categories{$category} } = $params->{$category};
	}

	# These must be in order.
	for my $category (qw(genre artist album track)) {

		if (!defined $find->{$category}) {

			push @hierarchy, $category;

		} elsif ($find->{$category} eq '*') {

			delete $find->{$category};

		} elsif ($find->{$category}) {

			$find->{$category} = (@{$ds->search($category, [$find->{$category}])})[0];
		}
	}

	$find->{'hierarchy'} = join(',', @hierarchy);

	return browsedb($client, $find);
}

sub browseid3_old {
	my ($client, $params) = @_;

	my $limit  = $params->{'itemsPerPage'} || Slim::Utils::Prefs::get('itemsPerPage');
	my $offset = $params->{'start'} || 0;

	my $song   = $params->{'song'};
	my $artist = $params->{'artist'};
	my $album  = $params->{'album'};
	my $genre  = $params->{'genre'};
	my $player = $params->{'player'};

	my $itemnumber = 0;
	my $lastAnchor = '';
	my $descend;

	my $ds = Slim::Music::Info::getCurrentDataStore();

	# warn the user if the scanning isn't complete.
	if (Slim::Utils::Misc::stillScanning()) {
		$params->{'warn'} = 1;
	}

	if (defined(Slim::Utils::Prefs::get('audiodir'))) {
		$params->{'audiodir'} = 1;
	}

	# XXX
	_addStats($params, [$genre], [$artist], [$album], [$song]);

	if (defined($album) && $album eq '*' && 
		defined($genre) && $genre eq '*' && 
		defined($artist) && $artist eq '*') {

		my %list_form = (
			'song'         => '',
			'album'        => '*',
			'artist'       => '*',
			'genre'        => '*',
			'player'       => $player,
			'pwditem'      => string('BROWSE_BY_SONG'),
			'skinOverride' => $params->{'skinOverride'},
		);

		$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};
		$params->{'browseby'} = 'BROWSE_BY_SONG';

	} elsif (defined($genre) && $genre eq '*' && defined($artist) && $artist eq '*') {

		my %list_form = (
			'song'   => '',
			'album'  => '',
			'artist' => '*',
			'genre'  => '*',
			'player' => $player,
		);

		if ($params->{'artwork'}) {

			$list_form{'pwditem'}      = string('BROWSE_BY_ARTWORK');
			$list_form{'artwork'}      = 1;

			$params->{'browseby'} = 'BROWSE_BY_ARTWORK';

		} else {

			$list_form{'pwditem'}      = string('BROWSE_BY_ALBUM');

			$params->{'browseby'} = 'BROWSE_BY_ALBUM';
		}

		$list_form{'skinOverride'} = $params->{'skinOverride'};
		$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};

	} elsif (defined($genre) && $genre eq '*') {

		my %list_form = (
			'song'         => '',
			'artist'       => '',
			'album'        => '',
			'genre'        => '*',
			'player'       => $player,
			'pwditem'      => string('BROWSE_BY_ARTIST'),
			'skinOverride' => $params->{'skinOverride'},
		);

		$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};
		$params->{'browseby'} = 'BROWSE_BY_ARTIST';

	} else {

		my %list_form = (
			'song'         => '',
			'artist'       => '',
			'album'        => '',
			'genre'        => '',
			'player'       => $player,
			'pwditem'      => string('BROWSE_BY_GENRE'),
			'skinOverride' => $params->{'skinOverride'},
		);

		$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};
		$params->{'browseby'} = 'BROWSE_BY_GENRE';
	}

	if ($genre && $genre ne '*') {

		my %list_form = (
			'song'         => '',
			'artist'       => '',
			'album'        => '',
			'genre'        => $genre,
			'player'       => $player,
			'pwditem'      => $genre,
			'skinOverride' => $params->{'skinOverride'},
		);

		$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};
	}

	if ($artist && $artist ne '*') {

		my %list_form = (
			'song'         => '',
			'artist'       => $artist,
			'album'        => '',
			'genre'        => $genre,
			'player'       => $player,
			'pwditem'      => $artist,
			'skinOverride' => $params->{'skinOverride'},
		);

		$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};
	}

	if ($album && $album ne '*') {

		my %list_form = (
			'song'         => '',
			'artist'       => $artist,
			'album'        => $album,
			'genre'        => $genre,
			'player'       => $player,
			'pwditem'      => $album,
			'skinOverride' => $params->{'skinOverride'},
		);

		$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_pwdlist.html", \%list_form)};
	}

	my $otherparams = 
		'player='  . Slim::Web::HTTP::escape($player || '') . 
		'&genre='  . Slim::Web::HTTP::escape($genre  || '') . 
		'&artist=' . Slim::Web::HTTP::escape($artist || '') . 
		'&album='  . Slim::Web::HTTP::escape($album  || '') . 
		'&song='   . Slim::Web::HTTP::escape($song   || '') . '&';

	# XXX - more ick
	if (!$genre) {

		# Browse by Genre
		my $find = {};

		$find->{'contributor'} = [$artist] if _refCheck([$artist]);
		$find->{'album'}       = [$album]  if _refCheck([$album]);
		$find->{'track'}       = [$song]   if _refCheck([$song]);

		my $items = $ds->find('genre', $find, 'genre');

		my $numItems = scalar @$items;

		if ($numItems) {

			my ($start, $end);

			if (defined $params->{'nopagebar'}) {

				($start, $end) = simpleHeader(
					$numItems,
					\$params->{'start'},
					\$params->{'browselist_header'},
					$params->{'skinOverride'},
					$params->{'itemsPerPage'},
					0
				);

			} else {

				($start, $end) = alphaPageBar(
					$items,
					$params->{'path'},
					$otherparams,
					\$params->{'start'},
					\$params->{'browselist_pagebar'},
					0,
					$params->{'skinOverride'},
					$params->{'itemsPerPage'},
				);
			}

			$descend = 'true';
			
			if ($numItems > 1) {

				my %list_form = %$params;

				if ($params->{'includeItemStats'} && !Slim::Utils::Misc::stillScanning()) {

					$list_form{'album_count'} = $ds->count('album', { 'genre' => '*' });
					$list_form{'song_count'}  = $ds->count('track', { 'genre' => '*' });
				}

				$list_form{'genre'}	   = '*';
				$list_form{'artist'}       = '*';
				$list_form{'album'}	   = $album;
				$list_form{'song'}	   = $song;
				$list_form{'title'}        = string('ALL_ALBUMS');
				$list_form{'descend'}      = $descend;
				$list_form{'player'}       = $player;
				$list_form{'odd'}	   = ($itemnumber + 1) % 2;
				$list_form{'skinOverride'} = $params->{'skinOverride'};

				$itemnumber++;

				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_list.html", \%list_form)};
			}
			
			for my $item ( @$items[$start..$end] ) {

				my %list_form = %$params;

				if ($params->{'includeItemStats'} && !Slim::Utils::Misc::stillScanning()) {
					$list_form{'artist_count'} = $ds->count('artist', { 'genre' => $item });
					$list_form{'album_count'}  = $ds->count('album',  { 'genre' => $item });
					$list_form{'song_count'}   = $ds->count('track',  { 'genre' => $item });
				}

				$list_form{'genre'}	      = $item;
				$list_form{'artist'}          = $artist;
				$list_form{'album'}	      = $album;
				$list_form{'song'}	      = $song;
				$list_form{'title'}           = $item;
				$list_form{'descend'}         = $descend;
				$list_form{'player'}          = $player;
				$list_form{'odd'}	      = ($itemnumber + 1) % 2;
				$list_form{'mixable_descend'} = Slim::Music::Info::isGenreMixable($item) && ($descend eq "true");
				$list_form{'skinOverride'}    = $params->{'skinOverride'};

				my $anchor = anchor(Slim::Utils::Text::getSortName($item));

				if ($lastAnchor ne $anchor) {
					$list_form{'anchor'} = $lastAnchor = $anchor;
				}

				$itemnumber++;
				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_list.html", \%list_form)};
				
				::idleStreams();
			}
		}

	} elsif (!$artist) {

		# Browse by Artist
		#
		# Create a _buildCriteriaFromXXX function to bundle all this
		# up. Check other places it could be used.
		my $find = {};

		$find->{'genre'}       = [$genre]  if _refCheck([$genre]);
		$find->{'contributor'} = [$artist] if _refCheck([$artist]);
		$find->{'album'}       = [$album]  if _refCheck([$album]);

		my $items = $ds->find('artist', $find, 'artist');

		my $numItems = scalar @$items;
		
		if ($numItems) {

			my ($start, $end);

			if (defined $params->{'nopagebar'}) {
				($start, $end) = simpleHeader(
					$numItems,
					\$params->{'start'},
					\$params->{'browselist_header'},
					$params->{'skinOverride'},
					$params->{'itemsPerPage'},
					($numItems > 1)
				);

			} else {

				($start, $end) = alphaPageBar(
					$items,
					$params->{'path'},
					$otherparams,
					\$params->{'start'},
					\$params->{'browselist_pagebar'},
					1,
					$params->{'skinOverride'},
					$params->{'itemsPerPage'},
				);
			}

			$descend = 'true';

			if ($numItems > 1) {

				my %list_form = %$params;

				if ($params->{'includeItemStats'} && !Slim::Utils::Misc::stillScanning()) {
					$list_form{'album_count'} = $ds->count('album', { 'genre' => $genre, 'artist' => '*'});
					$list_form{'song_count'}  = $ds->count('track', { 'genre' => $genre, 'artist' => '*'});
				}

				$list_form{'genre'}	   = $genre;
				$list_form{'artist'}       = '*';
				$list_form{'album'}	   = $album;
				$list_form{'song'}	   = $song;
				$list_form{'title'}        = string('ALL_ALBUMS');
				$list_form{'descend'}      = $descend;
				$list_form{'player'}       = $player;
				$list_form{'odd'}	   = ($itemnumber + 1) % 2;
				$list_form{'skinOverride'} = $params->{'skinOverride'};

				$itemnumber++;

				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_list.html", \%list_form)};
			}
			
			for my $item ( @$items[$start..$end] ) {

				my %list_form = %$params;

				if ($params->{'includeItemStats'} && !Slim::Utils::Misc::stillScanning()) {
					$list_form{'album_count'} = $ds->count('album', { 'genre' => $genre, 'artist' => $item});
					$list_form{'song_count'}  = $ds->count('track', { 'genre' => $genre, 'artist' => $item});
				}

				$list_form{'genre'}	      = $genre;
				$list_form{'artist'}          = $item;
				$list_form{'album'}	      = $album;
				$list_form{'song'}	      = $song;
				$list_form{'title'}           = $item;
				$list_form{'descend'}         = $descend;
				$list_form{'player'}          = $player;
				$list_form{'odd'}	      = ($itemnumber + 1) % 2;
				$list_form{'mixable_descend'} = (Slim::Music::Info::isArtistMixable($item)) && ($descend eq "true");
				$list_form{'skinOverride'}    = $params->{'skinOverride'};

				my $anchor = anchor(Slim::Utils::Text::getSortName($item), 1);

				if ($lastAnchor ne $anchor) {
					$list_form{'anchor'} = $lastAnchor = $anchor;
				}

				$itemnumber++;
				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_list.html", \%list_form)};

				::idleStreams();
			}
		}

	} elsif (!$album) {

		my $items = ();

		# Browse by Album
		if ($params->{'artwork'} && !Slim::Utils::Prefs::get('includeNoArt')) {

			# get a list of only the albums with valid artwork
			$items = $ds->albumsWithArtwork();

		} else {

			my $find = {};

			$find->{'genre'}       = [$genre]  if _refCheck([$genre]);
			$find->{'contributor'} = [$artist] if _refCheck([$artist]);
			$find->{'track'}       = [$song]   if _refCheck([$song]);

			$items = $ds->find('album', $find, 'album');
		}

		my $numItems = scalar @$items;
		
		if ($numItems) {

			my ($start, $end);

			if (defined $params->{'nopagebar'}){

				($start, $end) = simpleHeader(
					$numItems,
					\$params->{'start'},
					\$params->{'browselist_header'},
					$params->{'skinOverride'},
					$params->{'itemsPerPage'},
					($numItems > 1)
				);

			} else {

				if ($params->{'artwork'}) {
					$otherparams .= 'artwork=1&';

					($start, $end) = pageBar(
						$numItems,
						$params->{'path'},
						0,
						$otherparams,
						\$params->{'start'},
						\$params->{'browselist_header'},
						\$params->{'browselist_pagebar'},
						$params->{'skinOverride'},
						$params->{'itemsPerPage'},
					);

				} else {

					($start, $end) = alphaPageBar(
						$items,
						$params->{'path'},
						$otherparams,
						\$params->{'start'},
						\$params->{'browselist_pagebar'},
						1,
						$params->{'skinOverride'},
						$params->{'itemsPerPage'},
					);
				}
			}

			$descend = 'true';

			if (!$params->{'artwork'} && $numItems > 1) {

				my %list_form = %$params;

				if ($params->{'includeItemStats'} && !Slim::Utils::Misc::stillScanning()) {
					$list_form{'song_count'} = $ds->count('track',  { 'genre' => $genre, 'artist' => $artist, 'album' => '*' });
				}

				$list_form{'genre'}	   = $genre;
				$list_form{'artist'}       = $artist;
				$list_form{'album'}	   = '*';
				$list_form{'title'}        = string('ALL_SONGS');
				$list_form{'descend'}      = 1;
				$list_form{'player'}       = $player;
				$list_form{'odd'}	   = ($itemnumber + 1) % 2;
				$list_form{'skinOverride'} = $params->{'skinOverride'};

				$itemnumber++;

				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_list.html", \%list_form)};
			}

			for my $item ( @$items[$start..$end] ) {

				my %list_form = %$params;

				if ($params->{'includeItemStats'} && !Slim::Utils::Misc::stillScanning()) {
					$list_form{'song_count'} = $ds->count('track',  { 'genre' => $genre, 'artist' => $artist, 'album' => $item });
				}

				$list_form{'genre'}	   = $genre;
				$list_form{'artist'}       = $artist;
				$list_form{'album'}	   = $item;
				$list_form{'title'}        = $item;
				$list_form{'descend'}      = $descend;
				$list_form{'player'}       = $player;
				$list_form{'odd'}	   = ($itemnumber + 1) % 2;
				$list_form{'skinOverride'} = $params->{'skinOverride'};

				my $anchor = anchor(Slim::Utils::Text::getSortName($item),1);

				if ($lastAnchor ne $anchor) {
					$list_form{'anchor'} = $lastAnchor = $anchor;
				}

				if ($params->{'artwork'}) {

					$song = $item->artwork_path();

					if (defined $song) {

						$list_form{'coverthumb'}   = 1; 
						$list_form{'thumbartpath'} = $song;

					} else {

						$list_form{'coverthumb'}   = 0;

						if (Slim::Utils::Prefs::get('showYear')) {
							$song = $ds->find('track',  { 'genre' => $genre, 'artist' => $artist, 'album' => $item });
						}
					}

					if (Slim::Utils::Prefs::get('showYear')) {
						$list_form{'year'} = $item->year();
					}

					$list_form{'item'}	 = $item;
					$list_form{'itemnumber'} = $itemnumber;
					$list_form{'artwork'}	 = 1;
					$list_form{'size'}	 = Slim::Utils::Prefs::get('thumbSize');

					$itemnumber++;

					$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_artwork.html", \%list_form)};

				} else {

					if (Slim::Utils::Prefs::get('showYear')) {
						$song = $ds->find('track',  { 'genre' => $genre, 'artist' => $artist, 'album' => $item });
						$list_form{'year'} = $song->year();
					}

					$itemnumber++;
					$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_list.html", \%list_form)};
				}

				::idleStreams();
			}
		}

	} else {

		# Browse by tracks
		my $find = {};

		$find->{'genre'}       = [$genre]  if _refCheck([$genre]);
		$find->{'contributor'} = [$artist] if _refCheck([$artist]);
		$find->{'album'}       = [$album]  if _refCheck([$album]);

		my $items = $ds->find('track', $find, ($album eq '*' ? 'title' : undef));

		my $numItems = scalar @$items;

		if ($numItems) {

			my ($start, $end);

			if (defined $params->{'nopagebar'}) {

				($start, $end) = simpleHeader(
					$numItems,
					\$params->{'start'},
					\$params->{'browselist_header'},
					$params->{'skinOverride'},
					$params->{'itemsPerPage'},
					($numItems > 1),
				);

			} else {

				($start, $end) = pageBar(
					$numItems,
					$params->{'path'},
					0,
					$otherparams,
					\$params->{'start'},
					\$params->{'browselist_header'},
					\$params->{'browselist_pagebar'},
					$params->{'skinOverride'},
					$params->{'itemsPerPage'},
				);
			}
			
			$descend = undef;
			
			if ($numItems > 1) {

				my %list_form = %$params;

				$list_form{'genre'}	   = $genre;
				$list_form{'artist'}       = $artist;
				$list_form{'album'}	   = $album;
				$list_form{'song'}	   = '*';
				$list_form{'descend'}      = 'true';
				$list_form{'title'}        = string('ALL_SONGS');
				$list_form{'player'}       = $player;
				$list_form{'odd'}	   = ($itemnumber + 1) % 2;
				$list_form{'skinOverride'} = $params->{'skinOverride'};

				$itemnumber++;

				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_list.html", \%list_form)};
			}

			for my $item ( @$items[$start..$end] ) {

				my %list_form = %$params;

				my $title = Slim::Music::Info::standardTitle(undef, $item);

				my $webFormat = Slim::Utils::Prefs::getInd("titleFormat",Slim::Utils::Prefs::get("titleFormatWeb"));

				$list_form{'includeArtist'} = ($webFormat !~ /ARTIST/);
				$list_form{'includeAlbum'}  = ($webFormat !~ /ALBUM/) ;

				$list_form{'genre'}	          = $item->genre();
				$list_form{'artist'}              = $item->artist();
				$list_form{'album'}	          = $item->album();
				$list_form{'itempath'}            = $item->url(); 
				$list_form{'item'}                = $item->url();
				$list_form{'title'}               = $item->title();
				$list_form{'descend'}             = $descend;
				$list_form{'player'}              = $player;
				$list_form{'odd'}	          = ($itemnumber + 1) % 2;
				$list_form{'mixable_not_descend'} = Slim::Music::Info::isSongMixable($item);
				$list_form{'skinOverride'}        = $params->{'skinOverride'};

				if ((Slim::Music::Info::coverArt($item))[0]) {
					$list_form{'coverart'} = 1;
					$list_form{'coverartpath'} = $item->url();
				}

				$itemnumber++;

				$params->{'browse_list'} .= ${Slim::Web::HTTP::filltemplatefile("browseid3_list.html", \%list_form)};

				::idleStreams();
			}

			if ((Slim::Music::Info::coverArt($items->[$start]))[0]) {
				$params->{'coverart'} = 1;
				$params->{'coverartpath'} = $items->[$start];
			}
		}
	}

	$params->{'descend'} = $descend;

	return Slim::Web::HTTP::filltemplatefile("browseid3.html", $params);
}

# the following two functions are MoodLogic related.
sub mood_wheel {
	my ($client, $params) = @_;

	my @items = ();

	my $song   = $params->{'song'};
	my $artist = $params->{'artist'};
	my $album  = $params->{'album'};
	my $genre  = $params->{'genre'};
	my $player = $params->{'player'};

	my $itemnumber = 0;
	
	if (defined $artist && $artist ne "") {

		@items = Slim::Music::MoodLogic::getMoodWheel(Slim::Music::Info::moodLogicArtistId($artist), 'artist');

	} elsif (defined $genre && $genre ne "" && $genre ne "*") {

		@items = Slim::Music::MoodLogic::getMoodWheel(Slim::Music::Info::moodLogicGenreId($genre), 'genre');

	} else {

		$::d_moodlogic && msg('no/unknown type specified for mood wheel');
		return undef;
	}

	$params->{'pwd_list'} = generate_pwd_list($genre, $artist, $album, $player);
	$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("mood_wheel_pwdlist.html", $params)};

	for my $item (@items) {

		my %list_form = %$params;

		$list_form{'mood'}     = $item;
		$list_form{'genre'}    = $genre;
		$list_form{'artist'}   = $artist;
		$list_form{'album'}    = $album;
		$list_form{'player'}   = $player;
		$list_form{'itempath'} = $item; 
		$list_form{'item'}     = $item; 
		$list_form{'odd'}      = ($itemnumber + 1) % 2;

		$itemnumber++;

		$params->{'mood_list'} .= ${Slim::Web::HTTP::filltemplatefile("mood_wheel_list.html", \%list_form)};
	}

	return Slim::Web::HTTP::filltemplatefile("mood_wheel.html", $params);
}

sub instant_mix {
	my ($client, $params) = @_;

	my $output = "";
	my @items  = ();

	my $song   = $params->{'song'};
	my $artist = $params->{'artist'};
	my $album  = $params->{'album'};
	my $genre  = $params->{'genre'};
	my $player = $params->{'player'};
	my $mood   = $params->{'mood'};
	my $p0     = $params->{'p0'};

	my $itemnumber = 0;

	$params->{'pwd_list'} = generate_pwd_list($genre, $artist, $album, $player);

	if (defined $mood && $mood ne "") {
		$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("mood_wheel_pwdlist.html", $params)};
	}

	if (defined $song && $song ne "") {
		$params->{'src_mix'} = Slim::Music::Info::standardTitle(undef, $song);
	} elsif (defined $mood && $mood ne "") {
		$params->{'src_mix'} = $mood;
	}

	$params->{'pwd_list'} .= ${Slim::Web::HTTP::filltemplatefile("instant_mix_pwdlist.html", $params)};

	if (defined $song && $song ne "") {

		@items = Slim::Music::MoodLogic::getMix(Slim::Music::Info::moodLogicSongId($song), undef, 'song');

	} elsif (defined $artist && $artist ne "" && $artist ne "*" && $mood ne "") {

		@items = Slim::Music::MoodLogic::getMix(Slim::Music::Info::moodLogicArtistId($artist), $mood, 'artist');

	} elsif (defined $genre && $genre ne "" && $genre ne "*" && $mood ne "") {

		@items = Slim::Music::MoodLogic::getMix(Slim::Music::Info::moodLogicGenreId($genre), $mood, 'genre');

	} else {

		$::d_moodlogic && msg('no/unknown type specified for instant mix');
		return undef;
	}

	for my $item (@items) {

		my %list_form = %$params;

		$list_form{'artist'}   = $artist;
		$list_form{'album'}    = $album;
		$list_form{'genre'}    = $genre;
		$list_form{'player'}   = $player;
		$list_form{'itempath'} = $item; 
		$list_form{'item'}     = $item; 
		$list_form{'title'}    = Slim::Music::Info::infoFormat($item, 'TITLE (ARTIST)', 'TITLE');
		$list_form{'odd'}      = ($itemnumber + 1) % 2;

		$itemnumber++;

		$params->{'instant_mix_list'} .= ${Slim::Web::HTTP::filltemplatefile("instant_mix_list.html", \%list_form)};
	}

	if (defined $p0 && defined $client) {

		Slim::Control::Command::execute($client, ["playlist", $p0 eq "append" ? "append" : "play", $items[0]]);
		
		for (my $i = 1; $i <= $#items; $i++) {
			Slim::Control::Command::execute($client, ["playlist", "append", $items[$i]]);
		}
	}

	return Slim::Web::HTTP::filltemplatefile("instant_mix.html", $params);
}

sub searchStringSplit {
	my $search  = shift;
	my $searchSubString = shift;
	
	$searchSubString = defined $searchSubString ? $searchSubString : Slim::Utils::Prefs::get('searchSubString');
	
	my @strings = ();

	for my $string (split(/\s+/, $search)) {

		if ($searchSubString) {

			push @strings, "\*$string\*";

		} else {

			push @strings, [ "$string\*", "\* $string\*" ];
		}
	}

	return \@strings;
}

sub anchor {
	my $item = shift;
	my $suppressArticles = shift;
	
	if ($suppressArticles) {
		$item = Slim::Utils::Text::ignoreCaseArticles($item);
	}

	return Slim::Utils::Text::matchCase(substr($item, 0, 1));
}

sub options {
	my ($selected, $option, $skinOverride) = @_;

	# pass in the selected value and a hash of value => text pairs to get the option list filled
	# with the correct option selected.

	my $optionlist = '';

	for my $curroption (sort { $option->{$a} cmp $option->{$b} } keys %{$option}) {

		$optionlist .= ${Slim::Web::HTTP::filltemplatefile("select_option.html", {
			'selected'     => ($curroption eq $selected),
			'key'          => $curroption,
			'value'        => $option->{$curroption},
			'skinOverride' => $skinOverride,
		})};
	}

	return $optionlist;
}

# Build a simple header 
sub simpleHeader {
	my ($itemCount, $startRef, $headerRef, $skinOverride, $count, $offset) = @_;

	$count ||= Slim::Utils::Prefs::get('itemsPerPage');

	my $start = (defined($$startRef) && $$startRef ne '') ? $$startRef : 0;

	if ($start >= $itemCount) {
		$start = $itemCount - $count;
	}

	$$startRef = $start;

	my $end    = $start + $count - 1 - $offset;

	if ($end >= $itemCount) {
		$end = $itemCount - 1;
	}

	$$headerRef = ${Slim::Web::HTTP::filltemplatefile("pagebarheader.html", {
		"start"        => $start,
		"end"          => $end,
		"itemcount"    => $itemCount - 1,
		'skinOverride' => $skinOverride
	})};

	return ($start, $end);
}

# Build a bar of links to multiple pages of items
sub pageBar {
	my $itemcount = shift;
	my $path = shift;
	my $currentitem = shift;
	my $otherparams = shift;
	my $startref = shift; #will be modified
	my $headerref = shift; #will be modified
	my $pagebarref = shift; #will be modified
	my $skinOverride = shift;

	my $count = shift || Slim::Utils::Prefs::get('itemsPerPage');

	my $start = (defined($$startref) && $$startref ne '') ? $$startref : (int($currentitem/$count)*$count);
	if ($start >= $itemcount) { $start = $itemcount - $count; }
	$$startref = $start;
	my $end = $start+$count-1;
	if ($end >= $itemcount) { $end = $itemcount - 1;}
	if ($itemcount > $count) {
		$$headerref = ${Slim::Web::HTTP::filltemplatefile("pagebarheader.html", { "start" => ($start+1), "end" => ($end+1), "itemcount" => $itemcount, 'skinOverride' => $skinOverride})};

		my %pagebar = ();

		my $numpages  = POSIX::ceil($itemcount/$count);
		my $curpage   = int($start/$count);
		my $pagesperbar = 10; #make this a preference
		my $pagebarstart = (($curpage - int($pagesperbar/2)) < 0 || $numpages <= $pagesperbar) ? 0 : ($curpage - int($pagesperbar/2));
		my $pagebarend = ($pagebarstart + $pagesperbar) > $numpages ? $numpages : ($pagebarstart + $pagesperbar);

		$pagebar{'pagesstart'} = ($pagebarstart > 0);

		if ($pagebar{'pagesstart'}) {
			$pagebar{'pagesprev'} = ($curpage - $pagesperbar) * $count;
			if ($pagebar{'pagesprev'} < 0) { $pagebar{'pagesprev'} = 0; };
		}

		if ($pagebarend < $numpages) {
			$pagebar{'pagesend'} = ($numpages -1) * $count;
			$pagebar{'pagesnext'} = ($curpage + $pagesperbar) * $count;
			if ($pagebar{'pagesnext'} > $pagebar{'pagesend'}) { $pagebar{'pagesnext'} = $pagebar{'pagesend'}; }
		}

		$pagebar{'pageprev'} = $curpage > 0 ? (($curpage - 1) * $count) : undef;
		$pagebar{'pagenext'} = ($curpage < ($numpages - 1)) ? (($curpage + 1) * $count) : undef;
		$pagebar{'otherparams'} = defined($otherparams) ? $otherparams : '';
		$pagebar{'skinOverride'} = $skinOverride;
		$pagebar{'path'} = $path;

		for (my $j = $pagebarstart;$j < $pagebarend;$j++) {
			$pagebar{'pageslist'} .= ${Slim::Web::HTTP::filltemplatefile('pagebarlist.html'
							,{'currpage' => ($j == $curpage)
							,'itemnum0' => ($j * $count)
							,'itemnum1' => (($j * $count) + 1)
							,'pagenum' => ($j + 1)
							,'otherparams' => $otherparams
							,'skinOverride' => $skinOverride
							,'path' => $path})};
		}
		$$pagebarref = ${Slim::Web::HTTP::filltemplatefile("pagebar.html", \%pagebar)};
	}
	return ($start, $end);
}

sub alphaPageBar {
	my $itemsref = shift;
	my $path = shift;
	my $otherparams = shift;
	my $startref = shift; #will be modified
	my $pagebarref = shift; #will be modified
	my $ignorearticles = shift;
	my $skinOverride = shift;
	my $maxcount = shift || Slim::Utils::Prefs::get('itemsPerPage');
	my $itemcount = scalar(@$itemsref);
	my $start = $$startref;
	if (!$start) { 
		$start = 0;
	}
	
	if ($start >= $itemcount) { 
		$start = $itemcount - $maxcount; 
	}
	
	$$startref = $start;
	
	my $end = $itemcount-1;
	if ($itemcount > $maxcount/2) {

		my %pagebar_params = ();
		if (!defined($otherparams)) {
			$otherparams = '';
		}
		$pagebar_params{'otherparams'} =  $otherparams;
		
		my $lastLetter = '';
		my $lastLetterIndex = 0;
		my $pageslist = '';
		$end = -1;

		# This seems very inefficient - we're calling into anchor()
		# and getSortName() more times than we need to be.
		for (my $j = 0; $j < $itemcount; $j++) {

			my $curLetter = anchor(Slim::Utils::Text::getSortName($itemsref->[$j]), $ignorearticles);

			if ($lastLetter ne $curLetter) {

				if (($j - $lastLetterIndex) > $maxcount) {
					if ($end == -1 && $j > $start) {
						$end = $j - 1;
					}
					$lastLetterIndex = $j;
				}

				$pageslist .= ${Slim::Web::HTTP::filltemplatefile('alphapagebarlist.html', {
					'currpage' => ($lastLetterIndex == $start),
					'itemnum0' => $lastLetterIndex,
					'itemnum1' => ($lastLetterIndex + 1),
					'pagenum' => $curLetter,
					'fragment' => ("#" . $curLetter),
					'otherparams' => $otherparams,
					'skinOverride' => $skinOverride,
					'path' => $path
				})};
				
				$lastLetter = $curLetter;
			}
		}
		
		if ($end == -1) {
			$end = $itemcount - 1;
		}

		$pagebar_params{'pageslist'} = $pageslist;
		$pagebar_params{'skinOverride'} = $skinOverride;
		$$pagebarref = ${Slim::Web::HTTP::filltemplatefile("pagebar.html", \%pagebar_params)};
	}
	
	return ($start, $end);
}

sub firmware {
	my ($client, $params) = @_;

	return Slim::Web::HTTP::filltemplatefile("firmware.html", $params);
}

# This is here just to support SDK4.x (version <=10) clients
# so it always sends an upgrade to version 10 using the old upgrade method.
sub update_firmware {
	my ($client, $params) = @_;

	$params->{'warning'} = Slim::Player::Squeezebox::upgradeFirmware($params->{'ipaddress'}, 10) 
		|| string('UPGRADE_COMPLETE_DETAILS');
	
	return Slim::Web::HTTP::filltemplatefile("update_firmware.html", $params);
}

1;

__END__

# Local Variables:
# tab-width:4
# indent-tabs-mode:t
# End:
