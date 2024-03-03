// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721Holder.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./INftMarket.sol";
import './EnumerableSet.sol';
import './Math.sol';

contract NftShop is ERC721Holder, Ownable, ReentrancyGuard
{
   using SafeMath for uint256;

   using Address for address;

   using SafeERC20 for IERC20;

   using EnumerableSet for EnumerableSet.UintSet;

   address public constant ETH = 0x0000000000000000000000000000000000000000;

   IERC721 public Nft;

   INftMarket public Market;

   bool public isInitialized; 
 
   mapping(uint256 => address) private askers;

   mapping(uint256 => uint256) private askprices;

   mapping(uint256 => address) private paytokens;
    
   EnumerableSet.UintSet private askindexes;

   mapping(address => EnumerableSet.UintSet) private useraskes;

   mapping(address => EnumerableSet.UintSet) private paytokenaskes;

   event onAsk(address indexed seller, address indexed paytoken, uint256 indexed tokenId, uint256 price);

   event onTrade(address indexed seller, address indexed buyer, address recipient, uint256 indexed tokenId, uint256 price, uint256 fee);

   event onCancelAsk(address indexed seller, uint256 indexed tokenId);

   struct AskNode
   {
      address owner;

      address paytoken;

      uint256 tokenId;

      uint256 price;  
   }

   function initialize(address _nft, address _market) external onlyOwner
   {
      require(!isInitialized, "Already initialized");

      Nft = IERC721(_nft);

      Market = INftMarket(_market);

      isInitialized = true;
   }

   function getPrice(uint256 _tokenid) public view returns (uint256) {
      return askprices[_tokenid];
   }

   function getAskCount() public view returns (uint256) {
      return askindexes.length();
   }

   function getAsksByTokenids(uint256[] memory ids) public view returns (AskNode[] memory) 
   {
      uint256 ids_length = ids.length;

      AskNode[] memory asks = new AskNode[](ids_length);
            
      for (uint256 i = 0; i < ids_length; ++i) {
           uint256 tokenId = ids[i];

           asks[i] = AskNode({tokenId: tokenId, price: askprices[tokenId], paytoken: paytokens[tokenId], owner: askers[tokenId]});
      }

      return asks;
   }
 
   function getAsks(uint256 page, uint256 size) public view returns (AskNode[] memory) 
   {
      return _getAsks(askindexes, page, size);
   }   

   function getAsksDesc(uint256 page, uint256 size) public view returns (AskNode[] memory) 
   {
      return _getAsksDesc(askindexes, page, size);
   }    

   function getUserAskCount(address owner) public view returns (uint256) {
      return useraskes[owner].length();
   }

   function getUserAsks(address owner, uint256 page, uint256 size) public view returns (AskNode[] memory) 
   {
      return _getAsks(useraskes[owner], page, size);
   }   

    function getUserAsksDesc(address owner, uint256 page, uint256 size) public view returns (AskNode[] memory) 
    {
        return _getAsksDesc(useraskes[owner], page, size);
    }   

   function getPayTokenAskCount(address paytoken) public view returns (uint256) {
      return paytokenaskes[paytoken].length();
   }

   function getPayTokenAsks(address paytoken, uint256 page, uint256 size) public view returns (AskNode[] memory) 
   {
      return _getAsks(paytokenaskes[paytoken], page, size);
   }   

    function getPayTokenAsksDesc(address paytoken, uint256 page, uint256 size) public view returns (AskNode[] memory) 
    {
        return _getAsksDesc(paytokenaskes[paytoken], page, size);
    }   

   function _getAsks(EnumerableSet.UintSet storage _indexes, uint256 _page, uint256 _size) private view returns (AskNode[] memory) 
   {
        _page = _page == 0 ? 1 : _page;

        if (_indexes.length() > 0) {
            uint256 from = (_page - 1) * _size;

            uint256 to = Math.min(_page * _size, _indexes.length());
            
            AskNode[] memory asks = new AskNode[](to - from);
            
            for (uint256 i = 0; from < to; ++i) {
                uint256 tokenId = _indexes.at(from);

                asks[i] = AskNode({tokenId: tokenId, price: askprices[tokenId], paytoken: paytokens[tokenId], owner: askers[tokenId]});
                
                ++from;
            }

            return asks;
        }  
           
       return new AskNode[](0);  
    }   

    function _getAsksDesc(EnumerableSet.UintSet storage _indexes, uint256 _page, uint256 _size) private view returns (AskNode[] memory) 
    {
        _page = _page == 0 ? 1 : _page;

        if (_indexes.length() > 0) {
            uint256 from = _indexes.length() - 1 - (_page - 1) * _size;

            uint256 to = from >= _size ? from - _size + 1 : 0;
            
            uint256 resultSize = from - to + 1;
            
            AskNode[] memory asks = new AskNode[](resultSize);

            for (uint256 i = 0; i < resultSize; ++i)
            {
              uint256 tokenId = _indexes.at(from - i);
      
              asks[i] = AskNode({tokenId: tokenId, price: askprices[tokenId], paytoken: paytokens[tokenId], owner: askers[tokenId]});
            }
          
            return asks;
        }

        return new AskNode[](0);
    }  

    function updatePrice(uint256 _tokenId, uint256 _price) external nonReentrant  
    {
        require(isInitialized, "not initialized");

        require(useraskes[_msgSender()].contains(_tokenId), 'Only seller can update price');
    
        require(_price != 0, 'Price must be granter than zero');
    
        askprices[_tokenId] = _price;
    
        emit onAsk(_msgSender(), paytokens[_tokenId], _tokenId, _price);
    }

     function _ask(address paytoken, uint256 _tokenId, uint256 _price) internal
     {
        require(isInitialized, "not initialized");

        address seller = _msgSender();

        require(seller == Nft.ownerOf(_tokenId), 'Only owner can sell');

        require(_price != 0, 'Price must be granter than zero');

        Nft.safeTransferFrom(seller, address(this), _tokenId);

        askindexes.add(_tokenId);

        askers[_tokenId] = seller;

        askprices[_tokenId] = _price;
  
        useraskes[seller].add(_tokenId);

        paytokenaskes[paytoken].add(_tokenId);

        paytokens[_tokenId] = paytoken;
  
        emit onAsk(seller, paytoken, _tokenId, _price);
    }

     function ask(address paytoken, uint256 _tokenId, uint256 _price) external nonReentrant 
     {
        _ask(paytoken, _tokenId, _price);
    }

     function askEth(uint256 _tokenId, uint256 _price) external nonReentrant 
     {
        _ask(ETH, _tokenId, _price);
     }

    function buyEth(uint256 _tokenId) external payable nonReentrant
    {
       _buyEthTo(_tokenId, _msgSender());
    }

     function buyEthTo(uint256 _tokenId, address _to) external payable nonReentrant
    {
        _buyEthTo(_tokenId, _to);
    }

    function _buyEthTo(uint256 _tokenId, address _to) internal 
    {
        require(isInitialized, "not initialized");

        address buyer = _msgSender();

        require(buyer != address(0) && buyer != address(this), "Wrong msg sender");

        require(_to != address(0) && _to != address(this), "Wrong recipient");

        require(askindexes.contains(_tokenId), "Token not in sell book");
        
        require(paytokens[_tokenId] == ETH, "wrong pay token");

        uint256 price = askprices[_tokenId];  

        require(msg.value >= price, "not enough money");

        uint256 remain = msg.value - price;

        if(remain > 0)
        {
          payable(buyer).transfer(remain);
        }
        
        Nft.safeTransferFrom(address(this), _to, _tokenId);
        
        uint256 feeAmount = price.mul(Market.getFeePercent()).div(100);
        
        if (feeAmount != 0) {
          payable(Market.getFeeFund()).transfer(feeAmount);
        }

        address seller = askers[_tokenId];

        payable(seller).transfer(price.sub(feeAmount));
        
        _removeAsk(_tokenId);
        
        emit onTrade(seller, buyer, _to, _tokenId, price, feeAmount);
    }

    function buy(uint256 _tokenId) external nonReentrant
    {
       _buyTo(_tokenId, _msgSender());
    }

    function buyTo(uint256 _tokenId, address _to) external nonReentrant
    {
       _buyTo(_tokenId, _to);
    }

    function _buyTo(uint256 _tokenId, address _to) internal
    {
        require(isInitialized, "not initialized");

        address buyer = _msgSender();

        require(buyer != address(0) && buyer != address(this), "Wrong msg sender");

        require(_to != address(0) && _to != address(this), "Wrong recipient");

        require(askindexes.contains(_tokenId), "Token not in sell book");
        
        require(paytokens[_tokenId] != ETH, "wrong pay token");

        uint256 price = askprices[_tokenId];  

        IERC20 payToken = IERC20(paytokens[_tokenId]);

        Nft.safeTransferFrom(address(this), _to, _tokenId);

        uint256 feeAmount = price.mul(Market.getFeePercent()).div(100);

        if (feeAmount != 0) {
            payToken.safeTransferFrom(buyer, Market.getFeeFund(), feeAmount);
        }

        address seller = askers[_tokenId];

        payToken.safeTransferFrom(buyer, seller, price.sub(feeAmount));
      
        _removeAsk(_tokenId);
        
        emit onTrade(seller, buyer, _to, _tokenId, price, feeAmount); 
    }

    function cancelAsk(uint256 _tokenId) external nonReentrant 
    {
        require(isInitialized, "not initialized");

        address seller = _msgSender();

        require(useraskes[seller].contains(_tokenId), 'Only seller can cancel sell token');
    
        Nft.safeTransferFrom(address(this), seller, _tokenId);
    
        _removeAsk(_tokenId);
    
        emit onCancelAsk(seller, _tokenId);
    }

    function _removeAsk(uint256 _tokenId) internal
    {
        address seller = askers[_tokenId];

        askindexes.remove(_tokenId);
    
        useraskes[seller].remove(_tokenId);

        address paytoken = paytokens[_tokenId];

        paytokenaskes[paytoken].remove(_tokenId);
    
        delete askers[_tokenId];

        delete askprices[_tokenId];

        delete paytokens[_tokenId];
    }
}