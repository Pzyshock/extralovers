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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract TokenContract is Ownable, StandardToken {
  string public constant name = "ExtraToken";
  string public constant symbol = "ELT";
  uint8 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 30000000 * (10 ** uint256(decimals));

  constructor() public {                      
    
    address presaleAddress = 0x0;
    address crowdSaleAddress = 0x0;
    address affiliatesAddress = 0x0;
    address advisorAddress = 0x0;
    address bountyAddress = 0x0;
    address airdropAddress = 0x0;
    address extraLoversAddress = 0x0;
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = 2400000 * (10 ** uint256(decimals));  // transfered to the owner (2% + 6%)
    emit Transfer(0x0, msg.sender, 2400000 * (10 ** uint256(decimals)));

    balances[presaleAddress] = 4500000 * (10 ** uint256(decimals));  // transfer to presale contract
    emit Transfer(0x0, presaleAddress, 4500000 * (10 ** uint256(decimals)));

    balances[crowdSaleAddress] = 1500000 * (10 ** uint256(decimals)); // transfer to crowdsale contract
    emit Transfer(0x0, presaleAddress, 1500000 * (10 ** uint256(decimals)));

    balances[affiliatesAddress] = 3600000 * (10 ** uint256(decimals)); // transfer to affiliates contract
    emit Transfer(0x0, affiliatesAddress, 3600000 * (10 ** uint256(decimals)));

    balances[advisorAddress] = 900000 * (10 ** uint256(decimals)); // transfer to advisors wallet
    emit Transfer(0x0, advisorAddress, 900000 * (10 ** uint256(decimals)));

    balances[bountyAddress] = 900000 * (10 ** uint256(decimals)); // transfer to bounty wallet
    emit Transfer(0x0, bountyAddress, 900000 * (10 ** uint256(decimals)));

    balances[airdropAddress] = 900000 * (10 ** uint256(decimals)); // transfer to airdrop wallet / contract
    emit Transfer(0x0, airdropAddress, 900000 * (10 ** uint256(decimals)));

    balances[extraLoversAddress] = 1800000 * (10 ** uint256(decimals)); // transfer to valult contract
    emit Transfer(0x0, extraLoversAddress, 1800000 * (10 ** uint256(decimals)));
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}
