package G0VTW::PCC::Fetch::Parser;

sub tender_parse
{
	my $body = shift;

	$body =~ s/\r//g;
	my @lines = split(/\n/, $body);

	my $i;
	my $firstline = 0;
	my $lastline = $#lines;
	for($i = 0; $i <= $lastline; $i++)
	{
		if($lines[$i] =~ /公告日/)
		{
			$firstline = $i;
			last;
		}
	}

	for(; $i <= $lastline; $i++)
	{
		if($lines[$i] =~ /history\./)
		{
			$lastline = $i;
			last;
		}
	}

	$i = $firstline;
	my $f_key = 0;
	my ($section, $key, $value);
	while($i <= $lastline)
	{
		my $line = $lines[$i];
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
				}while ($line !~ /<\/th/ && $i <= $lastline);
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
			my $subtable;
			$value = $line;
			if($value !~ /<\/td/)
			{
				my $level = 0;
				$subtable = 0;
				do
				{
					$i += 1;
					$line = $lines[$i];
					$value .= "$line\n";
					$level += 1 if($line =~ /<table/);
					$subtable = 1 if $level > 0;
					$level -= 1 if($line =~ /<\/table/);
				}while ((0 != $level || $line !~ /<\/td/) && $i <= $lastline);
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
				if(1 == $subtable)
				{
					parse_subtable($value);
				}
				else
				{
					$value =~ s/\n//g;
					$value =~ s/<[^>]+>//g;
					$value =~ s/\s+/ /g;
					if(1 == $f_key)
					{
						$f_key = 0;
						print "\t\t$value\n";
					}
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
sub parse_subtable
{
	my $subtable = shift;
	#print "[[[$subtable]]]\n";
}

1;

