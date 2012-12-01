#!/usr/bin/perl -w

use G0VTW::PCC::Fetch::Crawler;

$crawler = new G0VTW::PCC::Fetch::Crawler( data_dir => 'atm-2012nov' );
#$crawler->crawl_announcement();
$crawler->crawl_atm();

