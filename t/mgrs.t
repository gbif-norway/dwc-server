use strict;
use warnings;

use Test::Simple tests => 16;

use GBIFNorway;
use GBIFNorway::MGRS;

my ($mgrs, $d);

($mgrs, $d) = GBIFNorway::MGRS::parse("NP 273-277 472-478");
ok($mgrs eq "32VNP2755047550", "Finn midten I");
ok($d == 430, "Usikkerhet I");

($mgrs, $d) = GBIFNorway::MGRS::parse("WQ 17-22 11-16");
ok($mgrs eq "33WWQ2000014000", "Finn midten II");
ok($d == 4243, "Usikkerhet II");

($mgrs, $d) = GBIFNorway::MGRS::parse("NJ 50000 50000");
ok($d == 1, "Usikkerhet (1 meter)");
ok($mgrs eq "32VNJ5000050000", "NJ -> 32V");

($mgrs, $d) = GBIFNorway::MGRS::parse("LV 4000 4000");
ok($d == 7, "Usikkerhet (10 meter)");
ok($mgrs eq "32WLV4000540005", "LV -> 32W");

($mgrs, $d) = GBIFNorway::MGRS::parse("UC 300 300");
ok($d == 71, "Usikkerhet (100 meter)");
ok($mgrs eq "33VUC3005030050", "UC -> 33V");

($mgrs, $d) = GBIFNorway::MGRS::parse("CR 20 20");
ok($d == 707, "Usikkerhet (1000 meter)");
ok($mgrs eq "34WCR2050020500", "CR -> 34W");

($mgrs, $d) = GBIFNorway::MGRS::parse("PG 1 1");
ok($d == 7071, "Usikkerhet (10000 meter)");
ok($mgrs eq "32UPG1500015000", "PG -> 32U");

($mgrs, $d) = GBIFNorway::MGRS::parse("NM-PM 950-005,415-450");
ok($d == 3329, "Usikkerhet (flere ruter)");
ok($mgrs eq "32VNM9780043300", "Midtpunkt (flere ruter)");

