//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract GOVToken is ERC20Votes {
    using Counters for Counters.Counter;
    Counters.Counter public ERC20TokenID;

    struct ERC20Tokens {
        address creator;
        address ERC20TokenAddress;
        uint256 ERC20Rate;
        uint256 ERC20TokenID;
    }
    mapping(uint256 => ERC20Tokens) public IDToERC20Tokens;

    constructor() ERC20("GOVToken", "GOVToken") ERC20Permit("GOVToken") {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Votes)
    {
        super._burn(account, amount);
    }

    /// /////////////////////////////////////////////////////////////////////////////// My Functions

    function registerNewERC20(address _ERC20Token, uint256 _ERC20Rate)
        external
        payable
    {
        require(msg.value == 0.01 ether);
        ERC20TokenID.increment();

        ERC20Tokens memory _newERC20Tokens = ERC20Tokens(
            msg.sender,
            _ERC20Token,
            _ERC20Rate,
            ERC20TokenID.current()
        );

        IDToERC20Tokens[ERC20TokenID.current()] = _newERC20Tokens;
    }

    function mintPower(uint256 _ERC20TokenID) external returns (bool) {
        ERC20Tokens memory _newERC20Tokens = IDToERC20Tokens[_ERC20TokenID];

        require(
            IERC20(_newERC20Tokens.ERC20TokenAddress).balanceOf(msg.sender) >=
                _newERC20Tokens.ERC20Rate,
            "influence ERC20 Token Balance"
        );

        IERC20(_newERC20Tokens.ERC20TokenAddress).transferFrom(
            msg.sender,
            address(this),
            _newERC20Tokens.ERC20Rate
        );

        _mint(msg.sender, 1);
        delegate(msg.sender);
        return true;
    }

    /// /////////////////////////////////////////////////////////////////////////////// Getter Functions
    function getERC20TokenDetails(address _ERC20Token)
        external
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        uint256 _ERC20TokenTracker = ERC20TokenID.current();

        for (uint256 i = 1; i <= _ERC20TokenTracker; ++i) {
            ERC20Tokens memory _newERC20Tokens = IDToERC20Tokens[i];
            if (_newERC20Tokens.ERC20TokenAddress == _ERC20Token) {
                return (
                    _newERC20Tokens.ERC20Rate,
                    _newERC20Tokens.ERC20TokenID,
                    _newERC20Tokens.ERC20TokenAddress
                );
            }
        }
        return (0, 0, address(0));
    }

    function getUserPower() external view returns (uint256) {
        return numCheckpoints(msg.sender);
    }
}
