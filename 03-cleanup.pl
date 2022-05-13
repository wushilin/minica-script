#!/usr/bin/perl

print("This will delete the CA, and all issued certs as well as their keys. \nAre you sure? YES!/NO[default=NO]: ");
my $ans = <STDIN>;
chomp $ans;
if($ans ne "YES!") {
   print("You must answer 'YES!' to proceed.\n");
   exit;
}

print("As you wish!\n");
`rm -rf index.txt*`;
`rm -rf serial.txt*`;
&rm("certs", "issued", "CERT_SETTINGS", "SETTINGS", "CA.key", "CA.pem", "openssl-ca.conf");
print "Done!\n";
sub rm {
	foreach my $f(@_) {
		if(-e $f) {
      print "Deleting $f\n";
			print `rm -rf $f`;
		} else {
			print "$f is already gone.\n";
		}
	}
}
