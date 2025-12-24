const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Authorization-Governed Vault System", function () {
  let vault, authManager, owner, recipient;

  beforeEach(async function () {
    [owner, recipient] = await ethers.getSigners();

    const AuthMgr = await ethers.getContractFactory("AuthorizationManager");
    authManager = await AuthMgr.deploy();
    await authManager.deployed();

    const Vault = await ethers.getContractFactory("SecureVault");
    vault = await Vault.deploy();
    await vault.deployed();
    await vault.initialize(authManager.address);
  });

  describe("Deployment", function () {
    it("Should initialize vault correctly", async function () {
      expect(await vault.isInitialized()).to.equal(true);
      expect(await vault.getAuthorizationManager()).to.equal(authManager.address);
    });

    it("Should prevent re-initialization", async function () {
      await expect(
        vault.initialize(authManager.address)
      ).to.be.revertedWith("Vault already initialized");
    });
  });

  describe("Deposits", function () {
    it("Should accept deposits", async function () {
      const amount = ethers.utils.parseEther("1.0");
      await owner.sendTransaction({to: vault.address, value: amount});
      expect(await vault.getBalance()).to.equal(amount);
    });
  });

  describe("Withdrawals", function () {
    beforeEach(async function () {
      const depositAmount = ethers.utils.parseEther("10.0");
      await owner.sendTransaction({to: vault.address, value: depositAmount});
    });

    it("Should execute withdrawal with valid authorization", async function () {
      const withdrawAmount = ethers.utils.parseEther("1.0");
      const chainId = (await ethers.provider.getNetwork()).chainId;
      const authId = ethers.utils.solidityKeccak256(
        ["address", "uint256", "address", "uint256"],
        [vault.address, chainId, recipient.address, withdrawAmount]
      );
      await vault.withdraw(recipient.address, withdrawAmount, authId);
      expect(await vault.getBalance()).to.equal(ethers.utils.parseEther("9.0"));
    });

    it("Should prevent reuse of authorization", async function () {
      const withdrawAmount = ethers.utils.parseEther("1.0");
      const chainId = (await ethers.provider.getNetwork()).chainId;
      const authId = ethers.utils.solidityKeccak256(
        ["address", "uint256", "address", "uint256"],
        [vault.address, chainId, recipient.address, withdrawAmount]
      );
      await vault.withdraw(recipient.address, withdrawAmount, authId);
      await expect(
        vault.withdraw(recipient.address, withdrawAmount, authId)
      ).to.be.reverted;
    });
  });

  describe("Authorization Tracking", function () {
    it("Should track consumed authorizations", async function () {
      const withdrawAmount = ethers.utils.parseEther("1.0");
      const chainId = (await ethers.provider.getNetwork()).chainId;
      const authId = ethers.utils.solidityKeccak256(
        ["address", "uint256", "address", "uint256"],
        [vault.address, chainId, recipient.address, withdrawAmount]
      );
      expect(await authManager.isAuthorizationConsumed(authId)).to.equal(false);
      await owner.sendTransaction({to: vault.address, value: ethers.utils.parseEther("10.0")});
      await vault.withdraw(recipient.address, withdrawAmount, authId);
      expect(await authManager.isAuthorizationConsumed(authId)).to.equal(true);
    });
  });
});
