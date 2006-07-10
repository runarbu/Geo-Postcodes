package Geo::Postcodes;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

my %EXPORT_TAGS = ( 'all' => [ qw(valid legal location_of borough_of county_of type_of
                                  owner_of address_of) ] );

my @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

my @EXPORT = qw( );

our $VERSION = '0.01';

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

1;
__END__

=head1 NAME

Geo::Postcodes - Base class for the Geo::Postcodes::XX modules

=head1 SYNOPSIS

This is the base class for the Geo::Postcodes::XX modules.

See the 'SUBCLASS' file for information on how to make your own subclass.

=head1 ABSTRACT

Geo::Postcodes - Base class for the Geo::Postcodes::XX modules.

=head1 DESCRIPTION

=head1 CAVEAT

This module uses "inside out objects".

=head1 SEE ALSO

The latest version of this library should always be available on CPAN, 
but see also the library home page; L<http://bbop.org/perl/GeoPostcodes>.

I<perldoc Geo::Postcodes::NO> and I<perldoc Geo::Postcodes::DK>.

=head1 AUTHOR

Arne Sommer, E<lt>arne@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Arne Sommer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
