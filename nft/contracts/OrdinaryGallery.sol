// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract OrdinaryGallery is ERC721, ReentrancyGuard
{
    using SafeMath for uint256;

    using SafeERC20 for IERC20;

    address public feeFund;

    IERC20 public payToken;

    uint256 public createFee;

    uint256 private TokenIds;

        // Whether it is initialized
    bool public isInitialized;

    event onMint(address indexed sender, string url, uint256 fee, uint256 tokenId);

    event onBurn(address indexed sender, uint256 tokenId);

    event onPayTokenChanged(address indexed sender, address oldValue, address newValue);

    event onFeeChanged(address indexed sender, uint256 oldValue, uint256 newValue);

    event onFeeFundChanged(address indexed sender, address oldValue, address newValue);

    constructor() ERC721("Grampus Ordinary Gallery", "grausog")
    {

    }

    function initialize(IERC20 _payToken, address _feeFund, uint256 _createFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!isInitialized, "OrdinaryGallery: Already initialized");

        require(address(_payToken) != address(0), "OrdinaryGallery: pay token can't be zero");

        require(_feeFund != address(0), "OrdinaryGallery: fee fund can't be zero");

        require(_createFee > 0, "OrdinaryGallery: create fee must large than 0");

        // Make this contract initialized
        isInitialized = true;

        payToken = _payToken;

        feeFund = _feeFund;

        createFee = _createFee;
    }

    function setFeeFund(address _feeFund) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_feeFund != address(0), "OrdinaryGallery: fee fund can't be zero");

        address oldValue = feeFund;

        feeFund = _feeFund;

        emit onFeeFundChanged(_msgSender(), oldValue, _feeFund);
    }

    function setCreateFee(uint256 _createFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_createFee > 0, "OrdinaryGallery: create fee must large than 0");

        uint256 oldValue = createFee;

        createFee = _createFee;

        emit onFeeChanged(_msgSender(), oldValue, _createFee);
    }    

    function setPayToken(IERC20 _payToken, uint256 _createFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(_payToken) != address(0), "OrdinaryGallery: pay token can't be zero");

        require(_createFee > 0, "OrdinaryGallery: create fee must large than 0");

        uint256 oldValue = createFee;

        createFee = _createFee;

        emit onFeeChanged(_msgSender(), oldValue, _createFee);

        address oldPayToken = address(payToken);

        payToken = _payToken;

        emit onPayTokenChanged(_msgSender(), oldPayToken, address(_payToken));
    }   

    function mint(string memory uri) external nonReentrant{
        require(isInitialized, "OrdinaryGallery: hasn't initialized");

        require(bytes(uri).length > 0, "OrdinaryGallery: uri can not be empty");

        address recipient = _msgSender();

        payToken.safeTransferFrom(address(recipient), feeFund, createFee);

        uint newItemId = TokenIds;

        TokenIds = TokenIds.add(1);

        _mint(recipient, newItemId);

        _setTokenURI(newItemId, uri);

        emit onMint(recipient, uri, createFee, newItemId);
    }

    function burn(uint256 _tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "OrdinaryGallery: caller is not owner nor approved");
      
        _burn(_tokenId);

        emit onBurn(_msgSender(), _tokenId);
    }   
}