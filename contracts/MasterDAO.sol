// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Utils/GovernanceContract.sol";
import "./Utils/TimeLock.sol";
import "./Utils/DAOToken.sol";

contract MasterDAO {
    using Counters for Counters.Counter;

    Counters.Counter public DAOContractIDTracker;
    Counters.Counter public ProposalIDTracker;

    address DAOTokenContract;
    address TimeLockContract;

    struct DAOContracts {
        address _owner;
        GovernanceContract _GovernanceContract;
        address _erc20Token;
        uint256 _id;
        uint256[] _proposals;
    }

    mapping(address => DAOContracts) ERC20TokenDAOContarcts;
    mapping(uint256 => uint256) public ProposalIDToProposalHashID;

    function setAddress(address _DAOTokenContract, address _TimeLockContract)
        external
    {
        TimeLockContract = _TimeLockContract;
        DAOTokenContract = _DAOTokenContract;
    }

    /// /////////////////////////////////////////////////////////////////////////////// DAO FUNCTIONS

    function createNewDAOContract(address _erc20TokenAddress)
        external
        returns (uint256)
    {
        DAOContractIDTracker.increment();
        uint256 _newDAOContractID = DAOContractIDTracker.current();

        GovernanceContract _newContract = new GovernanceContract(
            DAOToken(DAOTokenContract),
            TimeLock(payable(TimeLockContract))
        );

        DAOContracts memory _DAOContracts;

        _DAOContracts._owner = msg.sender;
        _DAOContracts._GovernanceContract = _newContract;
        _DAOContracts._erc20Token = _erc20TokenAddress;
        _DAOContracts._id = _newDAOContractID;

        ERC20TokenDAOContarcts[_erc20TokenAddress] = _DAOContracts;

        return _newDAOContractID;
    }

    /// /////////////////////////////////////////////////////////////////////////////// PROPOSAL FUNCTIONS

    function createProposal(
        address _erc20TokenAddress,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external {
        ProposalIDTracker.increment();
        uint256 _newProposalID = ProposalIDTracker.current();

        GovernanceContract _contractInstance = ERC20TokenDAOContarcts[
            _erc20TokenAddress
        ]
        ._GovernanceContract;

        uint256 _proposalID = _contractInstance.propose(
            targets,
            values,
            calldatas,
            description
        );

        ERC20TokenDAOContarcts[_erc20TokenAddress]._proposals.push(_proposalID);
        ProposalIDToProposalHashID[_newProposalID] = _proposalID;
    }

    function voteForProposal(
        address _erc20TokenAddress,
        uint256 _proposalID,
        uint8 _support,
        string calldata _reason
    ) external returns (bool) {
        GovernanceContract _contractInstance = ERC20TokenDAOContarcts[
            _erc20TokenAddress
        ]
        ._GovernanceContract;

        uint256 _hashedProposalID = ProposalIDToProposalHashID[_proposalID];

        _contractInstance.VoteToProposal(
            msg.sender,
            _hashedProposalID,
            _support,
            _reason
        );

        removePowerToVote();

        return true;
    }

    /// /////////////////////////////////////////////////////////////////////////////// DAO TOKEN FUNCTIONS

    function addPowerToVote() external returns (bool) {
        require(DAOToken(DAOTokenContract).balanceOf(msg.sender) >= 1);
        return DAOToken(DAOTokenContract).addPower(msg.sender);
    }

    function removePowerToVote() private returns (bool) {
        return DAOToken(DAOTokenContract).removePower(msg.sender);
    }

    /// /////////////////////////////////////////////////////////////////////////////// GETTER FUNCTIONS

    function getProposalState(address _erc20TokenAddress, uint256 _proposalID)
        external
        view
        returns (uint256)
    {
        GovernanceContract _contractInstance = ERC20TokenDAOContarcts[
            _erc20TokenAddress
        ]
        ._GovernanceContract;
        uint256 _hashedProposalID = ProposalIDToProposalHashID[_proposalID];

        return uint256(_contractInstance.state(_hashedProposalID));
    }
}
