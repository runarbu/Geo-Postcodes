package Geo::Postcodes;

use strict;
use warnings;

## Which methods are available ##################################################

my @valid_methods = qw(postcode location borough county type owner address selection);
  # Used by the 'methods' method.

my %valid_methods;

foreach (@valid_methods)
{
  $valid_methods{$_} = 1;
}

## Exporter #####################################################################

require Exporter;
our @ISA = qw(Exporter);

my %EXPORT_TAGS = ( 'all' => [ qw(valid legal location_of borough_of county_of type_of
                                  owner_of address_of) ] );

my @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} });

my @EXPORT = qw();

our $VERSION = '0.02';

## OO Methods ###################################################################

our %postcode_of;
our %location_of;
our %borough_of;
our %county_of;
our %type_of;
our %owner_of;
our %address_of;

sub new
{
  my $class      = shift;
  my $postcode   = shift;
  my $self       = shift; # Allow for subclassing.

  return undef unless valid($postcode);

  unless ($self)
  {
    $self = bless \(my $dummy), $class;
  }

  $postcode_of  {$self} = $postcode;
  $location_of  {$self} = location_of($postcode);
  $borough_of   {$self} = borough_of($postcode);
  $county_of    {$self} = county_of($postcode);
  $type_of      {$self} = type_of($postcode);
  $owner_of     {$self} = owner_of($postcode);
  $address_of   {$self} = address_of($postcode);
  return $self;
}

sub DESTROY {
  my $dead_body = $_[0];
  delete $postcode_of  {$dead_body};
  delete $location_of  {$dead_body};
  delete $borough_of   {$dead_body};
  delete $county_of    {$dead_body};
  delete $type_of      {$dead_body};
  delete $owner_of     {$dead_body};
  delete $address_of   {$dead_body};
}

sub postcode
{
  my $self = shift;
  return unless defined $self;
  return $postcode_of{$self} if exists $postcode_of{$self};
  return;
}

sub location
{
  my $self = shift;
  return unless defined $self;
  return $location_of{$self} if exists $location_of{$self};
  return;
}

sub borough
{
  my $self = shift;
  return unless defined $self;
  return $borough_of{$self} if exists $borough_of{$self};
  return;
}

sub county
{
  my $self = shift;
  return unless defined $self;
  return $county_of{$self} if exists $county_of{$self};
  return;
}

sub type
{
  my $self = shift;
  return unless defined $self;
  return $type_of{$self} if exists $type_of{$self};
  return;
}

sub owner
{
  my $self = shift;
  return unless defined $self;
  return $owner_of{$self} if exists $owner_of{$self};
  return;
}

sub address
{
  my $self = shift;
  return unless defined $self;
  return $address_of{$self} if exists $address_of{$self};
  return;
}

sub methods
{
  return @valid_methods;
}

sub is_method
{
  my $method = shift;
  $method    = shift if $method =~ /Geo::Postcodes/; # Called on an object.

  return 1 if $valid_methods{$method};
  return 0;
}

## Global Procedures  - Stub Version, Please Subclass ###########################

sub legal # Is it a legal code, i.e. something that follows the syntax rule.
{
  return 0;
}

sub valid # Is the code in actual use.
{
  return 0;
}

sub location_of
{
  return;
}

sub borough_of
{
  return;
}

sub county_of
{
  return;
}

sub type_of
{
  return;
}

sub owner_of
{
  return;
}

sub address_of
{
  return;
}

sub get_postcodes
{
  return;
}

## Returns a list of postcodes if called as a procedure; Geo::Postcodes::NO::selection(xx => 'yy')
## Returns a list of objects if called as a method;      Geo::Postcodes::NO->selection(xx => 'yy')

sub selection
{
  return Geo::Postcodes::_selection("Geo::Postcodes", \%valid_methods, @_);
}

sub _selection
{
  my $prefix         = shift;
  my $legal_methods  = shift; # pointer to hash of legal methods.
  my $oo             = 0; 
  my $method         = shift;

  if ($method =~ /Geo::Postcodes/)
  {
    $oo     = 1;
    $method = shift;
  }

  # $prefix .= '::' unless $prefix =~ /::$/;

  # my $check = "$prefix::$methods";

  return unless $$legal_methods{$method}; # Check for a valid method

  my $value = shift;               # The value to search for

  return unless $value;            # A validity check is impossible, so this is the next best thing.

# if ($value =~ /\|/)
# {
#   my @value_fixed;
#   foreach my $new_value (split /|/, $value)
#   {
#     $new_value =~ s/%/\.\*/g;
#     $new_value = "^$new_value\$";
#     push(@value_fixed, $new_value);
#   }
#   $value = "(^" . join("|", @value_fixed) . "\$)";
# }
# else
# {
    $value =~ s/%/\.\*/g;
#   $value = "^$value\$";
# }

  my $current_value;
  my @set = ();

  my $procedure = $prefix . '::' . $method .'_of'; # From method to procedure.
  my $pointer = \&{$procedure};                            #  and get a pointer to it.

  my $procedure2 = $prefix . '::get_postcodes';
  my $pointer2   = \&{$procedure2};
 
  foreach (&$pointer2())
  {
    $current_value = $pointer->($_);    ## Call the procedure with the current postcode
    next unless $current_value;         ## Skip postcodes without this field.

    if ($current_value =~ m{^$value$}i) ## Case insensitive
    {
       push(@set, $_);
    }
  }
  @set = sort @set;

  return @set unless $oo;

  my @oo_set;

  foreach (@set)
  {
    push(@oo_set, $prefix->new($_));
  }

  return @oo_set;
}

1;
__END__

=head1 NAME

Geo::Postcodes - Base class for the Geo::Postcodes::XX modules

=head1 SYNOPSIS

This is the base class for the Geo::Postcodes::XX modules.

See the 'SUBCLASS' file for information on how to make your own subclass.

=head1 ABSTRACT

Geo::Postcodes - Base class for the Geo::Postcodes::XX modules. It is
useless on its own.

=head1 COMMON FEATURES

The child classes inherit the following methods and procedures (through
some black magic).

=head2 selection procedure

my @postcodes = Geo::Postcodes::NO::selection(method => $value);

Use this to get a list of all the postcodes associated with the
specified method and value. The methods can be either one mentioned
in the METHODS section, except I<selection>.

Wildcards are supported, by placing one or more I<%> in $value. The
I<%> will match zero or more arbitrary characters (as in standard SQL).
Use I<.> (a single period) to match exactly one character.

DEFECTIVE: Use | to combine searches; Location and I<%ÅS|%SKOG> will
give all  locations ending with "ÅS" or "SKOG". CAVEAT: This will enter
an implicit I<%> before and after the |, if not given.

The match is done case insensitive, but this does not work for the special
norwegian and danish characters 'Æ', 'Ø' and 'Å'.

=head2 selection method

my @postcodobjects = Geo::Postcodes::NO->selection(method => $value);

This works just as the procedure version (see above), but will return
a list of postcode objects (instead of a list of postcodes).

=head1 DESCRIPTION

=head1 CAVEAT

This module uses "inside out objects".

=head1 SEE ALSO

The latest version of this library should always be available on CPAN, but see
also the library home page; L<http://bbop.org/perl/GeoPostcodes> for addittional
information and sample usage.

=head1 AUTHOR

Arne Sommer, E<lt>arne@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Arne Sommer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
