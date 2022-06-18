// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Utils/GovernanceContract.sol";
import "./Utils/TimeLock.sol";
import "./Utils/DAOToken.sol";
import "./MasterDAOStorage.sol";

contract MasterDAOStorage {
    using Counters for Counters.Counter;

    Counters.Counter public DAOContractIDTracker;
    Counters.Counter public ProposalIDTracker;

    address DAOTokenContract;
    address TimeLockContract;

    struct DAOContracts {
        address _owner;
        address _GovernanceContract;
        address _erc20Token;
        string _erc20TokenName;
        uint256 _id;
        uint256[] _proposals;
    }

    mapping(uint256 => DAOContracts) public ERC20TokenDAOContarcts;
    mapping(uint256 => uint256[]) public ProposalIDToProposalHashID;

    /// /////////////////////////////////////////////////////////////////////////////// SETTER FUNCTIONS

    function setAddress(address _DAOTokenContract, address _TimeLockContract)
        external
    {
        DAOTokenContract = _DAOTokenContract;
        TimeLockContract = _TimeLockContract;
    }

    /// /////////////////////////////////////////////////////////////////////////////// MAIN FUNCTIONS

    function createNewDAOContract(
        address _creatorAddress,
        address _erc20TokenAddress,
        uint256 _votingDelay,
        uint256 _votingPeriod
    ) external returns (uint256) {
        DAOContractIDTracker.increment();
        uint256 _newDAOContractID = DAOContractIDTracker.current();

        GovernanceContract _newContract = new GovernanceContract(
            DAOToken(DAOTokenContract),
            TimeLock(payable(TimeLockContract)),
            _votingDelay,
            _votingPeriod
        );

        DAOContracts memory _DAOContracts;

        _DAOContracts._owner = _creatorAddress;
        _DAOContracts._GovernanceContract = address(_newContract);
        _DAOContracts._erc20Token = _erc20TokenAddress;
        _DAOContracts._erc20TokenName = ERC20(_erc20TokenAddress).name();
        _DAOContracts._id = _newDAOContractID;

        ERC20TokenDAOContarcts[_newDAOContractID] = _DAOContracts;

        return _newDAOContractID;
    }

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

        GovernanceContract _contractInstance = GovernanceContract(
            payable(_DAOContract._GovernanceContract)
        );

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

    /// /////////////////////////////////////////////////////////////////////////////// GETTERS FUNCTIONS

    function getDAOContractIDTracker() public view returns (uint256) {
        return DAOContractIDTracker.current();
    }

    function getDAOContractERC20TokenAddressByID(uint256 _id)
        external
        view
        returns (address)
    {
        return ERC20TokenDAOContarcts[_id]._erc20Token;
    }

    function getDAOContractERC20TokenNameByID(uint256 _id)
        external
        view
        returns (string memory)
    {
        return ERC20TokenDAOContarcts[_id]._erc20TokenName;
    }

    function getDAOContractCreatorByID(uint256 _id)
        external
        view
        returns (address)
    {
        return ERC20TokenDAOContarcts[_id]._owner;
    }

    function getDAOContractProposalsByID(uint256 _id)
        external
        view
        returns (uint256[] memory)
    {
        return ERC20TokenDAOContarcts[_id]._proposals;
    }

    function getDAOContractAddressByID(uint256 _id)
        public
        view
        returns (address)
    {
        return ERC20TokenDAOContarcts[_id]._GovernanceContract;
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

    function getDAOContractDetailsByCreator(address _creatorAddress)
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
            if (ERC20TokenDAOContarcts[i]._owner == _creatorAddress) {
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
}
