###############################################################################
#                                                                             #
#           Geo::Postcodes Test Suite 3 - Valid selection list                #
#         ------------------------------------------------------              #
#             Arne Sommer - perl@bbop.org - 7. September 2006                 #
#                                                                             #
###############################################################################
#                                                                             #
# Before `make install' is performed this script should be runnable with      #
# `make test'. After `make install' it should work as `3_validselection.t'.   #
#                                                                             #
###############################################################################

use Test::More tests => 40;

BEGIN { use_ok('Geo::Postcodes') };

###############################################################################

  valid('all');
  valid('all', 'xxxxxx'); # Everything after 'all' is silently ignored.

  valid('none');
  valid('none', 'xxxxxx'); # Everything after 'none' is silently ignored.

  valid('one');
  valid('one', 'postcode', '12..');
invalid('one', 'xxxxxx');
invalid('one', 'xxxxxx', 'yyyyy');

invalid('and');
  valid('and', 'postcode', '12..');

invalid('and not');
  valid('and not',    'postcode', '12..');
  valid('and', 'not', 'postcode', '12..');

invalid('not');
  valid('not', 'postcode', '12..');
  valid('not', 'postcode', '12..', 'postcode', '..9.');

invalid('or');
  valid('or', 'postcode', '12..');

invalid('or not');
  valid('or not', 'postcode', '12..');
  valid('or not', 'postcode', '12..');

invalid('nor');
  valid('nor', 'postcode', '12..');

invalid('nor not');
  valid('nor not',    'postcode', '12..');
  valid('nor', 'not', 'postcode', '12..');

invalid('xor');
  valid('xor', 'postcode', '12..');

invalid('xor not');
  valid('xor not',    'postcode', '12..');
  valid('xor', 'not', 'postcode', '12..');

  valid('postcode', 'what do you think?'); # A valid method, and an arbitrary value
  valid('postcode', '12..', 'and not',    'postcode', '12..');
  valid('postcode', '12..', 'and', 'not', 'postcode', '12..');

  valid(           'postcode' => '12..',     # '12' followed by two additional digits
        'and not', 'location' => '%s%',      # Containing an 's'
        'or',      'borough'  => '.....',    # 4 letters
        'nor',     'type'     => 'ST',       # 'Street address'
       );

invalid('elephant', 'Dumbo');

  valid('address',  '%s%');
  valid('county',   'F%');
  valid('borough',  '%øy');

###############################################################################

sub valid
{
  my @arguments = @_;

  my($status, undef) = Geo::Postcodes::verify_selectionlist(@arguments);

  ok ($status, "Valid selection list for core postcodes (" .
      join(",", @arguments) . ").\n");
}

sub invalid
{
  my @arguments = @_;

  my($status, undef) = Geo::Postcodes::verify_selectionlist(@arguments);

  ok (! $status, "Invalid selection list for core postcodes (" .
      join(",", @arguments) . ").\n");
}

###############################################################################
