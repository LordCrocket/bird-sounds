#!/usr/bin/perl -w
use strict;
use warnings;
use v5.10;

use JSON qw( decode_json );
use REST::Client;
use Data::Dumper;
use MP3::Cut::Gapless;
use LWP::Simple qw(getstore);
use utf8;
binmode(STDOUT, ":utf8");


my $cache_dir = "cache";
my $output_dir = "audio";

sub cut_file {
	my ($long, $short) = @_;
	my $dir = $output_dir;
	my $cut = MP3::Cut::Gapless->new(
        file      => "$cache_dir/$long.mp3",
        cache_dir => '/tmp/mp3cut',
        start_ms  => 0,
        end_ms    => 15000,
    );
    open my $out, '>', "$output_dir/$short.mp3";
    while ( $cut->read( my $buf, 4096 ) ) {
        syswrite $out, $buf;
    }
    close $out;
}

if(! -d $cache_dir) { 
    mkdir $cache_dir or die "Error creating directory: $cache_dir, Reason: $!"; 
}
if(! -d $output_dir) { 
    mkdir $output_dir or die "Error creating directory: $output_dir, Reason: $!";
}

my $client = REST::Client->new();
$client->GET('http://api.sr.se/api/v2/episodes/index?programid=3275&format=json&pagination=false');
my $response = decode_json $client->responseContent();
foreach my $episode (@{$response->{episodes}}){

    if(my ($title) = $episode->{title} =~ /^(\w{3,}(\s\w{3,})?)(, P2-fågeln)?/){
        my $url = $episode->{downloadpodfile}->{url};
		if($url){
			my $id = $episode->{id};
            $title =~ tr/ /_/;
			say $title . " " . $url;
            my $file = $cache_dir . "/" . $id . ".mp3";
            getstore($url, $file) unless -e $file;
            cut_file($id , $title);
		}
    }
}
