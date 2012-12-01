package G0VTW::PCC::Fetch::Crawler;

use WWW::Mechanize;
use POSIX;

sub iso8601
{
	my @tm = localtime(time);
	return strftime('%Y%m%dT%H%M%S%z', @tm);
}

sub extract_between
{
	my $text = shift or die;
	my $beg = shift or die;
	my $end = shift or die;
	my $offset = shift;

	my $b = index($text, $beg, (defined($offset) ? $offset : 0));
	return undef if ($b < 0);
	my $e = index($text, $end, ($b + length($beg)));
	return undef if ($e < 0);
	return ($b, ($e - $b));
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

# 招標方式
$TENDER_WAYS = {
	'tenderway01' => { value => '1',            text => '公開招標' },
	'tenderway02' => { value => '2',            text => '公開取得報價單或企劃書' },
	'tenderway04' => { value => '4',            text => '限制性招標(經公開評選或公開徵求)' },
	'tenderway05' => { value => '5',            text => '選擇性招標(建立合格廠商名單)' },
	'tenderway07' => { value => '7',            text => '選擇性招標(建立合格廠商名單後續邀標)' },
	'tenderway03' => { value => '3',            text => '選擇性招標(個案)' },
	'tenderway10' => { value => '10',           text => '電子競價' },
	'tenderway06' => { value => '6',            text => '限制性招標(未經公開評選或公開徵求者)' },
	'tenderwaySA' => { value => 'searchAppeal', text => '公開徵求' },
	'tenderwayPR' => { value => 'publicRead',   text => '公開閱覽' },
};

# 標的分類
$proctrgCate = {
	'engineer'  => { value => '1', text => '工程' },
	'financial' => { value => '2', text => '財物' },
	'service'   => { value => '3', text => '勞務' },
};

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

	$bot->submit_form(
		form_name => 'TenderActionForm',
		fields => {
			'method'          => 'search',
			'searchMethod'    => 'true',
			'orgName'         => '',                                      # 機關名稱
			'orgId'           => '',                                      # 機關代碼
			'hid_1'           => '1',
			'tenderName'      => '',                                      # 標案名稱
			'tenderId'        => '',                                      # 標案案號
			'tenderWay'       => $TENDER_WAYS->{'tenderway01'}->{value},  # 招標方式
			'tenderStartDate' => '101/10/01',
			'tenderEndDate'   => '101/12/01',
			'proctrgCate'     => $proctrgCate->{'engineer'}->{value},     # 標的分類
		},
	);
	bot_info_($bot, 'list.html');
	my $list_html = $bot->content();

}

1;

