const { ethers } = require("ethers");

async function main() {
  console.log("Starting contract deployment...");

  // Get signers
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // Deploy AuthorizationManager contract
  console.log("Deploying AuthorizationManager...");
  const AuthorizationManager = await hre.ethers.getContractFactory(
    "AuthorizationManager"
  );
  const authorizationManager = await AuthorizationManager.deploy();
  await authorizationManager.deployed();
  console.log("AuthorizationManager deployed at:", authorizationManager.address);

  // Deploy SecureVault contract
  console.log("Deploying SecureVault...");
  const SecureVault = await hre.ethers.getContractFactory("SecureVault");
  const vault = await SecureVault.deploy();
  await vault.deployed();
  console.log("SecureVault deployed at:", vault.address);

  // Initialize vault with authorization manager
  console.log("Initializing vault...");
  const initTx = await vault.initialize(authorizationManager.address);
  await initTx.wait();
  console.log("Vault initialized successfully");

  // Save addresses to file
  const fs = require("fs");
  const deploymentInfo = {
    authorizationManager: authorizationManager.address,
    vault: vault.address,
    deployer: deployer.address,
    network: hre.network.name,
    timestamp: new Date().toISOString()
  };
  fs.writeFileSync(
    "deployment.json",
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log("Deployment info saved to deployment.json");

  console.log("\n=== Deployment Complete ===");
  console.log("AuthorizationManager:", authorizationManager.address);
  console.log("SecureVault:", vault.address);
  console.log("=".repeat(40));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
