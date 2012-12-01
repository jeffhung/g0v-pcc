#!/usr/bin/perl -w

use G0VTW::PCC::Fetch::Crawler;

$crawler = new G0VTW::PCC::Fetch::Crawler( data_dir => '2012nov' );
$crawler->crawl_announcement();

