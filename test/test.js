// const { expect } = require("chai");
const { ethers } = require("hardhat");

/*

    const DeleteTXOwner = await GOVTokenContract.delegate(owner.address);
    await DeleteTXOwner.wait(1);
    console.log(
      "OwnerPower : ",
      await GOVTokenContract.numCheckpoints(owner.address)
    );

    with this code we delegate to user and user can vote ! but if we delegte before and after create proposal , results are different.
    test it and move this code before and after and see results.
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

    /// /////////////////////////////////////////////////////////////////////////////// Test Mint Power Before
    // here we see user has power to vote for proposal or no ! 0 means no and 1 means yes
    console.log(
      "User Power Before Mint : ",
      await GOVTokenContract.numCheckpoints(addr1.address)
    );

    /// /////////////////////////////////////////////////////////////////////////////// add ERC20 TOken to GOV Token
    // here we add our test erc20 token to GOV token contract , address / rate and 0.01 ether as fee
    // rate means for every 30 erc20 tokens we mint 1 GOV token to msg.sender
    await GOVTokenContract.registerNewERC20(TestERC20Contract.address, 30, {
      value: ethers.utils.parseEther("0.01"),
    });

    /// /////////////////////////////////////////////////////////////////////////////// Mint power to addr1
    // address 1 transfer 30 erc20 token to GOV contract and GOV contract after
    // validation , mint 1 GOV token to msg.sender and add 1 vote power to msg.sedner
    const approveTX = await TestERC20Contract.connect(addr1).approve(
      GOVTokenContract.address,
      ethers.utils.parseEther("30")
    );
    await approveTX.wait(1);
    const mintTX = await GOVTokenContract.connect(addr1).mintPower(1);
    await mintTX.wait(1);

    /// /////////////////////////////////////////////////////////////////////////////// Test Mint Power After
    console.log(
      "User Power After Mint : ",
      await GOVTokenContract.numCheckpoints(addr1.address)
    );

    /// /////////////////////////////////////////////////////////////////////////////// Get token details
    console.log(
      (await GOVTokenContract.connect(addr1).getUserPower()).toString()
    );
  });
});
