#!/usr/bin/perl
#use warnings;
use G0VTW::PCC::Fetch::Parser;

foreach $file (@ARGV) {
	open(FH, '<', $file) or die "open file failed: $!\n";
	local $/;
	$body = <FH>;
	
	close(FH);
	
	G0VTW::PCC::Fetch::Parser::tender_parse($body);
}

exit;


