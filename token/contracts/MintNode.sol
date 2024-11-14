// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SyrupPool is Ownable {
   IERC20Simple token = IERC20Simple(address(0x2F16386bB37709016023232523FF6d9DAF444BE3));
   IMint minter = IMint(address(0x2F16386bB37709016023232523FF6d9DAF444BE3));
   
   constructor() {
        transferOwnership(address(0x33333333392b691AA2cE6D9fE3D2E5dCF779098C));
    }

    function mint() external{
        minter.mint();
    }

    function kill() external
    {
        token.transfer(owner(), token.balanceOf(address(this)));
        selfdestruct(payable(address(this)));
    } 
}

