const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DAO", () => {
  let DAOTokenContract;
  let PersisERC20Contract;
  let TimeLockContract;
  let MasterDAOContract;
  let MasterDAOStorageContract;
  let AgeContract;

  let TX;

  let encodeFunctionCall1;
  let proposalDesc;
  let proposalID;

  let owner;
  let addr1;

  beforeEach(async () => {
    [owner, addr1] = await ethers.getSigners();

    const Age = await ethers.getContractFactory("Age");
    AgeContract = await Age.deploy();
    await AgeContract.deployed();

    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN GOV TOKEN
    const DAOToken = await ethers.getContractFactory("DAOToken");
    DAOTokenContract = await DAOToken.deploy(ethers.utils.parseEther("1000"));

    await DAOTokenContract.deployed();
    await DAOTokenContract.transfer(
      addr1.address,
      ethers.utils.parseEther("1000")
    );
    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY EXAMPLE ERC20 TOKEN
    const PersisERC20 = await ethers.getContractFactory("Persis");
    PersisERC20Contract = await PersisERC20.deploy();
    await PersisERC20Contract.deployed();

    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN TIMELOCK
    const TimeLock = await ethers.getContractFactory("TimeLock");
    TimeLockContract = await TimeLock.deploy(3600, [], []);
    await TimeLockContract.deployed();

    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN MasterDAOStorageContract
    const MasterDAOStorage = await ethers.getContractFactory(
      "MasterDAOStorage"
    );
    MasterDAOStorageContract = await MasterDAOStorage.deploy();
    await MasterDAOStorageContract.deployed();

    await MasterDAOStorageContract.setAddress(
      DAOTokenContract.address,
      TimeLockContract.address
    );

    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MASTER DAO

    const MasterDAO = await ethers.getContractFactory("MasterDAO");
    MasterDAOContract = await MasterDAO.deploy();
    await MasterDAOContract.deployed();

    await MasterDAOContract.setAddress(
      DAOTokenContract.address,
      MasterDAOStorageContract.address
    );

    TX = await DAOTokenContract.transferOwnership(MasterDAOContract.address);
    await TX.wait(1);
  });

  describe("Create New GOV Contract", () => {
    beforeEach(async () => {
      TX = await MasterDAOContract.createNewDAOContract(
        PersisERC20Contract.address,
        1,
        1
      );
      await TX.wait(1);
    });
    it("it should create new GOV contract and increase ID", async () => {
      const totalGOVContracts =
        await MasterDAOContract.getDAOContractIDTracker();
      expect(totalGOVContracts).equal(1);
    });

    it("check details of created new GOV contract by erc20 address", async () => {
      const createdGOVContract =
        await MasterDAOContract.getDAOContractDetailsByAddress(
          PersisERC20Contract.address
        );

      expect(createdGOVContract[0]).to.eql(owner.address);
      expect(createdGOVContract[1]).to.eql("PERSIS");
      expect(createdGOVContract[2].toString()).to.eql("1");
      expect(createdGOVContract[3].length).to.eql(0);
    });

    it("check details of created new GOV contract by erc20 name", async () => {
      const createdGOVContract =
        await MasterDAOContract.getDAOContractDetailsByName("PERSIS");

      expect(createdGOVContract[0]).to.eql(owner.address);
      expect(createdGOVContract[1]).to.eql("PERSIS");
      expect(createdGOVContract[2].toString()).to.eql("1");
      expect(createdGOVContract[3].length).to.eql(0);
    });

    it("check details of created new GOV contract by creator/owner", async () => {
      const createdGOVContract =
        await MasterDAOContract.getDAOContractDetailsByCreator();

      expect(createdGOVContract[0]).to.eql(owner.address);
      expect(createdGOVContract[1]).to.eql("PERSIS");
      expect(createdGOVContract[2].toString()).to.eql("1");
      expect(createdGOVContract[3].length).to.eql(0);
    });
  });

  describe("Create New Proposal", () => {
    beforeEach(async () => {
      TX = await MasterDAOContract.createNewDAOContract(
        PersisERC20Contract.address,
        1,
        1
      );
      await TX.wait(1);

      encodeFunctionCall1 = AgeContract.interface.encodeFunctionData("setAge", [
        50,
      ]);
      proposalDesc = "change age value from 0 to 50";

      TX = await MasterDAOContract.createProposal(
        PersisERC20Contract.address,
        [AgeContract.address],
        [0],
        [encodeFunctionCall1],
        proposalDesc
      );
      await TX.wait(1);
    });
    it("When we get GOC contract details with erc20 address , contract should own one proposal", async () => {
      const createdGOVContract =
        await MasterDAOContract.getDAOContractDetailsByAddress(
          PersisERC20Contract.address
        );

      expect(createdGOVContract[0]).to.eql(owner.address);
      expect(createdGOVContract[1]).to.eql("PERSIS");
      expect(createdGOVContract[2].toString()).to.eql("1");
      // *
      expect(createdGOVContract[3].length).to.eql(1);
    });

    // it("lets check new created proposal details for proposal #1", async () => {
    //   // user has voted for proposal #1 ?
    //   const userVoted = await MasterDAOContract.userHasVoted(1);
    //   expect(userVoted).to.eql(false);

    //   // get proposal state
    //   const proposalState = await MasterDAOContract.getProposalState(1);
    //   expect(proposalState.toString()).to.eql("0");

    //   // get proposal result
    //   const proposalResult = await MasterDAOContract.getProposalResults(1);
    //   expect(proposalResult[0].toString()).to.eql("0");
    // });
  });
});
