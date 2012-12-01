package G0VTW::PCC::Fetch::Crawler;

use WWW::Mechanize;
use POSIX;

sub iso8601
{
	my @tm = localtime(time);
	return strftime('%Y%m%dT%H%M%S%z', @tm);
}

sub bot_info_
{
	my $bot = shift or die;
	my $save_as = shift;
	my $ts = iso8601();
	printf("-------------------------------------------\n");
	printf("[bot:%s] URI: %s\n", $ts, $bot->uri());
	if (defined($save_as)) {
		$bot->save_content($save_as);
		printf("[bot:%s] Saved at %s\n", $ts, $save_as);
	}
}

sub new
{
	my $claz = shift or die;
	my %opts = @_;
	return bless {
	}, $claz;
}

##
# $opts{'query_type'}: could be 'basic', 'advanced', or 'update' (only 'basic' implemented so far)
# $opts{'date_range'}: 
sub craw
{
	my $self = shift or die;
	my %opts = @_;

	my $bot = new WWW::Mechanize(autocheck => 1);
	$bot->get('http://web.pcc.gov.tw/tps/pss/tender.do?method=goSearch&searchMode=common&searchType=basic');
	bot_info_($bot);
}

1;

