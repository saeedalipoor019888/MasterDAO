// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
        string _erc20TokenName;
        uint256 _id;
        uint256[] _proposals;
    }

    mapping(uint256 => DAOContracts) ERC20TokenDAOContarcts;
    mapping(uint256 => uint256[]) public ProposalIDToProposalHashID;

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
        _DAOContracts._erc20TokenName = ERC20(_erc20TokenAddress).name();
        _DAOContracts._id = _newDAOContractID;

        ERC20TokenDAOContarcts[_newDAOContractID] = _DAOContracts;

        return _newDAOContractID;
    }

    /// /////////////////////////////////////////////////////////////////////////////// PROPOSAL FUNCTIONS

    function createProposal(
        address _erc20TokenAddress,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (bool) {
        ProposalIDTracker.increment();
        uint256 _newProposalID = ProposalIDTracker.current();

        uint256 _allContracts = DAOContractIDTracker.current();
        DAOContracts memory _DAOContract;

        for (uint256 i = 1; i <= _allContracts; i++) {
            if (ERC20TokenDAOContarcts[i]._erc20Token == _erc20TokenAddress) {
                _DAOContract = ERC20TokenDAOContarcts[i];
            } else {
                return false;
            }
        }

        GovernanceContract _contractInstance = _DAOContract._GovernanceContract;

        uint256 _proposalID = _contractInstance.propose(
            targets,
            values,
            calldatas,
            description
        );

        ERC20TokenDAOContarcts[_DAOContract._id]._proposals.push(_proposalID);

        ProposalIDToProposalHashID[_newProposalID].push(_proposalID);
        ProposalIDToProposalHashID[_newProposalID].push(_DAOContract._id);

        return true;
    }

    function voteForProposal(
        uint256 _proposalID,
        uint8 _support,
        string calldata _reason
    ) external returns (bool) {
        // get all governance contracts / counter!
        DAOContracts memory _DAOContract = ERC20TokenDAOContarcts[
            ProposalIDToProposalHashID[_proposalID][1]
        ];

        // find proposal hashed id
        uint256 _hashedProposalID = ProposalIDToProposalHashID[_proposalID][0];
        // vote for proposal
        _DAOContract._GovernanceContract.VoteToProposal(
            msg.sender,
            _hashedProposalID,
            _support,
            _reason
        );

        return true;
    }

    /// /////////////////////////////////////////////////////////////////////////////// DAO TOKEN FUNCTIONS

    function addPowerToVote() external returns (bool) {
        return DAOToken(DAOTokenContract).addPower(msg.sender);
    }

    /// /////////////////////////////////////////////////////////////////////////////// GETTER FUNCTIONS

    function getProposalState(uint256 _proposalID)
        external
        view
        returns (uint256)
    {
        DAOContracts memory _DAOContract = ERC20TokenDAOContarcts[
            ProposalIDToProposalHashID[_proposalID][1]
        ];

        uint256 _hashedProposalID = ProposalIDToProposalHashID[_proposalID][0];

        return
            uint256(_DAOContract._GovernanceContract.state(_hashedProposalID));
    }

    function getDAOContractDetailsByAddress(address _erc20TokenAddress)
        external
        view
        returns (
            address,
            string memory,
            uint256,
            uint256[] memory
        )
    {
        uint256 _allContracts = DAOContractIDTracker.current();
        DAOContracts memory _DAOContract;

        for (uint256 i = 1; i <= _allContracts; i++) {
            if (ERC20TokenDAOContarcts[i]._erc20Token == _erc20TokenAddress) {
                _DAOContract = ERC20TokenDAOContarcts[i];
            }
        }

        return (
            _DAOContract._owner,
            _DAOContract._erc20TokenName,
            _DAOContract._id,
            _DAOContract._proposals
        );
    }

    function getDAOContractDetailsByName(string memory _name)
        external
        view
        returns (
            address,
            string memory,
            uint256,
            uint256[] memory
        )
    {
        uint256 _allContracts = DAOContractIDTracker.current();
        DAOContracts memory _DAOContract;

        for (uint256 i = 1; i <= _allContracts; i++) {
            //compare strings by hashing the packed encoding values of the string
            if (
                keccak256(
                    abi.encodePacked(ERC20TokenDAOContarcts[i]._erc20TokenName)
                ) == keccak256(abi.encodePacked(_name))
            ) {
                _DAOContract = ERC20TokenDAOContarcts[i];
            }
        }

        return (
            _DAOContract._owner,
            _DAOContract._erc20TokenName,
            _DAOContract._id,
            _DAOContract._proposals
        );
    }

    function getDAOContractDetailsByCreator()
        external
        view
        returns (
            address,
            string memory,
            uint256,
            uint256[] memory
        )
    {
        uint256 _allContracts = DAOContractIDTracker.current();
        DAOContracts memory _DAOContract;

        for (uint256 i = 1; i <= _allContracts; i++) {
            if (ERC20TokenDAOContarcts[i]._owner == msg.sender) {
                _DAOContract = ERC20TokenDAOContarcts[i];
            }
        }

        return (
            _DAOContract._owner,
            _DAOContract._erc20TokenName,
            _DAOContract._id,
            _DAOContract._proposals
        );
    }

    function userHasVoted(uint256 _proposalID) public view returns (bool) {
        address _userAddress = msg.sender;
        DAOContracts memory _DAOContract = ERC20TokenDAOContarcts[
            ProposalIDToProposalHashID[_proposalID][1]
        ];

        uint256 _hashedProposalID = ProposalIDToProposalHashID[_proposalID][0];

        return
            _DAOContract._GovernanceContract.hasVoted(
                _hashedProposalID,
                _userAddress
            );
    }

    function getProposalResults(uint256 _proposalID)
        external
        view
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        DAOContracts memory _DAOContract = ERC20TokenDAOContarcts[
            ProposalIDToProposalHashID[_proposalID][1]
        ];

        uint256 _hashedProposalID = ProposalIDToProposalHashID[_proposalID][0];

        return
            _DAOContract._GovernanceContract.proposalVotes(_hashedProposalID);
    }
}
