/**
 * This file acts as a way of bootstrapping certificate chains with root ca, intermediate ca, and leaf certs.
 */

// The first argument should be the configuration file path.
// It is either a json or yaml file.
// The configuration file should contain the following keys:
// root_ca: A list of root ca objects.
// intermediate_ca: A list of intermediate ca objects.
// leaf_certs: A list of leaf certificate objects.
// root_ca should contain the following keys:
// name: The name of the root ca.
// password: The password of the root ca, minimum length is 8 characters
// pfx_password: The password of the root ca pfx file. Minimum length is 8 characters.
// should_insert_into_trusted_store: A boolean value indicating whether the root ca should be inserted into the trusted store.
// generate_dhparam: A boolean value indicating whether the root ca should generate a dhparam file.
// has_extension_file: A boolean value indicating whether the root ca should have an extension file.
// config: An object containing information on the config file, will be written to the config file.
// intermediate_ca should contain the following keys:
// is_last_chain_root_ca: A boolean value indicating whether the intermediate ca is the last chain root ca.
// ca_chain_name: The name of the the last certificate in the chain.
// ca_chain_password: The password of the last certificate in the intermediate ca chain. Minimum length is 8 characters.
// name: The name of the intermediate ca.
// password: The password of the intermediate ca, minimum length is 8 characters.
// pfx_password: The password of the intermediate ca pfx file. Minimum length is 8 characters.
// should_insert_into_trusted_store: A boolean value indicating whether the intermediate ca should be inserted into the trusted store.
// generate_dhparam: A boolean value indicating whether the intermediate ca should generate a dhparam file.
// keep_certificate_request_file: A boolean value indicating whether the intermediate ca should keep the certificate request file.
// config: An object containing information on the config file, will be written to the config file.
// leaf_certs should contain the following keys:
// is_ca_root_ca: A boolean value indicating whether the CA is a root CA.
// ca_name: The name of the CA.
// ca_password: The password of the CA. Minimum length is 8 characters.
// name: The name of the leaf certificate.
// password: The password of the leaf certificate, minimum length is 8 characters.
// pfx_password: The password of the leaf certificate pfx file. Minimum length is 8 characters.
// generate_dhparam: A boolean value indicating whether the leaf certificate should generate a dhparam file.
// keep_certificate_request_file: A boolean value indicating whether the leaf certificate should keep the certificate request file. (.csr)
// config: An object containing information on the config file, will be written to the config file.

const fs = require("fs");
const yaml = require("js-yaml");
const path = require("path");



// check if bin folder exists
if (!fs.existsSync("./bin")) {
  console.log("Creating bin folder");
  fs.mkdirSync("./bin");
}

const configFilePath = process.argv[2];

if (!configFilePath) {
  console.error("Please provide a configuration file path.");
  process.exit(1);
}

function determineIfReference(cert) {
  // if $ref is specified, then try and load the certificate info from the path it gives.

  if (cert.$ref) {
    const ref = cert.$ref;

    // Determine if the ref is relative to the config file or is an absolute path.
    if (ref.startsWith("/")) {
      console.log(`Loading certificate config from absolute path: ${ref}`);
      // Absolute path.
      const absolutePath = path.resolve(ref);
      const absolutePathExists = fs.existsSync(absolutePath);
      if (!absolutePathExists) {
        console.error(
          `The certificate configuration file is referencing a certificate that does not exist. The absolute path is ${absolutePath}.`
        );
        process.exit(1);
      }
      // determine if the file is a json file or a yaml file.
      const absolutePathExtension = path.extname(absolutePath);
      if (absolutePathExtension === ".json") {
        console.log(`Loading json certificate config from absolute path: ${absolutePath}`);
        // json file.
        const absolutePathJson = fs.readFileSync(absolutePath, {
          encoding: "utf8",
        });
        const absolutePathJsonParsed = JSON.parse(absolutePathJson);
        cert = absolutePathJsonParsed;
      } else if (
        absolutePathExtension === ".yaml" ||
        absolutePathExtension === ".yml"
      ) {
        console.log(`Loading yaml certificate config from absolute path: ${absolutePath}`);
        // yaml file.
        const absolutePathYaml = fs.readFileSync(absolutePath, {
          encoding: "utf8",
        });
        const absolutePathYamlParsed = yaml.load(absolutePathYaml);
        cert = absolutePathYamlParsed;
      } else {
        console.error(
          `The certificate configuration file is referencing a certificate that is not a json or yaml file. The absolute path is ${absolutePath}.`
        );
        process.exit(1);
      }
    } else {
      console.log(`Loading certificate config from relative path: ${ref}`);
      // Relative path.
      // resolve the path absolute path of the config file, remove the filename, and append the ref.
      const resolvedConfigFilePath = path.resolve(configFilePath);
      const configFilePathDir = path.dirname(resolvedConfigFilePath);
      const absolutePath = path.resolve(configFilePathDir, ref);
      const absolutePathExists = fs.existsSync(absolutePath);

      console.log(`The absolute path is ${absolutePath}`);

      if (!absolutePathExists) {
        console.error(
          `The certificate configuration file is referencing a certificate that does not exist. The absolute path is ${absolutePath}.`
        );
        process.exit(1);
      }
      // determine if the file is a json file or a yaml file.
      const absolutePathExtension = path.extname(absolutePath);
      if (absolutePathExtension === ".json") {
        console.log(`Loading json certificate config from absolute path: ${absolutePath}`);
        // json file.
        const absolutePathJson = fs.readFileSync(absolutePath, {
          encoding: "utf8",
        });
        const absolutePathJsonParsed = JSON.parse(absolutePathJson);
        cert = absolutePathJsonParsed;
      } else if (
        absolutePathExtension === ".yaml" ||
        absolutePathExtension === ".yml"
      ) {
        console.log(`Loading yaml certificate config from absolute path: ${absolutePath}`);
        // yaml file.
        const absolutePathYaml = fs.readFileSync(absolutePath, {
          encoding: "utf8",
        });
        const absolutePathYamlParsed = yaml.load(absolutePathYaml);
        cert = absolutePathYamlParsed;
      } else {
        console.error(
          `The certificate configuration file is referencing a certificate that is not a json or yaml file. The absolute path is ${absolutePath}.`
        );
        process.exit(1);
      }
    }
  }
  return cert;
}

// Check if the configuration file exists.
if (!fs.existsSync(configFilePath)) {
  console.error("The configuration file does not exist.");
  process.exit(1);
}

function getDefaultConfig(config) {
  // In the format of an openssl config file.
  var configFile = `[req]
distinguished_name = issued_to_name
req_extensions = config_extensions
prompt = no

[issued_to_name]
`;

  if (config.country) {
    const country = config.country.toUpperCase();
    if (country.length !== 2) {
      console.error("Country must be a two character string.");
      process.exit(1);
    }

    configFile += `countryName = ${config.country}\n`;
  }

  if (config.state) {
    configFile += `stateOrProvinceName = ${config.state}\n`;
  }

  if (config.locality) {
    configFile += `localityName = ${config.locality}\n`;
  }

  if (config.organization) {
    configFile += `organizationName = ${config.organization}\n`;
  }

  if (config.organizational_unit) {
    configFile += `organizationalUnitName = ${config.organizational_unit}\n`;
  }

  if (!config.common_name) {
    console.error("Common name is required.");
    process.exit(1);
  }

  configFile += `commonName = ${config.common_name}\n`;

  if (config.email) {
    configFile += `emailAddress = ${config.email}\n`;
  }

  return (configFile += "\n[config_extensions]\n");
}

function getLeafConfig(config) {
  // In the format of an openssl config file.
  var configFile = getDefaultConfig(config);

  if (config.key_usage && config.key_usage.length > 0) {
    if (config.critical_key_usage) {
      configFile += `keyUsage = critical, ${config.key_usage}\n`;
    } else {
      configFile += `keyUsage = ${config.key_usage.join(",")}\n`;
    }
  } else {
    if (config.critical_key_usage) {
      configFile += `keyUsage = critical, digitalSignature, keyEncipherment\n`;
    } else {
      configFile += `keyUsage = digitalSignature, keyEncipherment\n`;
    }
  }

  if (config.extended_key_usage && config.extended_key_usage.length > 0) {
    if (config.critical_extended_key_usage) {
      configFile += `extendedKeyUsage = critical, ${config.extended_key_usage.join(
        ","
      )}\n`;
    } else {
      configFile += `extendedKeyUsage = ${config.extended_key_usage.join(
        ","
      )}\n`;
    }
  } else {
    if (config.critical_extended_key_usage) {
      configFile += `extendedKeyUsage = critical, serverAuth, clientAuth\n`;
    } else {
      configFile += `extendedKeyUsage = serverAuth, clientAuth\n`;
    }
  }

  if (config.basic_constraints && config.basic_constraints.length > 0) {
    // check if basic constraints is trying to force CA
    if (config.basic_constraints.includes("CA:TRUE")) {
      console.error("Basic constraints cannot force CA.");
      process.exit(1);
    }

    if (config.critical_basic_constraints) {
      configFile += `basicConstraints = critical, CA:FALSE, ${config.basic_constraints.join(
        ","
      )}\n`;
    } else {
      configFile += `basicConstraints = CA:FALSE, ${config.basic_constraints.join(
        ","
      )}\n`;
    }
  } else {
    if (config.critical_basic_constraints) {
      configFile += `basicConstraints = critical, CA:FALSE\n`;
    } else {
      configFile += `basicConstraints = CA:FALSE\n`;
    }
  }

  if (config.policies && config.policies.length > 0) {
    if (config.critical_policies) {
      configFile += `certificatePolicies = critical, ${config.policies.join(
        ","
      )}\n`;
    } else {
      configFile += `certificatePolicies = ${config.policies.join(",")}\n`;
    }
  }

  if (config.subject_alternative_name) {
    const hasDnsNames =
      config.subject_alternative_name.dns_names &&
      config.subject_alternative_name.dns_names.length > 0;
    const hasIpAddresses =
      config.subject_alternative_name.ip_addresses &&
      config.subject_alternative_name.ip_addresses.length > 0;
    // only add subject alternative name if there are dns names or ip addresses
    if (hasDnsNames || hasIpAddresses) {
      if (config.critical_subject_alternative_name) {
        configFile +=
          "subjectAltName = critical, @subject_alt_names\n\n[subject_alt_names]\n";
      } else {
        configFile +=
          "subjectAltName = @subject_alt_names\n\n[subject_alt_names]\n";
      }
      if (hasDnsNames) {
        // Append all DNS names like this: DNS.index = value\n
        configFile += config.subject_alternative_name.dns_names
          .map((dnsName, index) => `DNS.${index} = ${dnsName}`)
          .join("\n");

        configFile += "\n";
      }
      if (hasIpAddresses) {
        // Append all IP addresses like this: IP.index = value\n
        configFile += config.subject_alternative_name.ip_addresses
          .map((ipAddress, index) => `IP.${index} = ${ipAddress}`)
          .join("\n");
      }
    }
  }

  return configFile;
}

function getCaConfig(config) {
  // In the format of an openssl config file.
  var configFile = getDefaultConfig(config);

  if (config.key_usage && config.key_usage.length > 0) {
    if (config.critical_key_usage) {
      configFile += `keyUsage = critical, ${config.key_usage.join(",")}\n`;
    } else {
      configFile += `keyUsage = ${config.key_usage.join(",")}\n`;
    }
  } else {
    if (config.critical_key_usage) {
      configFile += `keyUsage = critical, keyCertSign, cRLSign\n`;
    } else {
      configFile += `keyUsage = keyCertSign, cRLSign\n`;
    }
  }

  if (config.path_length) {
    if (config.path_length < 0) {
      console.error("Path length must be greater than or equal to 0.");
      process.exit(1);
    }
    if (config.critical_basic_constraints) {
      configFile += `basicConstraints = critical, CA:TRUE, pathlen:${config.path_length}\n`;
    } else {
      configFile += `basicConstraints = CA:TRUE, pathlen:${config.path_length}\n`;
    }
  } else {
    if (config.critical_basic_constraints) {
      configFile += `basicConstraints = critical, CA:TRUE\n`;
    } else {
      configFile += `basicConstraints = CA:TRUE\n`;
    }
  }

  if (config.extended_key_usage && config.extended_key_usage.length > 0) {
    if (config.critical_extended_key_usage) {
      configFile += `extendedKeyUsage = critical, ${config.extended_key_usage.join(
        ","
      )}\n`;
    } else {
      configFile += `extendedKeyUsage = ${config.extended_key_usage.join(
        ","
      )}\n`;
    }
  }

  if (config.policies && config.policies.length > 0) {
    if (config.critical_policies) {
      configFile += `certificatePolicies = critical, ${config.policies.join(
        ","
      )}\n`;
    } else {
      configFile += `certificatePolicies = ${config.policies.join(",")}\n`;
    }
  }

  return configFile;
}

// Determine if the configuration file is a json or yaml file.
const configFileExtension = configFilePath.split(".").pop();
let config;

switch (configFileExtension) {
  case "json":
    console.log(`Reading configuration file ${configFilePath}`);
    config = JSON.parse(fs.readFileSync(configFilePath, "utf8"));
    break;
  case "yml":
  case "yaml":
    console.log(`Reading configuration file ${configFilePath}`);
    config = yaml.load(fs.readFileSync(configFilePath, "utf8"));
    break;
  default:
    console.error("The configuration file is not a json or yaml file.");
    process.exit(1);
}

// Check if generate-root-ca.sh exists.
if (!fs.existsSync("./generate-root-ca.sh")) {
  console.error("The generate-root-ca.sh script does not exist.");
  process.exit(1);
}

// Check if generate-intermediate-ca.sh exists.
if (!fs.existsSync("./generate-intermediate-ca.sh")) {
  console.error("The generate-intermediate-ca.sh script does not exist.");
  process.exit(1);
}

// Check if generate-certs-v2.sh exists.
if (!fs.existsSync("./generate-certs-v2.sh")) {
  console.error("The generate-certs-v2.sh script does not exist.");
  process.exit(1);
}

// require the module to call the script files synchronously.
const execSync = require("child_process").execSync;

// Simple function to call the script files synchronously and redirect the output to the console.
function callScript(scriptPath) {
  try {
    execSync(scriptPath, { stdio: "inherit" });
  } catch (error) {
    process.exit(1);
  }
}

const generated_root_ca_names = [];
const generated_intermediate_ca_names = [];

// Root ca section should be executed first.
if (config.root_ca) {
  console.log("Generating root CAs...");
  const rootCa = config.root_ca;

  rootCa.forEach((rootCa) => {
    if (generated_root_ca_names.includes(rootCa.name)) {
      return;
    }

    console.log(`Generating root CA ${rootCa.name}...`);

    rootCa = determineIfReference(rootCa);

    const rootCaName = rootCa.name;
    const rootCaPassword = rootCa.password;
    const rootCaPfxPassword = rootCa.pfx_password;
    const shouldInsertIntoTrustedStore =
      rootCa.should_insert_into_trusted_store === true ? "YES" : "NO";
    const skipDhparam = rootCa.generate_dhparam === false ? "YES" : "NO";
    const hasExtensionFile = rootCa.has_extension_file === true ? "YES" : "NO";

    // Check all the required keys are present.
    if (!rootCaName || !rootCaPassword || !rootCaPfxPassword) {
      console.error(
        "The root ca configuration file is missing one or more required keys."
      );
      process.exit(1);
    }

    // Check if the root ca password is at least 8 characters.
    if (rootCaPassword.length < 8) {
      console.error(
        "The root ca password is less than 8 characters. Please provide a password of at least 8 characters."
      );
      process.exit(1);
    }

    // Check if the root ca pfx password is at least 8 characters.
    if (rootCaPfxPassword.length < 8) {
      console.error(
        "The root ca pfx password is less than 8 characters. Please provide a password of at least 8 characters."
      );
      process.exit(1);
    }

    const rootCaConfigPath = `${__dirname}/bin/mfdlabs-root-ca-${rootCaName}.conf`;
    if (!fs.existsSync(rootCaConfigPath) || rootCa.overwrite_config === true) {
      const config = rootCa.config;
      if (!config) {
        console.error(
          "The root ca configuration file is missing the config key."
        );
        process.exit(1);
      }

      const rootCaConfigFile = getCaConfig(config);
      fs.writeFileSync(rootCaConfigPath, rootCaConfigFile, {
        encoding: "utf8",
      });
    }

    const command = `./generate-root-ca.sh ${rootCaName} ${rootCaPassword} ${rootCaPfxPassword} ${shouldInsertIntoTrustedStore} ${skipDhparam} ${hasExtensionFile}`;

    callScript(command);

    generated_root_ca_names.push(rootCaName);
  });
}

function generateIntermediateCa(intermediateCa) {
  if (generated_intermediate_ca_names.includes(intermediateCa.name)) {
    return;
  }

  console.log(`Generating intermediate CA ${intermediateCa.name}...`);

  intermediateCa = determineIfReference(intermediateCa);

  const isLastChainRootCa =
    intermediateCa.is_last_chain_root_ca === true ? "YES" : "NO";
  const caChainName = intermediateCa.ca_chain_name;
  const caChainPassword = intermediateCa.ca_chain_password;
  const name = intermediateCa.name;
  const password = intermediateCa.password;
  const pfxPassword = intermediateCa.pfx_password;
  const shouldInsertIntoTrustedStore =
    intermediateCa.should_insert_into_trusted_store === true ? "YES" : "NO";
  const skipDhparam = intermediateCa.generate_dhparam === false ? "YES" : "NO";
  const keepCertificateRequestFile =
    intermediateCa.keep_certificate_request_file === true ? "YES" : "NO";

  // Check all the required keys are present.
  if (!caChainName || !caChainPassword || !name || !password || !pfxPassword) {
    console.error(
      "The intermediate ca configuration file is missing one or more required keys."
    );
    process.exit(1);
  }

  // Check if the chain password is at least 8 characters.
  if (caChainPassword.length < 8) {
    console.error(
      "The ca chain password is less than 8 characters. Please provide a password of at least 8 characters."
    );
    process.exit(1);
  }

  // Check if the intermediate ca password is at least 8 characters.
  if (password.length < 8) {
    console.error(
      "The intermediate ca password is less than 8 characters. Please provide a password of at least 8 characters."
    );
    process.exit(1);
  }

  // Check if the intermediate ca pfx password is at least 8 characters.
  if (pfxPassword.length < 8) {
    console.error(
      "The intermediate ca pfx password is less than 8 characters. Please provide a password of at least 8 characters."
    );
    process.exit(1);
  }

  // Check if there is an intermediate ca in the list that matches the ca chain name of this intermediate ca.
  // If there is, then generate that intermediate ca first.
  // if we the last ca chain was a root ca, then we don't need to generate the intermediate ca, because by default root ca is generated first if they are specified in the config file.
  if (
    config.intermediate_ca &&
    isLastChainRootCa === "NO" &&
    !generated_intermediate_ca_names.includes(caChainName)
  ) {
    config.intermediate_ca.forEach((intermediateCa) => {
      if (intermediateCa.name === caChainName) {
        // Found a certificate that matches the ca chain name.
        // Generate the intermediate ca first.
        generateIntermediateCa(intermediateCa);
        return;
      }
    });
  }

  if (
    !generated_root_ca_names.includes(caChainName) &&
    !generated_intermediate_ca_names.includes(caChainName)
  ) {
    console.warn(
      `The intermediate ca configuration file is referencing a ca chain that was not generated. The ca chain name is ${caChainName}. It may exist on the system, but it was not generated by this script.`
    );
  }

  const caConfigPath = `${__dirname}/bin/mfdlabs-ca-${name}.conf`;
  if (
    !fs.existsSync(caConfigPath) ||
    intermediateCa.overwrite_config === true
  ) {
    const config = intermediateCa.config;
    if (!config) {
      console.error("The ca configuration file is missing the config key.");
      process.exit(1);
    }

    const caConfigFile = getCaConfig(config);
    fs.writeFileSync(caConfigPath, caConfigFile, {
      encoding: "utf8",
    });
  }

  const command = `./generate-intermediate-ca.sh ${isLastChainRootCa} ${caChainName} ${caChainPassword} ${name} ${password} ${pfxPassword} ${shouldInsertIntoTrustedStore} ${skipDhparam} ${keepCertificateRequestFile}`;

  callScript(command);

  generated_intermediate_ca_names.push(name);
}

// If we are generating intermediate ca, and we are generating with a ca chain that was not cached here, then warn the user.
if (config.intermediate_ca) {
  console.log("Generating intermediate cas...");
  const intermediateCa = config.intermediate_ca;

  intermediateCa.forEach((intermediateCa) => {
    generateIntermediateCa(intermediateCa);
  });
}

function generateLeafCertificate(leafCertificate) {
  console.log(`Generating leaf certificate ${leafCertificate.name}...`);
  leafCertificate = determineIfReference(leafCertificate);

  const isLastChainRootCa =
    leafCertificate.is_ca_root_ca === true ? "YES" : "NO";
  const caChainName = leafCertificate.ca_name;
  const caChainPassword = leafCertificate.ca_password;
  const name = leafCertificate.name;
  const password = leafCertificate.password;
  const pfxPassword = leafCertificate.pfx_password;
  const skipDhparam = leafCertificate.generate_dhparam === false ? "YES" : "NO";
  const keepCertificateRequestFile =
    leafCertificate.keep_certificate_request_file === true ? "YES" : "NO";

  // Check all the required keys are present.
  if (!caChainName || !caChainPassword || !name || !password || !pfxPassword) {
    console.error(
      "The leaf certificate configuration file is missing one or more required keys."
    );
    process.exit(1);
  }

  // Check if the chain password is at least 8 characters.
  if (caChainPassword.length < 8) {
    console.error(
      "The ca chain password is less than 8 characters. Please provide a password of at least 8 characters."
    );
    process.exit(1);
  }

  // Check if the leaf certificate password is at least 8 characters.
  if (password.length < 8) {
    console.error(
      "The leaf certificate password is less than 8 characters. Please provide a password of at least 8 characters."
    );
    process.exit(1);
  }

  // Check if the leaf certificate pfx password is at least 8 characters.
  if (pfxPassword.length < 8) {
    console.error(
      "The leaf certificate pfx password is less than 8 characters. Please provide a password of at least 8 characters."
    );
    process.exit(1);
  }

  // Check if there is an intermediate ca in the list that matches the ca chain name of this leaf certificate.
  // If there is, then generate that intermediate ca first.
  // if we the last ca chain was a root ca, then we don't need to generate the leaf certificate, because by default root ca is generated first if they are specified in the config file.
  if (
    config.intermediate_ca &&
    isLastChainRootCa === "NO" &&
    !generated_intermediate_ca_names.includes(caChainName)
  ) {
    config.intermediate_ca.forEach((intermediateCa) => {
      if (intermediateCa.name === caChainName) {
        // Found a certificate that matches the ca chain name.
        // Generate the intermediate ca first.
        generateIntermediateCa(intermediateCa);
        return;
      }
    });
  }

  if (
    !generated_root_ca_names.includes(caChainName) &&
    !generated_intermediate_ca_names.includes(caChainName)
  ) {
    console.warn(
      `The leaf certificate configuration file is referencing a ca chain that was not generated. The ca chain name is ${caChainName}. It may exist on the system, but it was not generated by this script.`
    );
  }

  const leafConfigPath = `${__dirname}/bin/mfdlabs-all-authority-${name}.conf`;
  if (
    !fs.existsSync(leafConfigPath) ||
    leafCertificate.overwrite_config === true
  ) {
    const config = leafCertificate.config;
    if (!config) {
      console.error(
        "The leaf certificate configuration file is missing the config key."
      );
      process.exit(1);
    }

    const leafCertConfigFile = getLeafConfig(config);
    fs.writeFileSync(leafConfigPath, leafCertConfigFile, {
      encoding: "utf8",
    });
  }

  const command = `./generate-certs-v2.sh ${isLastChainRootCa} ${caChainName} ${caChainPassword} ${name} ${password} ${pfxPassword} ${skipDhparam} ${keepCertificateRequestFile}`;

  callScript(command);
}

if (config.leaf_certificate) {
  console.log("Generating leaf certificates...");
  const leafCertificate = config.leaf_certificate;

  leafCertificate.forEach((leafCertificate) => {
    generateLeafCertificate(leafCertificate);
  });
}
