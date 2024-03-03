// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Ownable.sol';
import './Pausable.sol';
import './ERC20.sol';

contract Grampus is Ownable, Pausable, ERC20
{
    uint private constant Initsupply = 10 ** 8 * 10 ** 18;

    constructor() ERC20("Grampus", "graus")
    {
      _mint(owner(), Initsupply);
    }

    function pause() public onlyOwner
    {
        _pause();
    }

    function unpause() public onlyOwner
    {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal override 
    {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "Grampus: token transfer while paused");
    }
}