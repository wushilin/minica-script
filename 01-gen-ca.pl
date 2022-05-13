#!/usr/bin/perl

# openssl genrsa -out CA.key 4096
# openssl req -x509 -new -nodes -key CA.key -sha512 -days 7300 -out CA.pem

if (-e "CA.key" or -e "CA.pem") {
	print("CA.key or CA.pem is already present. Please delete them first. \n");
  exit;
}

my $storepass = "changeme";
if(not -e "PASSWORD") {
  `echo $storepass > PASSWORD`;
  print("Using default store pass [changeme]\n");
  print("If you want to customize keystore password, cancel now, and edit PASSWORD file.\n");
} else {
	$storepass = `cat PASSWORD`;
	chomp $storepass;
  if(length($storepass) > 30) {
    $storepass = substr($storepass, 0, 30);
  }
  if(length($storepass) < 8) {
    print("PASSWORD file content is too short.\n");
		exit;
  }
  print("Loaded store pass [$storepass] from PASSWORD file\n");
}
my $C = &ask("C", "Country Name (2 letter code)");
my $ST = &ask("ST", "State or Province Name (full anme)");
my $L = &ask("L", "Locality Name (eg, city)");
my $O = &ask("O", "Organization Name (eg, company)");
my $OU = &ask("OU", "Organizational Unit Name (eg, section)");
my $CN = &ask("CN", "CA Name (eg, EnterpriseCA01)");
my $EMAIL = &ask("EMAIL", "Email Address");
&write(C=>$C, ST=>$ST, L=>$L, O=>$O, OU=>$OU, CN=>$CN, EMAIL=>$EMAIL);
system("openssl", "genrsa", "-out", "CA.key", "4096");
system("openssl", "req", "-subj", "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN","-x509", "-new", "-nodes", "-key", "CA.key", "-sha512", "-days", "7300", "-out", "CA.pem");
system("keytool", "-import", "-trustcacerts", "-keystore", "truststore.p12", "-storepass", "$storepass", 
	"-alias", "CA-with-name-$CN", "-file", "CA.pem", "-noprompt", "-storetype", "pkcs12");
system("keytool", "-import", "-trustcacerts", "-keystore", "truststore.jks", "-storepass", "$storepass", 
	"-alias", "CA-with-name-$CN", "-file", "CA.pem", "-noprompt", "-storetype", "jks");
`echo $storepass > truststore.password`;
&apply_template();
# Country Name (2 letter code) []:aa
# State or Province Name (full name) []:aa
# Locality Name (eg, city) []:aa
# Organization Name (eg, company) []:aa
# Organizational Unit Name (eg, section) []:aa
# Common Name (eg, fully qualified host name) []:aa
# Email Address []:a

sub ask($$) {
  my ($short, $long) = @_;
  while(1) {
	  print("Please enter $long ($short):");
	  my $val = <STDIN>;
    chomp $val;
    $val =~ s/^\s+//g;
    $val =~ s/\s+$//g;
    if(length($val) == 0) {
      print("??????????????????????\n");
    } else {
			return $val;
		}
  }
}

sub write {
  my %args = (@_);
  open FH, ">SETTINGS";
  foreach my $k(keys(%args)) {
	  print FH $k . "=" . $args{$k} . "\n";
  }
  close FH;
}

sub apply_template() {
  my $p = &read_p("SETTINGS");
  my $lines = `cat openssl-ca.template`;
  $lines = &subs($lines, $p);
  open FH, ">openssl-ca.conf";
  print FH $lines;
  close FH; 
}

sub subs($$) {
	my $template = shift;
  my $p = shift;
  foreach my $k(keys %$p) {
		my $v = $p->{$k};
		$template =~ s/%$k%/$v/g;
	}
	return $template;
}

sub print_p($) {
  my $p = shift;
	foreach my $k(keys %$p) {
		print $k . " => " . $p->{$k} . "\n";
  }
}

sub read_p($) {
  my $f = shift;
	open S, "<$f";
	my $p = {};
  while(<S>) {
    chomp;
		my $idx = index($_, "=");
    my $key = substr($_, 0, $idx);
    my $value = substr($_, $idx + 1);
    $p->{$key} = $value;
  }
  close S;
	return $p;
}
