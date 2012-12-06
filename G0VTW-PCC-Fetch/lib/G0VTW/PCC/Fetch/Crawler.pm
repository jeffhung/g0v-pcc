package G0VTW::PCC::Fetch::Crawler;

use utf8;
use WWW::Mechanize;
use POSIX;
use Time::HiRes qw(usleep);
use File::Path qw( make_path );
use File::Basename;

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
		# Ensures destination directory exist
		$dir = dirname($save_as);
		make_path($dir);
		# Save the file
		$bot->save_content($save_as);
		printf("[bot:%s] Saved at %s\n", $ts, $save_as);
	}
	usleep((rand() % 100) * 10000);
}

sub new
{
	my $claz = shift or die;
	my %opts = @_;
	return bless {
		data_dir => $opts{data_dir},
		fetched  => 0,
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
sub crawl_announcement
{
	my $self = shift or die;
	my %opts = @_;

	my $data_dir = "$self->{data_dir}/announcement";

	my $bot = new WWW::Mechanize(autocheck => 1);
	$bot->get('http://web.pcc.gov.tw/tps/pss/tender.do?method=goSearch&searchMode=common&searchType=basic');
	bot_info_($bot);

	foreach $way (keys %$TENDER_WAYS) {
		next if ($way eq 'tenderway01'); # we've done it

		$bot->submit_form(
			form_name => 'TenderActionForm',
			fields => {
				'method'          => 'search',
				'searchMethod'    => 'true',
				'orgName'         => '',                                     # 機關名稱
				'orgId'           => '',                                     # 機關代碼
				'hid_1'           => '1',
				'tenderName'      => '',                                     # 標案名稱
				'tenderId'        => '',                                     # 標案案號
				'tenderWay'       => $TENDER_WAYS->{$way}->{value},          # 招標方式
#				'tenderWay'       => $TENDER_WAYS->{'tenderway01'}->{value}, # 招標方式
				'tenderStartDate' => '101/11/01',
				'tenderEndDate'   => '101/11/30',
#				'proctrgCate'     => $proctrgCate->{'engineer'}->{value},    # 標的分類
				'proctrgCate'     => '',
			},
		);

		@page_links = $bot->find_all_links(
			url_regex => qr|./tender.do\?searchMode=common&searchType=basic&method=search&pageIndex=\d+|,
		);
		$last_page_link = pop @page_links;
		if ($last_page_link && $last_page_link->url =~ m/pageIndex=(\d+)$/o) {
			$last_page_num = $1;
		} else {
			$last_page_num = 1;
		}

		$pgdn_link = undef;
		$page_num = 0;
		while ($page_num <= $last_page_num) {
			++$page_num;
			if ($page_num > 1) {
				print "------------\n";
				$bot->get("./tender.do\?searchMode=common&searchType=basic&method=search&pageIndex=$page_num");
			}
			bot_info_($bot, "$data_dir/$way/list-page$page_num.html");

			@links = $bot->find_all_links(
				url_regex => qr|../tpam/main/tps/tpam/tpam_tender_detail.do\?searchMode=common&scope=F&primaryKey=\d+|,
			);
			foreach $link (@links) {
				$url = $link->url;
#				print "$url\n";
				if ($url =~ m/primaryKey=(\d+)$/o) {
					$pkey = $1;
					$bot->get($url);
					bot_info_($bot, "$data_dir/$way/case$pkey.html");
					$bot->back();
					$self->{fetched} += 1;
				}
			}
		}

		$bot->back();
	}
}

sub crawl_atm
{
	my $self = shift or die;
	my %opts = @_;

	my $data_dir = "$self->{data_dir}/atm";

	# 標案狀態
	my $tenderStatus = {
		'all'       => { text => '',         value => '4,5,21,29,9,22,23,30,34,10,24' },
		'success'   => { text => '決標公告', value => '4,5,21,29' },
		'failed'    => { text => '無法決標', value => '9,22,23,30,34' },
		'cancelled' => { text => '撤銷公告', value => '10,24' },
	};
	# 採購級距
	my $tenderRange = {
		'range1' => { text => '未達公告金額',             value => '1' },
		'range2' => { text => '公告金額以上未達查核金額', value => '2' },
		'range3' => { text => '查核金額以上未達巨額',     value => '3' },
		'range4' => { text => '巨額', value => '4' },
	};
	# 優先採購分類
	my $priorityCate => {
		'category01' => { text => '食品',     value => '1' },
		'category13' => { text => '手工藝品', value => '13' },
		'category25' => { text => '清潔用品', value => '25' },
		'category27' => { text => '園藝產品', value => '27' },
		'category32' => { text => '輔助器具', value => '32' },
		'category34' => { text => '家庭用品', value => '34' },
		'category39' => { text => '印刷',     value => '39' },
		'category44' => { text => '清潔服務', value => '44' },
		'category48' => { text => '飲食服務', value => '48' },
		'category52' => { text => '洗車服務', value => '52' },
		'category54' => { text => '洗衣服務', value => '54' },
		'category58' => { text => '客服服務', value => '58' },
		'category63' => { text => '代工服務', value => '63' },
		'category67' => { text => '演藝服務', value => '67' },
		'category70' => { text => '交通服務', value => '70' },
		'category72' => { text => '其他', value => '72' },
	};

	my $bot = new WWW::Mechanize(autocheck => 1);
	$bot->get(
		'http://web.pcc.gov.tw/tps/pss/tender.do?method=goSearch&searchMode=common&searchType=advance&searchTarget=ATM'
	);
	bot_info_($bot, "$data_dir/form.html");

#	foreach $way (keys %$TENDER_WAYS) {
#		next unless ($way =~ m/\d+$/o);  # 公開徵求 & 公開閱覽 are not included in ATM
		my $way = 'all';

		$bot->submit_form(
			form_name => 'TenderActionForm',
			fields => {
				'searchMode'             => 'common',
				'searchType'             => 'advance',

				'btnQuery'               => 'Submit',

				'hid_1'                  => '1',
				'hid_2'                  => '1',
				'hid_3'                  => '1',
				'method'                 => 'search',
				'searchMethod'           => 'true',
				'searchTarget'           => 'ATM',
				'orgName'                => '',                             # 機關名稱
				'orgId'                  => '',                             # 機關代碼
				'tenderName'             => '',                             # 標案名稱
				'tenderId'               => '',                             # 標案案號
#				'tenderStatus'           => $tenderStatus->{'all'},         # 標案狀態
				'tenderStatus'           => '4,5,21,29,9,22,23,30,34,10,24',
#				'tenderWay'              => $TENDER_WAYS->{$way}->{value},  # 招標方式
				'tenderWay'              => '',                             # 招標方式
				'awardAnnounceStartDate' => '101/11/01',
				'awardAnnounceEndDate'   => '101/11/30',
#				'proctrgCate'            => $proctrgCate->{'engineer'}->{value},  # 標的分類
				'proctrgCate'            => '',
				'tenderRange'            => '',                             # 採購級距
				# 決標金額
				'minBudget'              => '',
				'maxBudget'              => '',
				'item'                   => '',                             # 決標品項
				'gottenVendorName'       => '',                             # 得標廠商
				'gottenVendorId'         => '',                             # 廠商統編
				'submitVendorName'       => '',                             # 投標廠商
				'submitVendorId'         => '',                             # 廠商統編
				'location'               => '',                             # 履約地點
				'priorityCate'           => '',                             # 優先採購分類
				'isReConstruct'          => '',                             # 災區重建工程 ('Y' or 'N')
			},
		);

		@page_links = $bot->find_all_links(
			url_regex => qr|./tender.do\?searchMode=common&searchType=advance&searchTarget=ATM&method=search&pageIndex=\d+|,
		);
		$last_page_link = pop @page_links;
		if ($last_page_link && $last_page_link->url =~ m/pageIndex=(\d+)$/o) {
			$last_page_num = $1;
		} else {
			$last_page_num = 1;
		}
		print "last page: $last_page_num\n";

		$pgdn_link = undef;
		$page_num = 0;
		while ($page_num <= $last_page_num) {
			++$page_num;
			if ($page_num > 1) {
				print "------------\n";
				$bot->get(
					"./tender.do\?searchMode=common&searchType=advance&searchTarget=ATM&method=search&pageIndex=$page_num"
				);
			}
			bot_info_($bot, "$data_dir/$way/list-page$page_num.html");

			@links = $bot->find_all_links(
				url_regex => qr{(../main/pms/tps/atm/atmAwardAction.do\?newEdit=false&searchMode=common&method=inquiryForPublic&pkAtmMain=\d+|../main/pms/tps/atm/atmNonAwardAction.do\?searchMode=common&method=nonAwardContentForPublic&pkAtmMain=\d+)},
			);
			my $previous_url = undef;
			foreach $link (@links) {
				$url = $link->url;
				next if (defined($previous_url) && ($url eq $previous_url));
				$previous_url = $url;
#				print "$url\n";
				if ($url =~ m/pkAtmMain=(\d+)/o) {
					$pkey = $1;
#					print "$pkey\n";
					$bot->get($url);
					bot_info_($bot, "$data_dir/$way/case$pkey.html");
					$bot->back();
					$self->{fetched} += 1;
				}
			}
		}

#		$bot->back();
#	}
}

1;

