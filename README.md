<h1 align="center"><b>MFDLABS Certificate Generation for Root Certificate Authorities and Intermediate Certificates</b></h1>
<br />

# About

This tool can be used to sign MFDLABS grade certificates for your app sites.

# Content

**generate-certs-v2.sh**: A shell file to be ran on Linux to generate certs while giving it a root CA name.

Example:

```bash
# Change directory to the MFDLABS SSL Root Directory.
# See https://ssl-siging.change-log.mfdlabs.local:443/ui/change+id:134/info
# for more information on why the directory was changed.
$ cd /opt/mfdlabs/ssl/

# Call Generate-Certs-V2.SH
$ ./generate-certs-v2.sh ROOT_CA_NAME ROOT_CA_PASSWORD INTERMEDIATE_CERT_NAME INTERMEDIATE_CERT_PASSWORD INTERMEDIATE_CERT_PFX_PASSWORD (INSERT_ROOT_CA_INTO_TRUSTED_CERTS?2) (DO_NOT_GENERATE_DHPARAM?3)
# ROOT_CA_NAME: The name of the RootCA that you are going to use,
# please see https://ssl-signers.docs.mfdlabs.local/ui/docs/v1/root_ca_name_pattern.
# Note: It should be like with `mfdlabs-root-ca-$(ROOT_CA_NAME)'.
# ROOT_CA_PASSWORD: A password to use for the ROOT_CA,
# please refer to https://ssl-signers.development-patterns.mfdlabs.local/ui/ssl-patterns/passwords.
# Note: The password is 100% required, and if you are not giving it,
# please make sure it is for local SSL testing, and not a grid deployment.
# INTERMEDIATE_CERT_NAME: The name of the certificate to sign.
# INTERMEDIATE_CERT_PASSWORD: The password of the the certificate to sign,
# please refer to https://ssl-signers.development-patterns.mfdlabs.local/ui/ssl-patterns/passwords.
# Note: The password is 100% required, and if you are not giving it,
# please make sure it is for local SSL testing, and not a grid deployment.
# INTERMEDIATE_CERT_PFX_PASSWORD: The password for the certificate to sign's PFX,
# please refer to https://ssl-signers.development-patterns.mfdlabs.local/ui/ssl-patterns/passwords.
# Note: The password is 100% required, and if you are not giving it,
# please make sure it is for local SSL testing, and not a grid deployment.
# INSERT_ROOT_CA_INTO_TRUSTED_CERTS: If set, it will try to insert it into Linux's ROOT CAs.
# Note: ROOT IS REQUIRED WHEN INSERTING INTO ROOT CA STORE.
# DO_NOT_GENERATE_DHPARAM: Determines if the signer should generate DH Parameters.

# Change directory into the output folder (./bin)
$ cd bin
```

**generate-root-ca.sh**: A shell file to be ran on Linux to generate root certificate authorithies for intermediate certs.

Example:

```bash
# Change directory to the MFDLABS SSL Root Directory.
# See https://ssl-siging.change-log.mfdlabs.local:443/ui/change+id:134/info
# for more information on why the directory was changed.
$ cd /opt/mfdlabs/ssl/

# Call Generate-Certs-V2.SH
$ ./generate-root-ca.sh ROOT_CA_NAME ROOT_CA_PASSWORD ROOT_CA_PFX_PASSWORD (INSERT_ROOT_CA_INTO_TRUSTED_CERTS?2) (DO_NOT_GENERATE_DHPARAM?3)
# ROOT_CA_NAME: The name of the RootCA that you are going to use,
# please see https://ssl-signers.docs.mfdlabs.local/ui/docs/v1/root_ca_name_pattern.
# Note: It should be like with `mfdlabs-root-ca-$(ROOT_CA_NAME)'.
# ROOT_CA_PASSWORD: A password to use for the ROOT_CA,
# please refer to https://ssl-signers.development-patterns.mfdlabs.local/ui/ssl-patterns/passwords.
# Note: The password is 100% required, and if you are not giving it,
# please make sure it is for local SSL testing, and not a grid deployment.
# ROOT_CA_PFX_PASSWORD: The password for the root certificate's PFX,
# please refer to https://ssl-signers.development-patterns.mfdlabs.local/ui/ssl-patterns/passwords.
# Note: The password is 100% required, and if you are not giving it,
# please make sure it is for local SSL testing, and not a grid deployment.
# INSERT_ROOT_CA_INTO_TRUSTED_CERTS: If set, it will try to insert it into Linux's ROOT CAs.
# Note: ROOT IS REQUIRED WHEN INSERTING INTO ROOT CA STORE.
# DO_NOT_GENERATE_DHPARAM: Determines if the signer should generate DH Parameters.

# Change directory into the output folder (./bin)
$ cd bin
```

Please refer to the [example config](./mfdlabs-all-authorithy-example.conf) for a configuration example

# Credits

Nikita Petko
Alex Bkordan
Yaakov Zimlski
Alex Vonn
