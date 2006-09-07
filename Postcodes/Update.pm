package Geo::Postcodes::Update;

#################################################################################
#                                                                               #
#                                                                               #
#                                                                               #
#                                                                               #
#################################################################################

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

my %EXPORT_TAGS = ();
my @EXPORT_OK   = qw(update);
my @EXPORT      = qw();

#################################################################################

sub update
{
  my($out, @files_and_procedures) = @_;

  $out    = "$out.pm" unless $out =~ /\.pm$/;

  chdir("..") unless -e $out; # Back up a directory.

  die("Unable to find '$out'") unless -e $out;

  my $source = "$out." . time;

  rename($out, $source) or die "Unable to rename file $out.\n";

  open(SOURCE, $source) or die "Unable to open the file $source.\n";
  open(OUT,    ">$out") or die "Unable to open the file $out.\n";

  ## Copy the old file - part 1

  my $part = 1; # 1 (first) 2 (skip) 3 (last)
  my @part1;
  my @part3;

  foreach (<SOURCE>)
  {
    if (/^\#\# bin\/update begin/)
    {
      $part = 2; # This part we skip.
    }
    elsif (/^\#\# bin\/update end/)
    {
      $part = 3;
    }
    if    ($part == 1) { push(@part1, $_); }
    elsif ($part == 3) { push(@part3, $_); }
  }

  close SOURCE;

  print OUT @part1;

  ## Update the postal info - part 2

  print OUT "## bin/update begin\n";
  print OUT "## This data structure was auto generated on " . localtime() . ". Do NOT edit it!\n\n";

  my($file, $procedure);

  while (1)
  {
    $file      = shift(@files_and_procedures) || last;
    $procedure = shift(@files_and_procedures) || last;

    my $in     = "bin/$file";
    open(IN,     $in)     or die "Unable to open the file $in.\n";

    print OUT &$procedure(<IN>);
    close IN;
  }

  ## Copy the old file - part 3

  print OUT @part3;
  close OUT;
}

1;

__END__

=head1 NAME

Geo::Postcodes::Update - Helper module for keeping the postcodes up to date

=head1 Procedures

=head2 update

=cut
