// const { expect } = require("chai");
const { ethers } = require("hardhat");

/*

    const DeleteTXOwner = await DAOTokenContract.delegate(owner.address);
    await DeleteTXOwner.wait(1);
    console.log(
      "OwnerPower : ",
      await DAOTokenContract.numCheckpoints(owner.address)
    );

    with this code we delegate to user and user can vote ! but if we delegte before and after create proposal , results are different.
    test it and move this code before and after and see results.
*/

describe("DAO", function () {
  let encodeFunctionCall1;
  let proposalDesc;
  let TX;
  let proposalID;

  it("Start", async function () {
    const [owner, addr1] = await ethers.getSigners();
    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN CONTRACT
    const Age = await ethers.getContractFactory("Age");
    const AgeContract = await Age.deploy();
    await AgeContract.deployed();
    // console.log("AgeContract deployed to:", AgeContract.address);
    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN GOV TOKEN
    const DAOToken = await ethers.getContractFactory("DAOToken");
    const DAOTokenContract = await DAOToken.deploy(
      ethers.utils.parseEther("1000")
    );
    await DAOTokenContract.deployed();
    await DAOTokenContract.transfer(
      addr1.address,
      ethers.utils.parseEther("1000")
    );
    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN GOV TOKEN
    const PersisERC20 = await ethers.getContractFactory("Persis");
    const PersisERC20Contract = await PersisERC20.deploy();
    await PersisERC20Contract.deployed();
    // console.log("PersisERC20Contract deployed to:", PersisERC20Contract.address);
    // await PersisERC20Contract.transfer(
    //   addr1.address,
    //   ethers.utils.parseEther("1000")
    // );
    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN TIMELOCK TOKEN
    const TimeLock = await ethers.getContractFactory("TimeLock");
    const TimeLockContract = await TimeLock.deploy(3600, [], []);
    await TimeLockContract.deployed();
    // console.log("TimeLockContract deployed to:", TimeLockContract.address);
    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN GOV CONTRACT
    const GovernanceContract = await ethers.getContractFactory(
      "GovernanceContract"
    );
    const GovernanceContractC = await GovernanceContract.deploy(
      DAOTokenContract.address,
      TimeLockContract.address
    );
    await GovernanceContractC.deployed();
    // console.log(
    //   "GovernanceContractC deployed to:",
    //   GovernanceContractC.address
    // );
    /// /////////////////////////////////////////////////////////////////////////////// DEPLOY MAIN GOV CONTRACT
    const MasterDAO = await ethers.getContractFactory("MasterDAO");
    const MasterDAOContract = await MasterDAO.deploy();
    await MasterDAOContract.deployed();
    // console.log("MasterDAOContract deployed to:", MasterDAOContract.address);
    await MasterDAOContract.setAddress(
      DAOTokenContract.address,
      TimeLockContract.address
    );
    TX = await DAOTokenContract.transferOwnership(MasterDAOContract.address);
    await TX.wait(1);
    /// /////////////////////////////////////////////////////////////////////////////// CREATE NEW DAO CONTRACT
    await MasterDAOContract.createNewDAOContract(PersisERC20Contract.address);
    /// /////////////////////////////////////////////////////////////////////////////// DELEGATE
    TX = await DAOTokenContract.connect(addr1).approve(
      MasterDAOContract.address,
      ethers.utils.parseEther("1")
    );
    await TX.wait(1);
    TX = await MasterDAOContract.connect(addr1).addPowerToVote();
    await TX.wait(1);
    console.log(
      "User vote weight : ",
      (await DAOTokenContract.getVotes(addr1.address)).toString()
    );
    /// /////////////////////////////////////////////////////////////////////////////// CREATE PROPOSE
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
    for (let i = 0; i < 2; i++) {
      ethers.provider.send("evm_mine");
    }
    proposalID = await MasterDAOContract.ProposalIDToProposalHashID(1, 0);
    console.log("we created proposal with hashed id ", proposalID.toString());
    /// /////////////////////////////////////////////////////////////////////////////// VOTE !
    TX = await MasterDAOContract.connect(addr1).voteForProposal(1, 1, "I want");
    await TX.wait(1);
    for (let i = 0; i < 102; i++) {
      ethers.provider.send("evm_mine");
    }
    console.log(
      "user voted for proposal by 1 as support / for , and after proposal deadline , state is Ok :)",
      (await MasterDAOContract.getProposalState(1)).toString()
    );
    const answer = await MasterDAOContract.getProposalResults(1);
    console.log(answer.toString());
  });
});
