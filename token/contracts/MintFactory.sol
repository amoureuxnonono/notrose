// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "/MintNode.sol;"

contract MintFactory is Ownable {
    mapping (uint256 => address[]) public Pools;
    mapping (uint256 => bool) public HasPool;

    function deployPool(
        uint256 _start,
        uint256 _count) external onlyOwner {
        require(!HasPool[_start]);
        bytes memory bytecode = type(MintNode).creationCode;
        HasPool[_start] = true;
        Pools[_start] = new address[](_count);
        address[] memory ps = Pools[_start];
        for(uint256 i = 0; i < _count; i++){
            bytes32 salt = keccak256(abi.encodePacked(_start + i));

            address syrupPoolAddress;

            assembly {
               syrupPoolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }

            ps[i] = syrupPoolAddress;
        }
    }

    function mint(uint256 _start) external onlyOwner{
        require(HasPool[_start]);
        address[] memory ps = Pools[_start];
        for(uint256 i = 0; i < ps.length; i++){
            MintNode(ps[i]).mint();
        }
    }

    function kill(uint256 _start) external onlyOwner{
        require(HasPool[_start]);
        address[] memory ps = Pools[_start];
        for(uint256 i = 0; i < ps.length; i++){
            MintNode(ps[i]).kill();
        }
    }
}
