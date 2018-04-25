// v6
pragma solidity ^0.4.23;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
// interface to the token contract
interface TokenContract {
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function balanceOf(address _holder) external view returns (uint256);
}
// interface to the storage contract
interface InvestorsStorage {
  function newInvestment(address _investor, uint256 _amount) external;
  function getInvestedAmount(address _investor) external view returns (uint256);
  function investmentRefunded(address _investor) external;
}

contract CrowdSale  is Ownable {
  using SafeMath for uint256;
  // variables

  TokenContract public tkn;
 
  InvestorsStorage public investorsStorage;
  uint256 public levelEndDate;
  uint256 public currentLevel;
  uint256 public levelTokens = 3750000;
  uint256 public tokensSold;
  uint256 public weiRised;
  uint256 public ethPrice;
  address[] public investorsList;
  bool public crowdSalePaused;
  bool public crowdSaleEnded;
  bool public canRefund;
  uint256 public softcap;
  bool public  softcapReached;
  uint256[4] private tokenPrice = [49, 60, 67, 70];
  uint256 private baseTokens = 3750000;
  uint256 private usdCentValue;
  uint256 private minInvestment;

   constructor() public {
    uint256 startDate = now;
    levelEndDate = startDate + (1 * 7 days);
    tkn = TokenContract(0x0);                    // address of the token contract 
    investorsStorage = InvestorsStorage(0x0);      // address of the storage contract
    softcap = 1000000;
    minInvestment = 100 finney;
    updatePrice(5000);
  }

  // fallback payable function
  function() payable public {
    require(msg.value >= minInvestment); // check for minimum investment amount
    require(!crowdSalePaused);
    require(!crowdSaleEnded);
    if (currentLevel < 3) { // there are 4 levels, array start with 0
      if (levelEndDate < now) { // if the end date of the level is reached
        currentLevel += 1;
        levelTokens += baseTokens; // add remaining tokens to next level
        levelEndDate = levelEndDate.add(1 * 7 days); // restart end date
        prepareSell(msg.sender, msg.value);
        } else {
        prepareSell(msg.sender, msg.value);
        }
    } else {
      if (levelEndDate < now) { // on last level, ask for extension, if the crowd sale is not extended then end
        crowdSaleEnded = true;
        msg.sender.transfer(msg.value);
        } else {
        prepareSell(msg.sender, msg.value);
        }  
      }
  }

  function prepareSell(address _investor, uint256 _amount) private {
    uint256 remaining;
    uint256 pricePerCent;
    uint256 pricePerToken;
    uint256 toSell;
    uint256 amount = _amount;
    uint256 sellInWei;
    address investor = _investor;
    
    pricePerCent = getUSDPrice();
    pricePerToken = pricePerCent.mul(tokenPrice[currentLevel]);
    toSell = _amount.div(pricePerToken);
       
    if (toSell < levelTokens) { // if there is enough tokens left in the current level, sell from it
      levelTokens = levelTokens.sub(toSell);
      weiRised = weiRised.add(_amount);
      executeSell(investor, toSell, _amount);
      if (softcapReached) {
        owner.transfer(_amount);
      } 
    } else {  // if not, sell from 2 or more different levels
      while (amount > 0) {
        if (toSell > levelTokens) {
          toSell = levelTokens; // sell all the remaining in the level
          sellInWei = toSell.mul(pricePerToken);
          amount = amount.sub(sellInWei);
          if (currentLevel < 3) {  
            currentLevel += 1;
            levelTokens = baseTokens;
            if (currentLevel == 3) {  
              baseTokens = tkn.balanceOf(address(this));  // on last level, sell the remaining from presale
            }
          } else {
            remaining = amount;
            amount = 0;
          }
        } else {
          sellInWei = amount;
          amount = 0;
        }
        
        executeSell(investor, toSell, sellInWei); 
        weiRised = weiRised.add(sellInWei);
        if (softcapReached) {
          owner.transfer(amount);
        } 
        if (amount > 0) {
          toSell = amount.div(pricePerToken);
        }
        if (remaining > 0) {
          investor.transfer(remaining);
          owner.transfer(address(this).balance);
          crowdSaleEnded = true;
        }
      }
    }
  }

  function executeSell(address _investor, uint256 _tokens, uint256 _weiAmount) private {
    uint256 totalTokens = _tokens * (10 ** 18);
    tokensSold += _tokens; // update tokens sold
    investorsStorage.newInvestment(_investor, _weiAmount);

    require(tkn.transfer(_investor, totalTokens)); // transfer the tokens to the investor
    emit NewInvestment(_investor, totalTokens);
  }


  // send tokens left to the owner
  function terminateCrowdSale() onlyOwner public {
    require(crowdSaleEnded);
    uint256 remainingTokens = tkn.balanceOf(address(this));
    // address _crowdSaleAddress = crowdSaleAddress;
    require(tkn.transfer(owner, remainingTokens));
    selfdestruct(owner);
  }

  function getUSDPrice() private view returns (uint256) {
    return usdCentValue;
  }

  function updatePrice(uint256 _ethPrice) private {
    uint256 centBase = 1 * 10 ** 16;
    require(_ethPrice > 0);
    ethPrice = _ethPrice;
    usdCentValue = centBase.div(_ethPrice);
    checkSoftcap();
  }

  function setUsdEthValue(uint256 _ethPrice) onlyOwner external { // set the ETH value in USD
    updatePrice(_ethPrice);
  }

  function setStorageAddress(address _investorsStorage) onlyOwner public { // set the storage contract address
    investorsStorage = InvestorsStorage(_investorsStorage);
  }

  function pauseCrowdSale(bool _paused) onlyOwner public { // pause the crowdsale
    crowdSalePaused = _paused;
  }

  function enableRefunds(bool _enabled) onlyOwner public { // enable refunds
    canRefund = _enabled;
  }

  function checkSoftcap() private { // check if the softcap is reached
    if (weiRised.div(usdCentValue).mul(100) >= softcap) {
      softcapReached = true;
    }
  }

  function getFunds() onlyOwner public { // claim the funds if the softcap is reached
    require(softcapReached);
    owner.transfer(address(this).balance);
  }

  function getRefund() public {
    require(!softcapReached); // check for softcap
    require(crowdSaleEnded); 
    require(canRefund);
    uint256 toRefund = investorsStorage.getInvestedAmount(msg.sender); // get the amount to refund from storage
    if (toRefund > 0) { // transfer if the value is > 0
      investorsStorage.investmentRefunded(msg.sender);
      msg.sender.transfer(toRefund);
      weiRised -= toRefund;
    }
  }


  event NewInvestment(address _investor, uint256 tokens);

}
