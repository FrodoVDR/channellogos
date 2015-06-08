#!/usr/bin/perl

if (not defined $ARGV[0]) {die "No parameter given! \ncreate-symlinks.pl <channels.conf> <logos> <link-dir>\n"};
if (not defined $ARGV[1]) {die "No parameter given! \ncreate-symlinks.pl <channels.conf> <logos> <link-dir>\n"};
if (not defined $ARGV[2]) {die "No parameter given! \ncreate-symlinks.pl <channels.conf> <logos> <link-dir>\n"};

my $logopath = "$ARGV[1]";
my $linkpath = "$ARGV[2]";

%img = ();

# svg folder einlesen
opendir DIR, "$logopath" or {die " cant open $logopath" };

while(my $file = readdir DIR) {
    if( $file =~ /\.(svg|png|jpg)$/i ) {
	$value = $file;
	$file =~ /(.*).([A-Za-z]{3})/;
	$key = $1;
	$key =~ s/\W//g;
	$img{$key} = $value;
    }
}
closedir DIR;


open LOG, ">translate.log" or die "Can't open log file!\n";

# channels.conf einlesen
open (FILE, "< $ARGV[0]") or die "Can't open file\n";
while (<FILE>) {
    $channame = $shortname = '';
    $line = $_;
    $line =~ s/\r\n//;
    if ($line =~ /^:/ or $line =~ /^@/ ) { next; }

    @line = split(/:/, $line);
    $line[0] =~ s/\'//;
    $line[0] =~ s/\///;
    if ($line[0] =~ m/;/) { $line[0] =~ /(.*);.*/; $line[0] = $1 }

    if ($line[0] =~ m/,/) { 
	@names = split(/,/, $line[0]);
	$channame = $names[0]; $shortname = $names[1];
    }
    else { $channame = $line[0]; $shortname = ''; }

    if ($channame eq '' or $channame eq '.') { next; }

    my($name, $frequency, $polarization, $source, $symbolrate, $vpid, $apid,
     $tpid, $ca, $service_id, $nid, $tid, $rid) = split(/\:/, $_);

    if ( $source eq 'T' || $source eq 'C' ) {
        if ( length($frequency) > 3) {
            $frequency=substr($frequency, 0, length($frequency)-3);
        }
        if ( length($frequency) > 3) {
            $frequency=substr($frequency, 0, length($frequency)-3);
        }
    }

    $data = $nid>0 ? $tid : $frequency;

    $channelid = "$source-$nid-$data-$service_id";
    # channelid changes for skindesigner
    $channelid =~ tr/[A-Z]/[a-z]/;
    


    
    $searchname = $channame;
    $searchname =~ s/\W//g;
    $searchname =~ tr/[A-Z]/[a-z]/;
    
    if ($img{$searchname}) {
	$cnt++;

	$type = $img{$searchname};
	$type =~ /(.*).([A-Za-z]{3})/;
	$type = $2;

	$status = symlink("$logopath/$img{$searchname}","$linkpath/$channelid.$type");
	if ($status == 1)  { print LOG "$channame => $channelid.$type => $logopath/$img{$searchname}"; }
	else { print LOG "$channame => failed"; } 
	if ($shortname and $shortname ne '') {
	    $status = symlink("$logopath/$img{$searchname}","$linkpath/$channelid.$type");
	    if ($status == 1)  { print LOG "\t$shortname"; }
	    else { print LOG "\t$shortname => failed"; } 
	}
	print LOG "\n"; next;
    }
    elsif ($shortname and $shortname ne '') {
	
	$searchname = $shortname;
	$searchname =~ s/\W//g;
	$searchname =~ tr/[A-Z]/[a-z]/;
    
	if ($img{$searchname}) {
	    $cnt++;

	$type = $img{$searchname};
	$type =~ /(.*).([A-Za-z]{3})/;
	$type = $2;

	    $status = symlink("./../$logopath/$img{$searchname}","$linkpath/$channelid.$type");
	    if ($status == 1)  { print LOG "$channame => $channelid.$type => ./../$logopath/$img{$searchname}"; }
	    else { print LOG "$shortname => failed"; } 
	    if ($channame and $channame ne '') {
		$status = symlink("./../$logopath/$img{$searchname}","$linkpath/$channelid.$type");
		if ($status == 1)  { print LOG "\t$channame"; }
	    else { print LOG "\t$channame => failed"; }
	    }
	    print LOG "\n"; next;
	}
    }
}
close(FILE) or die "Can't close file\n";
close(LOG) or die "Can't close file\n";

print $cnt, "\n";

