#!/usr/bin/perl -w

use File::Basename;
use Getopt::Long;
use POSIX;
use G0VTW::PCC::Fetch::Crawler;

my ($__exe_name__) = (basename($0));

sub msg_exit
{
	my $ex = ((scalar(@_) > 0) ? shift @_ : 0);
	foreach my $m (@_) {
		print STDERR "ERROR: $m\n";
	}
	print STDERR <<"EOF";
Usage: $__exe_name__ [ <option> ... ] <svn-repo> ...
Type '$__exe_name__ --help' for usage.
EOF
	exit($ex);
}

sub usage
{
	print STDERR <<"EOF";
Usage: $__exe_name__ [ <option> ... ]

Crawl the Taiwan Government e-Procurement System to fetch its data for open
data purposes.

Options:

  -h,--help               Show this help message.
  -v,--verbose            Show verbose progress messages.
  -d,--data-dir DATA_DIR  Save data in DATA_DIR. [ default: data-* ]

EOF
	exit(0);
}

my %opts = (
	'h' => 0,
	'd' => strftime('data-%Y%m%dT%H%M%SZ', gmtime(time)),
	'v' => 0,
);
if (!GetOptions(\%opts,
                'h|help' => sub { usage },
                'd|data-dir=s',
                'v|verbose')) {
	msg_exit(0);
}
$crawler = new G0VTW::PCC::Fetch::Crawler( data_dir => $opts{d} );
$crawler->crawl_announcement();
$crawler->crawl_atm();

exit;

