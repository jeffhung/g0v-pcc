#!/usr/bin/perl
#use warnings;
use lib "../lib";
use G0VTW::PCC::Fetch::Parser;
use Data::Dumper;
use JSON;

if(-d $ARGV[0])
{
	my @files = glob "$ARGV[0]/*";
	parse_file($_) foreach (@files);
}
else
{
	parse_file($ARGV[0]);
}

exit;

sub parse_file
{
	my $file = shift;

	open(FH, '<', $file) or die "failed to open $file: $!\n";
	local $/;
	my $body = <FH>;
	close(FH);
	
	my $hash = G0VTW::PCC::Fetch::Parser::tender_parse($body);

	open(FH, '>', "$file.json") or die "failed to open $file.json: $!\n";
	print FH to_json($hash, {pretty => 1});
	close(FH);
}
