//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Utils/GovernanceContract.sol";
import "./Utils/TimeLock.sol";
import "./GOVToken.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

contract GOVMaster {
    using Counters for Counters.Counter;

    Counters.Counter public ProposalIDTracker;

    address public GOVTokenContract;
    address public TimeLockContract;

    struct ProposalData {
        address creatorAddress;
        address ERC20TokenAddress;
        uint256 proposalIDHash;
        uint256 proposalID;
        address proposalDAOContract;
    }

    mapping(address => address) ERC20TokenProposalsContarcts;
    mapping(uint256 => ProposalData) public ProposalDataFromID;

    function setAddress(address _GOVTokenContract, address _TimeLockContract)
        external
    {
        TimeLockContract = _TimeLockContract;
        GOVTokenContract = _GOVTokenContract;
    }

    /// //////////////////////////////////////////////////////////////////////// Proposal Contract Section

    function createNewProposalContract(address _ERC20TokenAddress) external {
        GovernanceContract _newContract = new GovernanceContract(
            GOVToken(GOVTokenContract),
            TimeLock(payable(TimeLockContract))
        );

        ERC20TokenProposalsContarcts[_ERC20TokenAddress] = address(
            _newContract
        );
    }

    /// //////////////////////////////////////////////////////////////////////// Create Proposal  Section

    function createProposal(
        address _ERC20TokenAddress,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external {
        ProposalIDTracker.increment();

        address _proposalContractAddress = ERC20TokenProposalsContarcts[
            _ERC20TokenAddress
        ];

        GovernanceContract _contractInstance = GovernanceContract(
            payable(_proposalContractAddress)
        );

        uint256 proposalID = _contractInstance.propose(
            targets,
            values,
            calldatas,
            description
        );

        ProposalDataFromID[ProposalIDTracker.current()].creatorAddress = msg
        .sender;
        ProposalDataFromID[ProposalIDTracker.current()]
        .ERC20TokenAddress = _ERC20TokenAddress;
        ProposalDataFromID[ProposalIDTracker.current()]
        .proposalIDHash = proposalID;
        ProposalDataFromID[ProposalIDTracker.current()]
        .proposalID = ProposalIDTracker.current();
        ProposalDataFromID[ProposalIDTracker.current()]
        .proposalDAOContract = _proposalContractAddress;
    }

    /// //////////////////////////////////////////////////////////////////////// Proposal Contract Getter Section

    function getDAOContractAddressOfERC20Token(address _ERC20TokenAddress)
        external
        view
        returns (address)
    {
        return ERC20TokenProposalsContarcts[_ERC20TokenAddress];
    }

    function getProposalDetails(uint256 _proposalID)
        external
        view
        returns (uint256)
    {
        ProposalData memory _ProposalData = ProposalDataFromID[_proposalID];
        uint256 _proposalHash = _ProposalData.proposalIDHash;
        address _proposalDAOContract = _ProposalData.proposalDAOContract;

        GovernanceContract _contractInstance = GovernanceContract(
            payable(_proposalDAOContract)
        );

        return uint256(_contractInstance.state(_proposalHash));
    }

    function getProposalIDHash(uint256 _proposalID)
        external
        view
        returns (uint256)
    {
        ProposalData memory _ProposalData = ProposalDataFromID[_proposalID];
        return _ProposalData.proposalIDHash;
    }

    function getProposalCreator(uint256 _proposalID)
        external
        view
        returns (address)
    {
        ProposalData memory _ProposalData = ProposalDataFromID[_proposalID];
        return _ProposalData.creatorAddress;
    }

    function getProposalDAOContarct(uint256 _proposalID)
        external
        view
        returns (address)
    {
        ProposalData memory _ProposalData = ProposalDataFromID[_proposalID];
        return _ProposalData.proposalDAOContract;
    }

    function getProposalERC20TokenAddress(uint256 _proposalID)
        external
        view
        returns (address)
    {
        ProposalData memory _ProposalData = ProposalDataFromID[_proposalID];
        return _ProposalData.ERC20TokenAddress;
    }

    function getAllProposalsOfERC20TokenAddress(address _ERC20TokenAddress)
        external
        view
        returns (ProposalData[] memory)
    {
        uint256 _allProposalsNumber = ProposalIDTracker.current();
        uint256 _itemCount = 0;

        for (uint256 i = 1; i <= _allProposalsNumber; i++) {
            if (ProposalDataFromID[i].ERC20TokenAddress == _ERC20TokenAddress) {
                _itemCount += 1;
            }
        }

        uint256 _currentIndex = 0;
        ProposalData[] memory _proposalItems = new ProposalData[](_itemCount);

        for (uint256 i = 1; i <= _allProposalsNumber; i++) {
            if (ProposalDataFromID[i].ERC20TokenAddress == _ERC20TokenAddress) {
                uint256 _currentItemId = ProposalDataFromID[i].proposalID;
                ProposalData storage _currentItem = ProposalDataFromID[
                    _currentItemId
                ];
                _proposalItems[_currentIndex] = _currentItem;
                _currentIndex += 1;
            }
        }

        return _proposalItems;
    }

    /// //////////////////////////////////////////////////////////////////////// GOV Token Contract Section
}
