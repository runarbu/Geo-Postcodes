package Geo::Postcodes;

use strict;
use warnings;

our $VERSION = '0.10';

## Which methods are available ##################################################

my @valid_methods = qw(postcode location borough county type type_verbose owner
                       address);  # Used by the 'get_methods' procedure.

my %valid_methods;

foreach (@valid_methods)
{
  $valid_methods{$_} = 1; # Used by 'is_method' for easy lookup.
}

## Type Description #############################################################

my %typedesc;

$typedesc{BX}   = "Post Office box";
$typedesc{ST}   = "Street address";
$typedesc{SX}   = "Service box";
$typedesc{IO}   = "Individual owner";
$typedesc{STBX} = "Street Address and Post Office box";
$typedesc{MU}   = "Multiple usage";
$typedesc{PP}   = "Porto Paye receiver";

$typedesc{PN}   = "Place name";

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

  return unless valid($postcode);

  unless ($self)
  {
    $self = bless \(my $dummy), $class;
  }

  $postcode_of {$self} =              $postcode;
  $location_of {$self} = location_of ($postcode);
  $borough_of  {$self} = borough_of  ($postcode);
  $county_of   {$self} = county_of   ($postcode);
  $type_of     {$self} = type_of     ($postcode);
  $owner_of    {$self} = owner_of    ($postcode);
  $address_of  {$self} = address_of  ($postcode);
  return $self;
}

sub DESTROY {
  my $dead_body = $_[0];
  delete $postcode_of {$dead_body};
  delete $location_of {$dead_body};
  delete $borough_of  {$dead_body};
  delete $county_of   {$dead_body};
  delete $type_of     {$dead_body};
  delete $owner_of    {$dead_body};
  delete $address_of  {$dead_body};
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

sub type_verbose
{
  my $self = shift;
  return unless defined $self;
  return unless exists $type_of{$self};
  return unless exists $typedesc{$type_of{$self}};
  return $typedesc{$type_of{$self}};
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

#################################################################################

sub get_postcodes      ## Return all the postcodes, unsorted.
{
  return;
}

sub get_methods        ## Get a list of legal methods for the class/object.
{
  return @valid_methods;
}

sub is_method          ## Is the specified method legal. Can be called as
{                      ## a procedure, or as a method.
  my $method = shift;
  $method    = shift if $method =~ /Geo::Postcodes/; # Called on an object.

  return 1 if $valid_methods{$method};
  return 0;
}

## Global Procedures  - Stub Version, Override in your subclass #################

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

sub type_verbose_of
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

sub get_types
{
  return keys %typedesc;
}

sub type2verbose
{
  my $type = shift;
  return unless $type;
  return unless exists $typedesc{$type};
  return $typedesc{$type};
}

sub selection
{
  return Geo::Postcodes::_selection("Geo::Postcodes", @_);
    # Black magick.
}

my %legal_mode; $legal_mode{and} = $legal_mode{or}  = 1;
                $legal_mode{not} = $legal_mode{all} = 1;

#################################################################################
#                                                                               #
#  Returns a list of postcodes if called as a procedure;                        #
#    Geo::Postcodes::XX::selection(xx => 'yy')                                  #
#  Returns a list of objects if called as a method;                             #
#    Geo::Postcodes::XX->selection(xx => 'yy')                                  #
#                                                                               #
# Note that 'or' and 'not' are not written efficient, as they recompile the     #
# regular expression(s) for every postcode.                                     #
#                                                                               #
#################################################################################

sub _selection
{
  my $caller_class      = shift;
  my $mode              = shift; # Legal values are 'and' and 'or'.

  my $objects_requested = 0; # Not object oriented.

  if ($mode eq $caller_class) ## was =~ /Geo::Postcodes/)
  {
    $objects_requested  = 1;
    $mode               = shift;
  }

  unless ($legal_mode{$mode})    # Check for old-style one-method-and-value usage
  {
    unshift(@_, $mode);          # The method, put it back.
    $mode = 'and';               # It doesn't really matter, but we must choose one.
  }

  return unless $legal_mode{$mode};

  my @out = ();

  ###############################################################################

  if ($mode eq "and")
  {
    my $method;
    my $value;
    my @argument_list = @_;

    my @in = &{&proc_pointer($caller_class . '::get_postcodes')}();
      # Get all the postcodes.

    while (@argument_list)
    {
      @out = (); # Cleanup after the previous loop iteration.

      $method = shift(@argument_list);
      return unless &{&proc_pointer($caller_class . '::is_method')}($method);
        # Return if the specified method is undefined for the class.
        # As and 'and' with a list with one undefined item gives an empty list.

      $value  = shift(@argument_list);
      return unless $value;
        # A validity check is impossible, so this is the next best thing.

      $value =~ s/%/\.\*/g;

      my $current_value;
      my $current_method = &proc_pointer($caller_class . '::' . $method .'_of');

      foreach my $postcode (@in)
      {
        $current_value = $current_method->($postcode);
          # Call the procedure with the current postcode as argument

        next unless $current_value;
          # Skip postcodes without this field.

        push(@out, $postcode) if $current_value =~ m{^$value$}i; ## Case insensitive
      }
      @in = @out if @argument_list;
    }
  }

  ###############################################################################

  elsif ($mode eq "or")
  {
    my $method;
    my $value;

POSTCODE:
    foreach my $postcode (&{&proc_pointer($caller_class . '::get_postcodes')}()) # Get all the postcodes.
    {
      my @argument_list = @_;
METHOD:
      while (@argument_list)
      {
        $method = shift(@argument_list);
        next POSTCODE unless &{&proc_pointer($caller_class . '::is_method')}($method);
          # Simply skip unknown methods, as that it doesn't screw up our 'or' list in any way.

        $value  = shift(@argument_list);
        next POSTCODE unless $value;
          # A validity check is impossible, so this is the next best thing.

        $value =~ s/%/\.\*/g;

        my $current_method = &proc_pointer($caller_class . '::' . $method .'_of');

        my $current_value  = $current_method->($postcode);
          # Call the procedure with the current postcode as argument

        next unless $current_value;
          # Skip postcodes without this field.

        if ($current_value =~ m{^$value$}i)
	{
          push(@out, $postcode); ## Case insensitive
          next POSTCODE;
	}
      }
    }
  }
  ###############################################################################

  elsif ($mode eq "not") # Only include the postcode if it doesn't match any of the arguments.
  {                      # as 'or', but next postcode if matching, and include the postcode
    my $method;
    my $value;

POSTCODE_NOT:
    foreach my $postcode (&{&proc_pointer($caller_class . '::get_postcodes')}()) # Get all the postcodes.
    {
      my @argument_list = @_;

      while (@argument_list)
      {
        $method = shift(@argument_list);
        next POSTCODE_NOT unless &{&proc_pointer($caller_class . '::is_method')}($method);
          # Simply skip unknown methods, as that it doesn't screw up our 'or' list in any way.

        $value  = shift(@argument_list);
        next POSTCODE_NOT unless $value;
          # A validity check is impossible, so this is the next best thing.

        $value =~ s/%/\.\*/g;

        my $current_method = &proc_pointer($caller_class . '::' . $method .'_of');

        my $current_value  = $current_method->($postcode);
          # Call the procedure with the current postcode as argument

        next unless $current_value;
          # Skip postcodes without this field.

        next POSTCODE_NOT if $current_value =~ m{^$value$}i;
          # A match
      }

      push(@out, $postcode); ## Case insensitive
        # Include the postcode if none of the methods gave a match.
    }
  }
  ###############################################################################

  elsif ($mode eq "all")
  {
    @out = &{&proc_pointer($caller_class . '::get_postcodes')}();
      # This one isn't very useful, as it duplicates 'get_postcodes'.
      # But it can be used object oriented to get all the objects, if
      # time (and memory usage) is of no importance.
  }

  ###############################################################################

  @out = sort @out;
    # This will give an ordered list, as opposed to a semi random order. This   #
    # is essential when comparing lists of postcodes, as the test scripts do.   #

  ###############################################################################

  return unless @out;
    # Return undef if we have an empty list.

  return @out unless $objects_requested;

  my @out_objects;

  foreach my $postcode (@out)
  {
    push(@out_objects, $caller_class->new($postcode));
  }

  return @out_objects;
}

sub proc_pointer
{
  my $procedure_name = shift;
  return \&{$procedure_name};
}

1;
__END__

=head1 NAME

Geo::Postcodes - Base class for the Geo::Postcodes::XX modules

=head1 SYNOPSIS

This is the base class for the Geo::Postcodes::XX modules.

Note that information on how to make a country specific subclass will not be
written until the API is finalised.

=head1 ABSTRACT

Geo::Postcodes - Base class for the Geo::Postcodes::XX modules. It is
useless on its own.

=head1 COMMON FEATURES

The child classes inherit the following methods and procedures (through
some black magic):

=head2 selection procedure

 my @postcodes = Geo::Postcodes::XX::selection($method => $string);

This simple form will give a list of postcodes matching the specified method
and string. Substitute 'XX' by a valid country subclass. The methods can be 
anyone given by the C<Geo::Postcodes::XX::get_methods()> call. The resulting
list of postcodes is sorted.

It is possible to specify more than one method/string pair, but then the mode 
must be given. Use as many metod/value-pairs as required. (The mode can be
specified for the one pair version of 'or|and' as well, but will have no effect.)

=over

=item and

The postcode is included in the result if it is included in B<all> the expressions.

 my @postcodes = Geo::Postcodes::XX::selection('and',
    $method => $string, $method2 => $string2, ...);

Return postcodes matching I<all> the method/string pairs.

The computation will work faster if the method/string pairs are given with the one with
the most matches first, and the one with the least matches last.
given first

=item or

The postcode is included in the result if it is included in at least B<one of> the
expressions.

 my @postcodes4 = Geo::Postcodes::XX::selection('or',
    $method => $string, $method2 => $string2);

Return postcodes matching I<one or more> of the method/string pairs.

The computation will work faster if the method/string pairs are given with the one with
the least matches first, and the one with the most matches last.
given first


=item not

The postcode is included in the result if it is included in B<none of> the expressions.

 my @postcodes4 = Geo::Postcodes::XX::selection('not',
    $method => $string, $method2 => $string2);

Return the postcodes I<not> matching any of the method/string pairs. (This is the same as
C<all - or>, on sets of postcodes.)

=item all

All the postcodes.

 my @postcodes4 = Geo::Postcodes::XX::selection('all');

This will simply return I<all> the postcodes. Any additional arguments 
are silentliy ignored.

This is the same as I<sort(get_postcodes())>. The object oriented version
(see below for syntax) will return a postcode object for each postcode,
and can be handy in some circumstances - if time and memory usage is
of no concern. Otherwise create the postcode objects only when needed,
inside a I<foreach>-loop.

=back

The search string is parsed as the regular expression C<m{^$string$}i>.
This has the following implications:

=over

=item m{...}i

The trailing i means that the search is done case insensitive. This
does not work for the special norwegian and danish characters 'Æ',
'Ø' and 'Å' unless a C<use locale> is used in the program, and the
current locale supports these characters. (This does not work when
the code is running with mod_perl on my web servers, until I find
a solution.)

I<'As'> will match 'AS', 'As', 'aS', and 'as'.

=item m{^...$}

The first (I<^>; caret) and last (I<$>; dollar sign) character inside
the expression force a matcth to the whole expression. 

I<'AS'> will match exactly the four variations mentioned above, and
nothing else (so that 'CHAS' or 'ASIMOV' will not match).

Use L<"Wildcards"> or L<"Regular expressions"> to match several
characters at once.

=back

=head3 Wildcards

The character I<%> (the percent character) will match zero or more
arbitrary characters (and is borrowed from standard SQL).

I<'%12'> will match '1112' but not '1201'. I<'O%D'> will match all
strings starting with an 'O' and ending with a 'D'. I<'%A%'> will match all
strings with an 'A' somewhere.

(The character I<%> is changed to the regular expression '.*' (dot star)
by the module.)

=head3 Regular expressions

=over

=item .

The character . (a single dot) will match exactly one character.

I<'..11'> will match a four character string, where the first two can be anything,
followed by '11'.

=item ?

The character ? (a question mark) will match the previous character
zero or one time.

I<'%ØYA?'> will match strings ending with 'ØY' or 'ØYA'.

=item *

The character * (a star) will match the previous character zero or
more times. 

=item []

The expression I<'[AB]'> will match one of 'A' or'B'.

I<%'[AB]'> will match all names ending with an 'A' or 'B'.

=cut ()

The expression I<'(..)'> will remember the part inside the paranthesis.
See the next item for usage.

It can also be used in combination with back references; C<\1>, C<\2>
and so on. I<(..)\1> will match postcodes starting with two caharcters,
and ending with the same ones (e.g. '1919', 7272', but not '1221').
I<(.)(.)\2\1> will match postcodes where the first and fourth digit is
the same, and the second and third digit is the same.

=cut |

The expression I<'A|BBB'> will match either 'A' or 'BBB'.

Be careful with this construct, as I<'%ÅS|%SKOG'> will B<not>
match '%ÅS' or '%SKOG', but rather everything starting with 'ÅS'
or ending with 'SKOG' - caused by the C<'^...$'> that the expression
is wrapped in. Use I<'%(ÅS|SKOG)'> to get the desired result.

=head2 selection method

 my @postcodobjects = Geo::Postcodes::XX->selection(xxxx);

This works just as the procedure version (see above), but will return
a list of postcode objects (instead of just the postcodes).

=head2 type2verbose procedure

  my $type_as_english_text  = $Geo::Postcodes::type2verbose($type);
  my $type_as_national_text = $Geo::Postcodes::XX:type2verbose($type);

The child classes are responsible for translating the relevant types.

See the L<"TYPE"> section for a description of the types.

=head1 TYPE

This class defines the following types for the postal locations:

=over

=item BX

Post Office box

=item ST

Street address

=item SX

Service box (as a Post Office box, but the mail is delivered to
the customer).

=item IO

Individual owner (a company with its own postcode).

=item STBX

Either a Street address (ST) or a Post Office box (BX)

=item MU

Multiple usage (a mix of the other types)

=item PP

Porto Paye receiver (mail where the reicever will pay the postage).

=item PN

Place name

=cut

The child classes can use a subset of these, and define the descriptions
in the native language if appropriate.

Use C<type2verbose> (see above) to get the description for a given code.

=head1 DESCRIPTION

=head1 CAVEAT

This module uses "inside out objects".

C<Selection or> and C<Selection not> is not written efficiently, as the
regular expressions are recompiled for every postcode. This will be fixed
in the future.

=head1 SEE ALSO

The latest version of this library should always be available on CPAN, but see
also the library home page; L<http://bbop.org/perl/GeoPostcodes> for additional
information and sample usage. The child classes that can be found there have
some sample programs.

=head1 AUTHOR

Arne Sommer, E<lt>perl@bbop.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
