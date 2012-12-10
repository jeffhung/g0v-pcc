package G0VTW::PCC::Fetch::Parser;

sub tender_parse
{
	my $body = shift;
	my $tender = body_parse($body);

	if(defined $tender->{'決標品項'})
	{
		my $item;
		foreach $item (keys %{$tender->{'決標品項'}})
		{
			if($item =~ /第(\d+)品項/)
			{
				my $key;
				my $item_detail = $tender->{'決標品項'}->{$item};
				foreach $key (keys %$item_detail)
				{
					if($key =~ /(\S*得標廠商\d+)(.*)$/)
					{
						my $vendor_key = $1;
						my $vendor_value = $2;
						#print "$vendor_key\t$vendor_value\t$item_detail->{$key}\n";

						$item_detail->{$vendor_key} = () if(not defined $item_detail->{$vendor_key});
						$item_detail->{$vendor_key}->{$vendor_value} = $item_detail->{$key};
						delete($item_detail->{$key});
					}
				}
			}	
		}
	}

	return $tender;
}

sub body_parse
{
	my $body = shift;

	$body =~ s/\r//g;
	my @lines = split(/\n/, $body);

	my $i;
	my $firstline = 0;
	my $lastline = $#lines;
	for($i = 0; $i <= $lastline; $i++)
	{
		if($lines[$i] =~ /\d{2,3}\/\d{1,2}\/\d{1,2}/)
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

	my $sections = {};

	$i = $firstline;
	my $f_key = 0;
	my ($section_name, $key, $value);
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
			$key =~ /<th[^>]*>\s*(.*)\s*<\/th/;
			$key = strclean($1);
			$f_key = 1;
			#print "\t$key\n";
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
			if($value =~ /(\S+<br\/?>\S{3}<br\/?>\S{3}<br\/?>\S+)/)
			{
				$section_name = strclean($1);
				if($section_name =~ /.*>(.*)/)
				{
					$section_name = $1;
				}
				#print "$section_name\n";

				$sections->{$section_name} = ();
			}
			else
			{
				if(1 == $subtable)
				{
					if($value =~ /(投標廠商|決標品項)/)
					{
						$sections->{$section_name} = subtable_parse($value);
					}
				}
				else
				{
					$value =~ s/\n//g;
					$value =~ /<td[^>]*>\s*(.*)\s*<\/td/;
					$value = strclean($1);
					if(1 == $f_key)
					{
						$f_key = 0;
						#print "\t\t$value\n";

						$sections->{$section_name}->{$key} = $value;
					}
				}
			}
		}
		$i += 1;
	}

	return $sections;
}
sub subtable_parse
{
	my $subtable = shift;

	my @lines = split(/\n/, $subtable);
	my $i;
	my $firstline = 0;

	my $lastline = $#lines;
	for($i = 0; $i <= $lastline; $i++)
	{
		if($lines[$i] =~ /<table/)
		{
			$firstline = $i;
			last;
		}
	}

	for(; $i <= $lastline; $i++)
	{
		if($lines[$i] =~ /<\/table/)
		{
			$lastline = $i;
			last;
		}
	}

	my $sections = {};

	$i = $firstline;
	my ($f_key, $section_name, $key, $value, $prepend);
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
			$key =~ /<th[^>]*>\s*(.*)\s*<\/th/;
			$key = strclean($1);
			$f_key = 1;
			#print "\t\t$key\n";
		}
		elsif($line =~ /<td/)
		{
			my $subtable;
			$value = $line;
			if($value !~ /<\/td/)
			{
				do
				{
					$i += 1;
					$line = $lines[$i];
					$value .= "$line\n";
				}while ($line !~ /<\/td/ && $i <= $lastline);
			}
			
			$value =~ s/\n//g;
			$value =~ /<td[^>]*>\s*(.*)\s*<\/td/;
			$value = strclean($1);
			if(1 == $f_key)
			{
				$f_key = 0;
				#print "\t\t\t$value\n";

				if($key eq '投標廠商家數' || $key eq '決標品項數')
				{
					$sections->{$key} = $value;
				}
				elsif($key =~ /投標廠商\d+/ || $key =~ /第\d+品項/)
				{
					$section_name = $key;
				}
				elsif($key =~ /得標廠商\d+/)
				{
					$prepend = $key;
				}
				else
				{
					$sections->{$section_name}->{$prepend . $key} = $value;
				}
			}
		}
		$i += 1;
	}

	return $sections;
}

sub strclean
{
	my $string = shift;

	$string =~ s/<[^>]+>//g;
	$string =~ s/&nbsp;/ /g;
	$string =~ s/&lt;/</g;
	$string =~ s/&gt;/>/g;
	$string =~ s/　//g;
	$string =~ s/\s+/ /g;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;

	return $string;
}

1;

