package G0VTW::PCC::Fetch::Parser;

sub tender_parse
{
	my $body = shift;

	my @lines = split(/\n/, $body);

	my $i = 0;
	my $f_key = 0;
	while($i <= $#lines)
	{
		$line = $lines[$i];
		if($line =~ /<th/)
		{
			$key = $line;
			if($line !~ /<\/th/)
			{ 
				do
				{
					$i += 1;
					$line = $lines[$i];
					$key .= $line;
				}while ($line !~ /<\/th/ && $i <= $#lines);
			}
			if($key =~ /T11b/)
			{
				$key =~ s/[\r\n]//g;
				$key =~ /<th[^>]*>\s*(.*)\s*<\/th/;
				$key = $1;
				$key =~ s/<[^>]+>//g;
				$key =~ s/\s+/ /g;
				$f_key = 1;
				print "\t$key\n";
			}
		}
		elsif($line =~ /<td/)
		{
			$value = $line;
			do
			{
				$i += 1;
				$line = $lines[$i];
				$value .= $line;
			}while ($line !~ /<\/td/ && $i <= $#lines);
			if($value =~ /\s*(\S+<br>\S+<br>\S+<br>\S+)\s*/)
			{
				$section = $1;
				$section =~ s/<br>//g;
				print "$section\n";
			}
			else
			{
				$value =~ s/[\r\n]//g;
				$value =~ /<td[^>]*>\s*(.*)\s*<\/td/;
				$value = $1;
				$value =~ s/<[^>]+>//g;
				$value =~ s/\s+/ /g;
				if(1 == $f_key)
				{
					$f_key = 0;
					print "\t\t$value\n";
				}
			}
		}
		else
		{
			#print "[nonmatch] $line\n";
		}
		$i += 1;
	}
}

1;

