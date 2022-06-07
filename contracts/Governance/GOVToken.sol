//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract GOVToken is ERC20Votes, Ownable {
    uint256 _fixedSupply = 1000000000000000000000000;

    constructor() ERC20("GOVToken", "GOVToken") ERC20Permit("GOVToken") {
        _mint(msg.sender, _fixedSupply);
    }

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

    function mintPower(address _userAddress, uint256 _toMint)
        external
        onlyOwner
        returns (bool)
    {
        _mint(_userAddress, _toMint);
        return true;
    }
}
