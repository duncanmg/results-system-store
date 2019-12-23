use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Differences;
use List::MoreUtils qw/any/;
use Data::Dumper;
use Test::MockObject;
use FindBin qw/$Bin/;

my $mock_logger = Test::MockObject->new;
$mock_logger->mock( 'debug', sub {1} );
$mock_logger->mock( 'error', sub {1} );

my $CSV_FILE = $Bin . '/../data/U9N.csv';

use_ok('ResultsSystem::Store::FixtureList');

my $fl;
ok( $fl = ResultsSystem::Store::FixtureList->new( { -logger => $mock_logger } ),
  "Got an object" );
isa_ok( $fl, 'ResultsSystem::Store::FixtureList' );
ok( $fl->logger, "Logger is set" );

throws_ok( sub { $fl->read_file },
  qr/FILE_DOES_NOT_EXIST/x, "read_file throws an exception because the file has not been set." );

ok( $fl->set_full_filename($CSV_FILE), "Set full_filename" );

lives_ok( sub { $fl->read_file }, "Full filename has been set so read_file() lives" );

my $date_list = $fl->get_date_list;
is( ref($date_list), 'ARRAY', "get_date_list returns an array ref" );
ok( scalar(@$date_list) > 1, "Got at least 1 date" );

my $date = shift @$date_list;

my $wf;
ok( $wf = $fl->get_week_fixtures( -date => $date ), "get_week_fixtures" );
ok( scalar(@$wf) > 1, "Got at least 1 fixture for $date" );
eq_or_diff(
  [ sort( keys( %{ $wf->[0] } ) ) ],
  [ 'away', 'home' ],
  "First fixture has the correct keys"
);

ok( scalar( @{ $fl->get_all_teams } ) >= 2,
  "get_all_teams returns array ref with at least 2 rows" );
ok( !( any { ref($_) ne 'HASH' } @{ $fl->get_all_teams } ), "They are all hash refs" )
  || diag( Dumper $fl->get_all_teams );
ok(
  ( !any { !$_->{team} } @{ $fl->get_all_teams } ),
  "They all have the key 'team' set to a true value"
) || diag( Dumper $fl->get_all_teams );

my $is_sorted = sub {
  my $list = shift;
  my $p    = "";
  for my $l (@$list) {
    return if $l->{team} lt $p;
    $p = $l->{team};
  }
  return 1;
};

ok( $is_sorted->( $fl->get_all_teams ), "Teams are sorted" ) || diag( Dumper $fl->get_all_teams );

done_testing;

