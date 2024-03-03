// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INftMarket
{
   function getFeePercent() external view returns(uint256);

   function getFeeFund() external view returns(address);
}
