// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./INftMarket.sol";
import "./IERC721.sol";
import "./NftShop.sol";

contract NftMarket is Ownable, INftMarket
{
  uint256 private feePercent;

  address private feeFund;

  address[] public Nfts;

  mapping(address => address) public Shops;

  event onChangeFeePercent(address indexed _op, uint256 oldFeePercent, uint256 newFeePercent);

  event onChangeFeeFund(address indexed _op, address indexed previousFeeFund, address indexed newFeeFund);

  event OnDeployShop(address indexed shop);

  function getFeePercent() public override view returns(uint256)
  {
    return feePercent;
  }

  function setFeePercent(uint256 fee) public onlyOwner
  {
     require((fee > 0) && (fee < 100), "invalid fee");

     uint256 oldFeePercent = feePercent;

     if(oldFeePercent != fee)
     {
       feePercent = fee;

       emit onChangeFeePercent(_msgSender(), oldFeePercent, fee);
     }
  }


  function getFeeFund() public override view returns(address)
  {
    return feeFund;
  }

  function setFeeFund(address fund) public onlyOwner
  {
     require(fund != address(0), "invalid fund address");

     address oldFeeFund = feeFund;

     if(oldFeeFund != fund)
     {
       feeFund = fund;

       emit onChangeFeeFund(_msgSender(), oldFeeFund, feeFund);
     }
  }

   function deployShop(address nftAddress) external onlyOwner {
        require(nftAddress != address(0), 'invalid nft address');

        require(Shops[nftAddress] == address(0), 'shop exist');

        bytes memory bytecode = type(NftShop).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(nftAddress));

        address shopAddress;

        assembly {
            shopAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        NftShop(shopAddress).initialize(
            nftAddress,

            address(this)
        );

        emit OnDeployShop(shopAddress);

        Nfts.push(nftAddress);

        Shops[nftAddress] = shopAddress;
    }
}