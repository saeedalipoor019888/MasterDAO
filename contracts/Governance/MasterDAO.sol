// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./GovernanceContract.sol";

import "./TimeLock.sol";
import "./GOVToken.sol";

contract MasterDAO {
    using Counters for Counters.Counter;

    Counters.Counter public DAOContractIDTracker;
    Counters.Counter public ProposalIDTracker;

    address GOVTokenContract;
    address TimeLockContract;

    mapping(uint256 => GovernanceContract) ERC20TokenDAOContarcts;
    mapping(uint256 => uint256) public ProposalIDToProposalHashID;

    function setAddress(address _GOVTokenContract, address _TimeLockContract)
        external
    {
        TimeLockContract = _TimeLockContract;
        GOVTokenContract = _GOVTokenContract;
    }

    function createNewDAOContract() external returns (uint256) {
        DAOContractIDTracker.increment();
        uint256 _newDAOContractID = DAOContractIDTracker.current();

        GovernanceContract _newContract = new GovernanceContract(
            GOVToken(GOVTokenContract),
            TimeLock(payable(TimeLockContract))
        );

        ERC20TokenDAOContarcts[_newDAOContractID] = _newContract;

        return _newDAOContractID;
    }

    function createProposal(
        uint256 _id,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external {
        ProposalIDTracker.increment();
        uint256 _newProposalID = ProposalIDTracker.current();

        GovernanceContract _contractInstance = ERC20TokenDAOContarcts[_id];

        uint256 proposalID = _contractInstance.propose(
            targets,
            values,
            calldatas,
            description
        );

        ProposalIDToProposalHashID[_newProposalID] = proposalID;
    }

    function voteForProposal(
        uint256 _DAOContractID,
        uint256 _proposalID,
        uint8 _support,
        string calldata _reason
    ) external returns (uint256) {
        GovernanceContract _DAOContract = ERC20TokenDAOContarcts[
            _DAOContractID
        ];
        uint256 _hashedProposalID = ProposalIDToProposalHashID[_proposalID];

        return
            _DAOContract.VoteToProposal(
                msg.sender,
                _hashedProposalID,
                _support,
                _reason
            );
    }

    function getProposalState(uint256 _DAOContractID, uint256 _proposalID)
        external
        view
        returns (uint256)
    {
        GovernanceContract _DAOContract = ERC20TokenDAOContarcts[
            _DAOContractID
        ];
        uint256 _hashedProposalID = ProposalIDToProposalHashID[_proposalID];

        return uint256(_DAOContract.state(_hashedProposalID));
    }
}
