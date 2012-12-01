package G0VTW::PCC::Fetch::Parser;

sub tender_parse
{
	my $body = shift;

	$body =~ s/\r//g;
	my @lines = split(/\n/, $body);

	my $i;
	my $f_begin = 0;
	for($i = 0; $i <= $#lines && 0 == $f_begin; $i++)
	{
		$f_begin = 1 if($lines[$i] =~ /?砍???);
	}

	my $f_key = 0;
	while($i <= $#lines)
	{
		$line = $lines[$i];
		if($line =~ /<th/)
		{
			$key = $line;
			if($key !~ /<\/th/)
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
			if($value !~ /<\/td/)
			{
				my $level = 0;
				do
				{
					$i += 1;
					$line = $lines[$i];
					$value .= $line;
					$level += 1 if($line =~ /<table/);
					$level -= 1 if($line =~ /<\/table/);
				}while ((0 != $level || $line !~ /<\/td/) && $i <= $#lines);
			}
			if($value =~ /(\S+<br\/?>\S+<br\/?>\S+<br\/?>\S+)/)
			{
				$section = $1;
				$section =~ s/<[^>]+>//g;
				if($section =~ /.*>(.*)/)
				{
					$section = $1;
				}
				print "$section\n";
			}
			else
			{
				#$value =~ /<td[^>]*>\s*(.*)\s*<\/td/;
				#$value = $1;
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

