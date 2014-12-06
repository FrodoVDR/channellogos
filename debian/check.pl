#!/usr/bin/perl
use strict;
use File::Basename;

foreach my $logo (glob("./logos/*")) {
  if ( "$logo" =~ /.png$/ )
  {
    print "$logo"."\n";
    my $name = $logo;
    $name =~ s/.png/.svg/g;
    if ( -f $name )
    {
      print "found: $name"."\n";
    }
  }
}

