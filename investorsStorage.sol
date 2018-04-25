// v6
pragma solidity ^0.4.23;


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

contract InvestorsStorage is Ownable {

  mapping (address => uint256) public investors; // map the invested amount
  address[] public investorsList;
  address authorized;

  modifier isAuthorized() { // modifier that allows only presale or crowdsale
    require(msg.sender==authorized);
    _;
  }

  function setAuthorized(address _authorized) onlyOwner public { // change the autorization for presale or crowdsale
    authorized = _authorized;
  }

  function newInvestment(address _investor, uint256 _amount) isAuthorized public { // add the invested amount to the map
    if (investors[_investor] == 0) {
      investorsList.push(_investor);
    }
    investors[_investor] += _amount;
  }

  function getInvestedAmount(address _investor) public view returns (uint256) { // return the invested amount
    return investors[_investor];
  }

  function investmentRefunded(address _investor) isAuthorized public { // set the invested amount to 0 after the refund
    investors[_investor] = 0;
  }

}