# Slim Server Copyright (c) 2001, 2002, 2003 Sean Adams, Slim Devices Inc.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
package Slim::Player::HTTP;

@ISA = ("Slim::Player::Client");

sub new {
	my (
		$class,
		$id,
		$paddr,			# sockaddr_in
		$tcpsock
	) = @_;
	
	my $client = Slim::Player::Client->new($id, $paddr);

	$client->streamingsocket($tcpsock);

	bless $client, $class;

	return $client;
}

sub init {
	my $client = shift;
	$client->startup();
}

sub update {
}

sub isPlayer {
	return 0;
}

sub power {
	return 1;
}

sub play {
	return 1;
}

sub volume {
	return 1;
}

sub fade_volume {
	return 1;
}
1;
