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

interface TokenContract {
  function transfer(address _recipient, uint256 _amount) external returns (bool);
  function balanceOf(address _holder) external view returns (uint256);
}

contract Affiliate is Ownable {

  TokenContract public tkn;
  mapping (address => uint256) affiliates;

  function addAffiliates(address[] _affiliates, uint256[] _amount) onlyOwner public {
    require(_affiliates.length > 0);
    require(_affiliates.length == _amount.length);
    for (uint256 i = 0; i < _affiliates.length; i++) {
      affiliates[_affiliates[i]] = _amount[i];
    }
  }

  function claimReward() public {
    if (affiliates[msg.sender] > 0) {
      require(tkn.transfer(msg.sender, affiliates[msg.sender]));
      affiliates[msg.sender] = 0;
    }
  }

  function terminateContract() onlyOwner public {
    uint256 amount = tkn.balanceOf(address(this));
    require(tkn.transfer(owner, amount));
    selfdestruct(owner);
  }

}