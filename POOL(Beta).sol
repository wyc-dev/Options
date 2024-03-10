// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/**
 * @title POOL
 * @dev ERC20 token for speculative betting on asset price movements, using Pyth Network for price feeds.
 */
contract POOL is ERC20, ReentrancyGuard {
    IPyth public pyth;
    
    mapping(address => uint256) private _buyPrice;
    mapping(address => uint256) private _sellPrice;
    mapping(address => uint256) private _betSize;
    mapping(address => uint256) private _userStakingSize;
    mapping(address => uint256) private _userStakingTime;

    uint256 private constant YEAR_IN_SECONDS = 31536000;
    uint256 private constant APY_PERCENT = 10;
    bytes32 private constant PRICE_ID = 0xf9c0172ba10dfa4d19088d94f5bf61d3b54d5bd7483a322a982e1373ee8ea31b;

    event BuyPriceSet(address indexed user, uint price);
    event SellPriceSet(address indexed user, uint price);

    constructor() ERC20("POOL", "POOL") {
        pyth = IPyth(0x056f829183Ec806A78c26C98961678c24faB71af);
    }

    /**
     * @dev Returns the current BTC/USD price.
     */
    function getBtcUsdPrice(bytes[] calldata priceUpdateData) public payable nonReentrant returns (PythStructs.Price memory) {
        uint fee = pyth.getUpdateFee(priceUpdateData);
        require(msg.value >= fee, "Insufficient ETH for fee");
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        return pyth.getPrice(PRICE_ID);
    }

    /**
     * @dev Allows users to bet on price increase.
     */
    function buy(bytes[] calldata priceUpdateData) public payable nonReentrant {
        _bet(priceUpdateData, true);
    }

    /**
     * @dev Allows users to bet on price decrease.
     */
    function sell(bytes[] calldata priceUpdateData) public payable nonReentrant {
        _bet(priceUpdateData, false);
    }

    function convertTokensToEth(uint256 amount) public nonReentrant {
        require(amount <= balanceOf(msg.sender), "Insufficient tokens");
        uint256 totalEth = address(this).balance;
        uint256 tokenSupply = totalSupply();
        uint256 ethAmount = (totalEth * amount) / tokenSupply;
        uint256 fee = ethAmount / 100;
        ethAmount -= fee;

        _burn(msg.sender, amount);

        // Use call method to send ETH
        (bool sent, ) = payable(msg.sender).call{value: ethAmount}("");
        require(sent, "Failed to send Ether");

    }


    function getBoughtPrice() external view returns (uint256) {
        require(_buyPrice[msg.sender] != 0, "No BuyPrice set");
        return _buyPrice[msg.sender];
    }

    function getSoldPrice() external view returns (uint256) {
        require(_sellPrice[msg.sender] != 0, "No SellPrice set");
        return _sellPrice[msg.sender];
    }

    function stake(uint256 amount) public nonReentrant {
        require(amount <= balanceOf(msg.sender), "Insufficient balance");
        _burn(msg.sender, amount);
        _userStakingSize[msg.sender] += amount;
        _userStakingTime[msg.sender] = block.timestamp;
    }

    function checkStakingAmount() public view returns (uint256) {
        uint256 stakedTime = block.timestamp - _userStakingTime[msg.sender];
        uint256 rewardRatePerSecond = (_userStakingSize[msg.sender] * APY_PERCENT) / (YEAR_IN_SECONDS * 100);
        return _userStakingSize[msg.sender] + (stakedTime * rewardRatePerSecond);
    }

    function unstake() public nonReentrant {
        uint256 totalAmount = checkStakingAmount();
        require(totalAmount > 0, "No staked amount");
        _userStakingSize[msg.sender] = 0;
        _userStakingTime[msg.sender] = 0;
        _mint(msg.sender, totalAmount);
    }

    fallback() external payable nonReentrant {}
    receive() external payable nonReentrant {}

    // Private functions
    function _bet(bytes[] calldata priceUpdateData, bool isBuy) private {
        uint fee = pyth.getUpdateFee(priceUpdateData);
        require(msg.value >= fee, "Insufficient ETH for fee");
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        PythStructs.Price memory priceData = pyth.getPrice(PRICE_ID);
        require(priceData.price >= 0, "Invalid price data");
        uint256 currentPrice = uint256(int256(priceData.price));
        _processBet(msg.sender, currentPrice, isBuy);
    }

    function _processBet(address user, uint256 currentPrice, bool isBuy) private {
        if (isBuy) {
            require(_buyPrice[user] == 0, "Existing buy position");
            _betSize[user] = msg.value;
            _buyPrice[user] = currentPrice;
        } else {
            require(_sellPrice[user] == 0, "Existing sell position");
            _betSize[user] = msg.value;
            _sellPrice[user] = currentPrice;
        }
    }
}
