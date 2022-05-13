# OpenSSL based CA without hassle. 

You can create CA with a single command.
You can issue cert with a single command.

# Customizing password
By default, the program will generate CA key, CA cert, and CA truststore.
If you want to customize the CA truststore password, please edit 'PASSWORD' file (if not exist, create one).

By default, this program will generate keystore for certs too. 
If you want to customize the keystore password, please edit 'PASSWORD' file (if not exist, create one).
# Creating CA
```
$ perl 01-gen-ca.pl 
```
Sample Output
```
$ perl 01-gen-ca.pl 
Please enter Country Name (2 letter code) (C):SG
Please enter State or Province Name (full anme) (ST):Singapore
Please enter Locality Name (eg, city) (L):Singapore
Please enter Organization Name (eg, company) (O):ABC Company
Please enter Organizational Unit Name (eg, section) (OU):IT Department
Please enter CA Name (eg, EnterpriseCA01) (CN):EnterpriseCA01
Please enter Email Address (EMAIL):admin@abc.com
Generating RSA private key, 4096 bit long modulus
........................................................................................................................++
.......++
e is 65537 (0x10001)
```
That's it! CA.pem (CA cert), CA.key (CA key) are generated, as well as openssl-ca.conf.
The keys are not protected for simplicity.

There is also truststore.p12 and truststore.jks, as well as a password file truststore.password are generated.

# Creating cert
```
$ perl 02-gen-cert.pl <commonName> <fqdn1> ... <fqdnN> <ipAddress1> ... <ipAddressN>
```
Cert, Key, CSR, JKS keystore, JKS TrustStore, PKCS keystore will be all generated.

## Passwords for keystores: changeme

Sample Output:
```
$ perl 02-gen-cert.pl commonCert host1.abc.com host2.abc.com host3.abc.com 127.0.0.1 172.20.1.1 172.20.1.2 localhost
Create certs with following settings:
Hosts: commonCert host1.abc.com host2.abc.com host3.abc.com localhost
IPs: 127.0.0.1 172.20.1.1 172.20.1.2
CN=commonCert
Loading cert config from SETTINGS. If you want to customize, please edit CERT_SETTINGS file
[Notice] >>> Generating key pair and CSR ( => issued/commonCert.key + issued/commonCert.csr)
Generating a 4096 bit RSA private key
.................................++
...............................................................++
writing new private key to 'issued/commonCert.key'
-----
[Notice] >>> Signing certificate (issued/commonCert.csr => issued/commonCert.pem)
Using configuration from openssl-ca.conf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
countryName           :PRINTABLE:'SG'
stateOrProvinceName   :ASN.1 12:'Singapore'
localityName          :ASN.1 12:'Singapore'
organizationName      :ASN.1 12:'ABC Company'
organizationalUnitName:ASN.1 12:'IT Department'
commonName            :ASN.1 12:'commonCert'
Certificate is to be certified until May  8 03:51:23 2042 GMT (7300 days)

Write out database with 1 new entries
Data Base Updated
[Notice] >>> Generating pkcs12 keystore (issued/commonCert.pem => issued/commonCert.p12)
[Notice] >>> Converting pkcs12 keystore to JKS keystore (issued/commonCert.p12 => issued/commonCert.jks)
Importing keystore issued/commonCert.p12 to issued/commonCert.jks...
Entry for alias 1 successfully imported.
Import command completed:  1 entries successfully imported, 0 entries failed or cancelled

Warning:
The JKS keystore uses a proprietary format. It is recommended to migrate to PKCS12 which is an industry standard format using "keytool -importkeystore -srckeystore issued/commonCert.jks -destkeystore issued/commonCert.jks -deststoretype pkcs12".
[Notice] >>> Done! Please check issued/commonCert.p12, issued/commonCert.jks, issued/commonCert.key, issued/commonCert.csr, issued/commonCert.pem!
```
That's it! Everything (Country Code etc) follows CA. If you are not happy about it, create a CERT_SETTINGS file just like SETTINGS, and put your customized parameter in!

# Cleaning up (deletes everything)
```
$ perl 03-cleanup.pl
```

