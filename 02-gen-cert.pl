#!/usr/bin/perl

# openssl genrsa -out CA.key 4096
# openssl req -x509 -new -nodes -key CA.key -sha512 -days 7300 -out CA.pem

if (-e "CA.key" or -e "CA.pem") {
	print("CA.key or CA.pem is already present. Please delete them first. \n");
  exit;
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
shwu@C02DR0C3MD6T ~/D/ca-scripts-new (2)> ls
01-gen-ca.pl        02-gen-cert.pl      03-cleanup.pl       openssl-ca.template
shwu@C02DR0C3MD6T ~/D/ca-scripts-new (2)> cat 02-gen-cert.pl 
#!/usr/bin/env perl

if(@ARGV < 1) {
  print "Usage: " . __FILE__ . " <common name> <dns.1> <dns.2>...<dns.n> <ip.1> <ip.2> ... <ip.n>\n";
  exit 1;
}
if(not -e "serial.txt") {
  `echo "01" > serial.txt`;
}

if(not -e "index.txt") {
  `touch index.txt`;
}

`mkdir -p certs`;
`mkdir -p issued`;
my $DAYS = 7300;
my @ARGVF = ();

foreach my $arg(@ARGV) {
  if($arg =~ m/-days=(\d+)/) {
    $DAYS = $1;
    print "Using expiry days of $DAYS\n";
    next;
  }
  push @ARGVF, $arg;
}
my @hosts = ();
my @ips = ();

foreach my $arg(@ARGVF) {
  if(&is_ip($arg)) {
    push @ips, $arg;
  } else {
    push @hosts, $arg;
  }
}

my $CN = $hosts[0];
print "Create certs with following settings:\n";
print "Hosts: @hosts\n";
print "IPs: @ips\n";

my $outdir = "issued";
my @output = ("$outdir/$CN.p12", "$outdir/$CN.jks", "$outdir/$CN.key", "$outdir/$CN.csr", "$outdir/$CN.pem");
my $errcount = 0;
foreach my $out(@output) {
  if(-e $out) {
    print "$out";
    print "\n";
    $errcount++;
  }
}

if($errcount > 0) {
  print "Delete the above items before proceeding\n";
  exit 1;
}
sub is_ip($) {
  my $arg = shift;
  return $arg =~ m/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;
}
my $template = <<EOF
[ req ]
default_bits       = 4096
default_keyfile    = $CN.pem
distinguished_name = server_distinguished_name
req_extensions     = server_req_extensions
string_mask        = utf8only

####################################################################
[ server_distinguished_name ]
countryName         = Country Name (2 letter code)
countryName_default = %C%

stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = %ST%

localityName         = Locality Name (eg, city)
localityName_default = %L%

organizationName            = Organization Name (eg, company)
organizationName_default    = %O%

organizationalUnitName         = Organizational Unit (eg, division)
organizationalUnitName_default = %OU%

commonName           = Common Name (e.g. server FQDN or YOUR name)
commonName_default   = $CN

emailAddress         = Email Address
emailAddress_default = %EMAIL%

####################################################################
[ server_req_extensions ]

subjectKeyIdentifier = hash
basicConstraints     = CA:FALSE
keyUsage             = digitalSignature, keyEncipherment, keyAgreement, nonRepudiation
extendedKeyUsage     = critical, serverAuth, clientAuth
subjectAltName       = \@alternate_names
nsComment            = "OpenSSL Generated Certificate"

####################################################################
[ alternate_names ]
EOF
;

print "CN=$CN\n";
my $index = 1;
foreach my $host(@hosts) {
  $template = $template . "DNS.$index = $host\n";
  $index++;
}

$index = 1;
foreach my $host(@ips) {
  $template = $template . "IP.$index = $host\n";
  $index++;
}

my $settings = "SETTINGS";
if(-e "CERT_SETTINGS") {
	$settings = "CERT_SETTINGS";
}
print("Loading cert config from $settings. If you want to customize, please edit CERT_SETTINGS file\n");
my $p = &read_p($settings);
$template = &subs($template, $p);
my $config_file = "/tmp/openssl-config-" . time . ".conf";
open FH, ">$config_file";
print FH $template;
close FH;
mkdir "$outdir/";
&notice("Generating key pair and CSR ( => $outdir/$CN.key + $outdir/$CN.csr)\n");
`openssl req -config $config_file -newkey rsa:4096 -sha512 -nodes -keyout $outdir/$CN.key -out $outdir/$CN.csr -outform PEM -subj "/C=$p->{C}/ST=$p->{ST}/L=$p->{L}/O=$p->{O}/OU=$p->{OU}/CN=$CN"`;
# `rm $config_file`;
&notice("Signing certificate ($outdir/$CN.csr => $outdir/$CN.pem)\n");
`openssl ca -config openssl-ca.conf -days $DAYS -batch -policy signing_policy -extensions signing_req -out $outdir/$CN.pem -infiles $outdir/$CN.csr`;
&notice("Generating pkcs12 keystore ($outdir/$CN.pem => $outdir/$CN.p12)\n");
`openssl pkcs12 -export -inkey $outdir/$CN.key -in $outdir/$CN.pem -out $outdir/$CN.p12 -password pass:changeme`;
&notice("Converting pkcs12 keystore to JKS keystore ($outdir/$CN.p12 => $outdir/$CN.jks)\n");
`keytool -importkeystore -srcstorepass changeme -srckeystore $outdir/$CN.p12 -srcstoretype pkcs12  -destkeystore $outdir/$CN.jks -deststoretype jks -deststorepass changeme`;
&notice("Done! Please check " . "$outdir/$CN.p12" . ", " . "$outdir/$CN.jks" 
  . ", " . "$outdir/$CN.key" . ", " . "$outdir/$CN.csr" . ", " . "$outdir/$CN.pem" . "!\n");


sub prompt($) {
   print shift;
}

sub notice($) {
  prompt("[Notice] >>> ");
  print shift;
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
