// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";  

//
contract Migrations is Ownable
 {
    uint public last_completed_migration;

    function setCompleted(uint completed) public onlyOwner
    {
        last_completed_migration = completed;
    }
}
