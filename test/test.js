// const { expect } = require("chai");
const { ethers } = require("hardhat");

/*

*/

describe("DAO", function () {
  it("Start", async function () {
    const [owner, addr1, addr2, addr3] = await ethers.getSigners();

    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN GOV TOKEN
    const GOVToken = await ethers.getContractFactory("GOVToken");
    const GOVTokenContract = await GOVToken.deploy();
    await GOVTokenContract.deployed();
    console.log("GOVTokenContract deployed to:", GOVTokenContract.address);

    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY ERC20 Token
    const TestERC20 = await ethers.getContractFactory("Persis");
    const TestERC20Contract = await TestERC20.deploy();
    await TestERC20Contract.deployed();
    console.log("TestERC20Contract deployed to:", TestERC20Contract.address);

    await TestERC20Contract.transfer(
      addr1.address,
      ethers.utils.parseEther("100")
    );

    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN CONTRACT
    const Age = await ethers.getContractFactory("Age");
    const AgeContract = await Age.deploy();
    await AgeContract.deployed();
    console.log("AgeContract deployed to:", AgeContract.address);

    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN TIMELOCK TOKEN
    const TimeLock = await ethers.getContractFactory("TimeLock");
    const TimeLockContract = await TimeLock.deploy(3600, [], []);
    await TimeLockContract.deployed();
    console.log("TimeLockContract deployed to:", TimeLockContract.address);

    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN GOV CONTRACT
    const GovernanceContract = await ethers.getContractFactory(
      "GovernanceContract"
    );
    const GovernanceContractC = await GovernanceContract.deploy(
      GOVTokenContract.address,
      TimeLockContract.address
    );
    await GovernanceContractC.deployed();
    console.log(
      "GovernanceContractC deployed to:",
      GovernanceContractC.address
    );

    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MASTER GOV CONTRACT
    const GOVMaster = await ethers.getContractFactory("GOVMaster");
    const GOVMasterContract = await GOVMaster.deploy();
    await GOVMasterContract.deployed();
    console.log("GOVMasterContract deployed to:", GOVMasterContract.address);

    /// /////////////////////////////////////////////////////////////////////////////// TRANSFER ROLES
    const PROPOSER_ROLE = await TimeLockContract.PROPOSER_ROLE();
    const EXECUTOR_ROLE = await TimeLockContract.EXECUTOR_ROLE();
    const TIMELOCK_ADMIN_ROLE = await TimeLockContract.TIMELOCK_ADMIN_ROLE();

    //
    const PROPOSER_ROLETX = await TimeLockContract.grantRole(
      PROPOSER_ROLE,
      GovernanceContractC.address
    );
    await PROPOSER_ROLETX.wait(1);

    //
    const EXECUTOR_ROLETX = await TimeLockContract.grantRole(
      EXECUTOR_ROLE,
      "0x0000000000000000000000000000000000000000"
    );
    await EXECUTOR_ROLETX.wait(1);

    //
    const TIMELOCK_ADMIN_ROLETX = await TimeLockContract.grantRole(
      TIMELOCK_ADMIN_ROLE,
      owner.address
    );
    await TIMELOCK_ADMIN_ROLETX.wait(1);

    /// /////////////////////////////////////////////////////////////////////////////// Set Address

    const setAddressTX = await GOVMasterContract.setAddress(
      GovernanceContractC.address,
      TimeLockContract.address
    );

    await setAddressTX.wait(1);

    /// /////////////////////////////////////////////////////////////////////////////// create new gov contract

    const createNewGOVTX = await GOVMasterContract.createNewProposalContract(
      TestERC20Contract.address
    );
    await createNewGOVTX.wait(1);

    console.log(
      "New DAO Contract created : ",
      await GOVMasterContract.getDAOContractAddressOfERC20Token(
        TestERC20Contract.address
      )
    );

    /// /////////////////////////////////////////////////////////////////////////////// create new proposal

    const encodeFunctionCall = AgeContract.interface.encodeFunctionData(
      "setAge",
      [50]
    );
    const proposalDesc = "change age value from 0 to 50";

    const proposTX = await GOVMasterContract.createProposal(
      TestERC20Contract.address,
      [AgeContract.address],
      [0],
      [encodeFunctionCall],
      proposalDesc
    );
    await proposTX.wait(1);

    /// /////////////////////////////////////////////////////////////////////////////// check new proposal state #1

    const proposalDetails =
      await GOVMasterContract.getAllProposalsOfERC20TokenAddress(
        TestERC20Contract.address
      );
    console.log(proposalDetails.toString());
  });
});
