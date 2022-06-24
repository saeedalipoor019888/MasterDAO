// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Utils/GovernanceContract.sol";
import "./Utils/DAOToken.sol";
import "./MasterDAOStorage.sol";

contract MasterDAO {
    address DAOTokenContract;
    MasterDAOStorage MasterDAOStorageContract;

    function setAddress(address _DAOTokenContract, address _MasterDAOStorage)
        external
    {
        DAOTokenContract = _DAOTokenContract;
        MasterDAOStorageContract = MasterDAOStorage(_MasterDAOStorage);
    }

    /// /////////////////////////////////////////////////////////////////////////////// DAO FUNCTIONS

    function createNewDAOContract(
        address _erc20TokenAddress,
        uint256 _votingDelay,
        uint256 _votingPeriod
    ) external returns (uint256) {
        require(ERC20DAOContractIsExist(_erc20TokenAddress) == false);
        address _creatorAddress = msg.sender;
        return
            MasterDAOStorageContract.createNewDAOContract(
                _creatorAddress,
                _erc20TokenAddress,
                _votingDelay,
                _votingPeriod
            );
    }

    // /// /////////////////////////////////////////////////////////////////////////////// PROPOSAL FUNCTIONS

    function createProposal(
        address _erc20TokenAddress,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (bool) {
        require(_erc20TokenAddress != address(0));

        address _GOVContractAddress;
        uint256 _GOVContractID;

        (, _GOVContractAddress, , _GOVContractID, ) = MasterDAOStorageContract
        .getDAOContractDetailsByAddress(_erc20TokenAddress);

        GovernanceContract _GovernanceContractInstance = GovernanceContract(
            payable(_GOVContractAddress)
        );

        uint256 _hashedProposalID = _GovernanceContractInstance.propose(
            targets,
            values,
            calldatas,
            description
        );

        MasterDAOStorageContract.createProposal(
            _GOVContractID,
            _hashedProposalID
        );

        return true;
    }

    function voteForProposal(
        uint256 _proposalID,
        uint8 _support,
        string calldata _reason
    ) external returns (bool) {
        uint256 _hashedProposalID;
        address _GOVContractAddress;

        (_hashedProposalID, _GOVContractAddress) = MasterDAOStorageContract
        .getHashedProposalID(_proposalID);

        GovernanceContract _GovernanceContractInstance = GovernanceContract(
            payable(_GOVContractAddress)
        );

        _GovernanceContractInstance.VoteToProposal(
            msg.sender,
            _hashedProposalID,
            _support,
            _reason
        );

        return true;
    }

    // /// /////////////////////////////////////////////////////////////////////////////// DAO TOKEN FUNCTIONS

    function addPowerToVote() external returns (bool) {
        return DAOToken(DAOTokenContract).addPower(msg.sender);
    }

    /// /////////////////////////////////////////////////////////////////////////////// GETTER FUNCTIONS

    function getDAOContractIDTracker() public view returns (uint256) {
        return MasterDAOStorageContract.getDAOContractIDTracker();
    }

    function getProposalState(uint256 _proposalID)
        external
        view
        returns (uint256)
    {
        uint256 _hashedProposalID;
        address _GOVContractAddress;

        (_hashedProposalID, _GOVContractAddress) = MasterDAOStorageContract
        .getHashedProposalID(_proposalID);

        GovernanceContract _GovernanceContractInstance = GovernanceContract(
            payable(_GOVContractAddress)
        );

        return uint256(_GovernanceContractInstance.state(_hashedProposalID));
    }

    function getDAOContractDetailsByAddress(address _erc20TokenAddress)
        external
        view
        returns (
            address,
            address,
            string memory,
            uint256,
            uint256[] memory
        )
    {
        return
            MasterDAOStorageContract.getDAOContractDetailsByAddress(
                _erc20TokenAddress
            );
    }

    function getDAOContractDetailsByName(string memory _name)
        external
        view
        returns (
            address,
            address,
            string memory,
            uint256,
            uint256[] memory
        )
    {
        return MasterDAOStorageContract.getDAOContractDetailsByName(_name);
    }

    function getDAOContractDetailsByCreator()
        external
        view
        returns (
            address,
            address,
            string memory,
            uint256,
            uint256[] memory
        )
    {
        address _creatorAddress = msg.sender;

        return
            MasterDAOStorageContract.getDAOContractDetailsByCreator(
                _creatorAddress
            );
    }

    function userHasVoted(uint256 _proposalID) public view returns (bool) {
        address _userAddress = msg.sender;

        uint256 _hashedProposalID;
        address _GOVContractAddress;

        (_hashedProposalID, _GOVContractAddress) = MasterDAOStorageContract
        .getHashedProposalID(_proposalID);

        GovernanceContract _GovernanceContractInstance = GovernanceContract(
            payable(_GOVContractAddress)
        );

        return
            _GovernanceContractInstance.hasVoted(
                _hashedProposalID,
                _userAddress
            );
    }

    function getProposalResults(uint256 _proposalID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // get hashed proposal id and dedicated GOV contract address from storage contract
        uint256 _hashedProposalID;
        address _GOVContractAddress;

        (_hashedProposalID, _GOVContractAddress) = MasterDAOStorageContract
        .getHashedProposalID(_proposalID);

        // create dedicated GOV contract instance
        GovernanceContract _GovernanceContractInstance = GovernanceContract(
            payable(_GOVContractAddress)
        );

        // return vote results for hashed proposal id
        return _GovernanceContractInstance.proposalVotes(_hashedProposalID);
    }

    function ERC20DAOContractIsExist(address _erc20TokenAddress)
        public
        view
        returns (bool)
    {
        require(_erc20TokenAddress != address(0));

        bool _isExist;
        uint256 _allContracts = MasterDAOStorageContract
        .getDAOContractIDTracker();

        for (uint256 i = 1; i <= _allContracts; i++) {
            if (
                MasterDAOStorageContract.getDAOContractERC20TokenAddressByID(
                    i
                ) == _erc20TokenAddress
            ) {
                _isExist = true;
            } else {
                _isExist = false;
            }
        }

        return _isExist;
    }
}
