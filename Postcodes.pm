package Geo::Postcodes;

use strict;
use warnings;

our $VERSION = '0.20';

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

my %legal_mode; $legal_mode{'and'} = $legal_mode{'and not'} =
                $legal_mode{'nor'} = $legal_mode{'nor not'} =
                $legal_mode{'or'}  = $legal_mode{'or not'}  =
                $legal_mode{'xor'} = $legal_mode{'xor not'} = 1;

sub is_legal_selectionmode
{
  my $mode = shift;
  return $legal_mode{$mode};
}

sub is_legal_initial_selectionmode
{
  my $mode = shift;
  return 1 if $mode eq 'all' or $mode eq 'none' or $mode eq 'not';
  return $legal_mode{$mode};
}

sub get_selectionmodes
{
  return sort keys %legal_mode;
}

sub get_initial_selectionmodes
{
  return sort (get_selectionmodes(), 'all', 'none', 'not');
}

sub verify_selectionlist
{
  return Geo::Postcodes::_verify_selectionlist('Geo::Postcodes', @_);
    # Black magic.
}

sub _verify_selectionlist
{
  my $caller_class = shift;
  my @args         = @_;    # A list of selection arguments to verify

  my $status       = 1;     # Return value
  my @out          = ();
  my @verbose      = ();

  return (0, "No arguments") unless @args;

  if (is_legal_initial_selectionmode($args[0]))
  {
    my $mode = shift @args;

    if (@args and $args[0] eq "not" and is_legal_selectionmode("$mode $args[0]"))
    {
      $mode = "$mode $args[0]";
      shift @args;
    }

    push @out, $mode;
    push @verbose, "Mode: '$mode' - ok";

    return (1, @out) if $mode eq "all" or $mode eq "none";

    return (0, @verbose, "Missing method/value pair - not ok") unless @args >= 2;
      # Missing method/value pair.
  }

  ## Done with the first one

  while (@args)
  {
    my $argument = shift(@args);

    if ($caller_class->is_method($argument))
    {
      push @out, $argument;
      push @verbose, "Method: '$argument' - ok";

      if (@args)
      {
        $argument = shift(@args);
        push @out, $argument;
        push @verbose, "String: '$argument' - ok";
      }
      else
      {
        push @verbose, "Missing string - not ok"; # The last element was a method.
        $status = 0;
        @args = (); # Terminate the loop
      }          
    }
    elsif (is_legal_selectionmode($argument))
    {
      if (@args and $args[0] eq "not" and is_legal_selectionmode("$argument $args[0]"))
      {
        $argument = "$argument $args[0]";
        shift @args;
      }
      push @out, $argument;
      push @verbose, "Mode: '$argument' - ok";

      unless (@args >= 2) # Missing method/value pair
      {
        push @verbose, "Missing method/value pair - not ok";
        $status = 0;
        @args = (); # Terminate the loop
      }
    }
    else
    {
      push @verbose, "Illegal argument: '$argument' - not ok";
      $status = 0;
      @args = (); # Terminate the loop
    }
  }

  return (1, @out) if $status;

  return (0, @verbose);
}


#################################################################################
#                                                                               #
#  Returns a list of postcodes if called as a procedure;                        #
#    Geo::Postcodes::XX::selection(...)                                         #
#  Returns a list of objects if called as a method;                             #
#    Geo::Postcodes::XX->selection(...)                                         #
#                                                                               #
# Note that 'or' and 'not' are not written efficient, as they recompile the     #
# regular expression(s) for every postcode.                                     #
#                                                                               #
#################################################################################

sub selection
{
  return Geo::Postcodes::_selection('Geo::Postcodes', @_);
    # Black magic.
}

sub _selection
{
  my $caller_class      = shift;

  my $objects_requested = 0; # Not object oriented.

  if ($_[0] eq $caller_class)
  {
    $objects_requested  = 1;
    shift;
  }

  if ($_[0] eq 'all')
  {
    my @all = sort &{&proc_pointer($caller_class . '::get_postcodes')}();
      # Get all the postcodes.

    return @all unless $objects_requested;

    my @out_objects;

    foreach my $postcode (@all)
    {
      push(@out_objects, $caller_class->new($postcode));
    }

    return @out_objects;    
  }

  elsif ($_[0] eq 'none')
  {
    return; # Absolutely nothing.
  }

  my $mode = "and"; 
    # The mode defaults to 'and' unless specified.

  $mode = shift if is_legal_initial_selectionmode($_[0]);

  my %out = ();

  ## The first set of method/value ##############################################

  my @all = &{&proc_pointer($caller_class . '::get_postcodes')}();
    # Get all the postcodes.

  my $method = shift;
  return unless &{&proc_pointer($caller_class . '::is_method')}($method);
    # Return if the specified method is undefined for the class.
    # As and 'and' with a list with one undefined item gives an empty list.

  my $current_method = &proc_pointer($caller_class . '::' . $method .'_of');

  my $value  = shift; $value =~ s/%/\.\*/g;
  return unless $value;
    # A validity check is impossible, so this is the next best thing.

  my $current_value;

  foreach my $postcode (@all)
  {
    $current_value = $current_method->($postcode);
      # Call the procedure with the current postcode as argument

    next unless $current_value;
      # Skip postcodes without this field.

    my $match = $current_value =~ m{^$value$}i; ## Case insensitive

    if ($mode =~ /not/) { $out{$postcode}++ unless $match; }
    else                { $out{$postcode}++ if     $match; }
  }

  $mode = 'and' if $mode eq 'not';

  while (@_)
  {
    $mode = shift if is_legal_selectionmode($_[0]);
      # Use the one already on hand, if none is given.

    $method = shift;
    return unless &{&proc_pointer($caller_class . '::is_method')}($method);
      # Return if the specified method is undefined for the class.
      # As an 'and' with a list with one undefined item gives an empty list.

    $current_method = &proc_pointer($caller_class . '::' . $method .'_of');

    $value = shift; 
    $value =~ s/%/\.\*/g;
    return unless $value;
      # A validity check is impossible, so this is the next best thing.

    foreach my $postcode ($mode =~ /and/ ? (keys %out) : @all)
    {
      $current_value = $current_method->($postcode);
        # Call the procedure with the current postcode as argument

      next unless $current_value;
        # Skip postcodes without this field.

      my $match = $current_value =~ m{^$value$}i; ## Case insensitive

      if    ($mode eq "and")
      {
        delete $out{$postcode} unless $match;
      }
      elsif ($mode eq "and not")
      {
        delete $out{$postcode} if     $match;
      }
      elsif ($mode eq "or")
      {
        $out{$postcode}++      if     $match;
      }
      elsif ($mode eq "or not")
      { 
        $out{$postcode}++      unless $match;
      }
      elsif ($mode eq "xor")
      {
        if ($match)
        {
          if ($out{$postcode}) { delete $out{$postcode}; }
          else                 { $out{$postcode}++;      }
        }
      }
      elsif ($mode eq "xor not")
      {
        unless ($match)
        {
           if ($out{$postcode}) { delete $out{$postcode}; }
           else                 { $out{$postcode}++;      }
        }
      }
      elsif ($mode eq "nor")
      {
        if (!$match and !$out{$postcode}) { $out{$postcode}++;                         }
        else                              { delete $out{$postcode} if $out{$postcode}; }
      }
      elsif ($mode eq "nor not")
      {
        if ($match and !$out{$postcode})  { $out{$postcode}++;                         }
        else                              { delete $out{$postcode} if $out{$postcode}; }
      }
    }
  }

  ###############################################################################

  return unless %out;
    # Return nothing if we have an empty list (or rather, hash).

  my @out = sort keys %out;
    # This will give an ordered list, as opposed to a semi random order. This   #
    # is essential when comparing lists of postcodes, as the test scripts do.   #

  ###############################################################################

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
anyone given by the C<Geo::Postcodes::XX::get_methods()> call, and the string
either a literal text or a regular expression. The resulting list of postcodes
is sorted. 

It is possible to specify more than one method/string pair, but then the mode 
should be given (but it will default to 'and' otherwise). Use as many
method/value-pairs as required. The mode can be specified initially, between
the method/string pairs, or not at all.

The following examples are equivalent:

 Geo::Postcodes::XX::selection('and', $method => $string, $method2 => $string2);
 Geo::Postcodes::XX::selection($method => $string, 'and', $method2 => $string2);
 Geo::Postcodes::XX::selection($method => $string, $method2 => $string2);

The method/string pairs are evaluated in the specified order, and the modes
can be mixed freely:

 Geo::Postcodes::XX::selection($method1 => $string1,
                     'and',    $method2 => $string2,
                     'or',     $method3 => $string3,
                     'or not', $method3 => $string3,
                     'and not, $method4 => $string4,
                     'xor',    $method5 => $string5);

=over

=item all

All the postcodes.

 my @postcodes = Geo::Postcodes::XX::selection('all');

This will return I<all> the postcodes. Any additional arguments 
are silentliy ignored.

This is the same as I<sort get_postcodes()>. The object oriented version
(see below for syntax) will return a postcode object for each postcode,
and can be handy in some circumstances - if time and memory usage is
of no concern. Otherwise create the postcode objects only when needed,
inside a I<foreach>-loop on the procedure version.

=item and

The postcode is included in the result if it is included in B<all> the expressions.

 my @postcodes = Geo::Postcodes::XX::selection(
    $method1 => $string1, 'and', $method2 => $string2);

Return postcodes matching I<all> the method/string pairs.

The computation will work faster if the method/string pairs are given with the one with
the most matches first, and the one with the least matches last.
given first

=item and not

The postcode is included in the result if it is included in B<the first, but not the second> the expressions.

 my @postcodes = Geo::Postcodes::XX::selection(
    $method1 => $string1, 'and not', $method2 => $string2);

Return the postcodes I<not> matching any of the method/string pairs. (This is the same as
C<all - or>, on sets of postcodes.)

=item nor

The postcode is included in the result if it is included in B<none of> the
expressions.

 my @postcodes = Geo::Postcodes::XX::selection(
    $method1 => $string1, 'nor', $method2 => $string2);

=item nor not

The postcode is included in the result if it is included in B<the second expression only>.

 my @postcodes = Geo::Postcodes::XX::selection(
    $method1 => $string1, 'nor not', $method2 => $string2);

=item or

The postcode is included in the result if it is included in at least B<one of> the
expressions.

 my @postcodes = Geo::Postcodes::XX::selection(
    $method1 => $string1, 'or', $method2 => $string2);

Return postcodes matching I<one or more> of the method/string pairs.

The computation will work faster if the method/string pairs are given with the one with
the least matches first, and the one with the most matches last.
given first

=item or not

The postcode is included in the result if it is included in B<the first> expression, but not
the second.

 my @postcodes = Geo::Postcodes::XX::selection(
    $method1 => $string1, 'or not', $method2 => $string2);

It is also possible to achieved this by using 'or' and a reversed regular expression.

=item not

This mode can be used initially (as the first argument) to negate the first
method/string pair. It is also possible to use 'and not' or 'or not'.

Note that 'not' is not a valid mode, and it will default to 'and' for any
additional method/string pairs if no mode is given.

The following examples are equivalent:

 Geo::Postcodes::XX::selection('not', $method => $string, 'and', $method2 => $string2);
 Geo::Postcodes::XX::selection('not', $method => $string, $method2 => $string2);
 Geo::Postcodes::XX::selection('or not', $method => $string, 'and', $method2 => $string2);
 Geo::Postcodes::XX::selection('and not', $method => $string, 'and', $method2 => $string2);

The following examples are equivalent:

 Geo::Postcodes::XX::selection('or not', $method => $string, $method2 => $string2);
 Geo::Postcodes::XX::selection('not', $method => $string, 'or not', $method2 => $string2);

=item xor (exlusive or)

The postcode is included in the result if it is included in B<only one of> the expressions.

 my @postcodes = Geo::Postcodes::XX::selection(
    $method1 => $string1, 'xor', $method2 => $string2);

=item xor not

The postcode is included in the result if it is included in B<the first but not the second>
the expressions.

=back

The search string is parsed as the regular expression C<m{^$string$}i>.
This has the following implications:

=over

=item m{...}i

The trailing i means that the search is done case insensitive. This does not work for
the special norwegian and danish characters 'Æ', 'Ø' and 'Å' (as used in the subclasses
'NO' and 'DK') unless a C<use locale> is used in the program, and the current locale
supports these characters. (This will probably not work when the code is running with
mod_perl on a web server.)

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

=item '*'

The character * (a star) will match the previous character zero or
more times. 

=item []

The expression I<'[AB]'> will match one of 'A' or'B'.

I<%'[AB]'> will match all names ending with an 'A' or 'B'.

=item ()

The expression I<'(..)'> will remember the part inside the paranthesis.
See the next item for usage.

It can also be used in combination with back references; C<\1>, C<\2>
and so on. I<(..)\1> will match postcodes starting with two caharcters,
and ending with the same ones (e.g. '1919', 7272', but not '1221').
I<(.)(.)\2\1> will match postcodes where the first and fourth digit is
the same, and the second and third digit is the same.

=item |

The expression I<'A|BBB'> will match either 'A' or 'BBB'.

Be careful with this construct, as I<'%ÅS|%SKOG'> will B<not>
match '%ÅS' or '%SKOG', but rather everything starting with 'ÅS'
or ending with 'SKOG' - caused by the C<'^...$'> that the expression
is wrapped in. Use I<'%(ÅS|SKOG)'> to get the desired result.

=back

=head2 selection method

 my @postcodobjects = Geo::Postcodes::XX->selection(xxxx);

This works just as the procedure version (see above), but will return
a list of postcode objects (instead of just a list of postcodes).

=head1 SUPPORTING PROCEDURES

=head2 Geo::Postcodes::XX::verify_selectionlist

Use this procedure from the child class to verify that the arguments are valid
for use by the selction procedure/method.

 my($status, @list) = Geo::Postcodes::XX::verify_selectionlist(@arguments);

A status value of true (1) is followed by a modified version of the original
arguments. This will replace things as 'and' 'not' by 'and not', as the selection
procedure does not accept the former.

A status value of false (0) is followed by a list of diagnostic messages, up to
the point where the verification failed.

=head2 is_legal_selectionmode

Returns true if the mode is one of the list returned by C<get_selectionmodes>,
documented below. 

=head2 is_legal_initial_selectionmode

Returns true if the mode is one of the list returned by
C<get_initial_selectionmodes>, documented below.

=head2 get_selectionmodes

A sorted list of legal selection modes; 'and', 'and not', 'nor', 'nor not', 'or',
'or not', 'xor' and 'xor not'.

=head2 get_initial_selectionmodes

As above, with the addition of 'all', none' and 'not'. The list is sorted.

=head2 type2verbose procedure

  my $type_as_english_text  = $Geo::Postcodes::type2verbose($type);
  my $type_as_national_text = $Geo::Postcodes::XX:type2verbose($type);

The child classes are responsible for translating the relevant types to the native language.

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

=back

The child classes can use a subset of these, and define the descriptions
in the native language if appropriate.

Use C<type2verbose> (see above) to get the description for a given code.

=head1 DESCRIPTION

I<Missing.>

=head1 CAVEAT

This module uses "inside out objects".

=head1 SEE ALSO

The latest version of this library should always be available on CPAN, but see
also the library home page; F<http://bbop.org/perl/GeoPostcodes> for additional
information and sample usage. The child classes that can be found there have
some sample programs.

=head1 AUTHOR

Arne Sommer, E<lt>perl@bbop.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
