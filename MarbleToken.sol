pragma solidity ^0.4.18;

//SafeMath

library SafeMath{
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c){
        c = a + b;
        require(c >= a);
    }
    function safeSubstract(uint256 a, uint256 b) internal pure returns (uint256 c){
        require(b <= a);
        c = a - b;
    }
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256 c){
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c){
        require (b>0);
        c = a / b;
    }
}

//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
//ERC20 Token Standard #20 Interface

contract ERC20Interface{
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256);
    function allowance(address tokenOwner, address spender) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
    //indexed keyword
}

//------------------------------------------------------------------------------
// ApproveAndCallFallBack Interface

contract ApproveAndCallFallBack{
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

//------------------------------------------------------------------------------
//Ownable contract based on OpenZeppelin's

contract Ownable{
    address public owner;
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    
    //The constructor initially set the owner to be the sender
    constructor() public{
        owner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    //After the function is called, the contract has no owner and functions
    //modified with onlyOwner will not be callable anymore
    function renounceOwnership() public onlyOwner{
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
    
    function transferOwnership(address newOwner) public onlyOwner{
        _transferOwnership(newOwner);
    }
    
    //internal function for transfering ownership
    function _transferOwnership(address newOwner) internal{
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

//------------------------------------------------------------------------------
//Claimable contract based on OpenZeppelin's 

contract Claimable is Ownable{
    address public pendingOwner;
    
    modifier onlyPendingOwner(){
        require(msg.sender == pendingOwner);
        _;
    }
    
    //Allow the current owner to appoint the pending owner
    function transferOwnership(address newOwner) onlyOwner public{
        pendingOwner = newOwner;
    }
    
    //Allows the pendingOwner to claim the Ownership
    function claimOwnership() onlyPendingOwner public{
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
    
}

//------------------------------------------------------------------------------
//Marbles Token contract

contract MarbleToken is ERC20Interface, Claimable{
    using SafeMath for uint256;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 _totalSupply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    constructor() public{
        symbol = "MTK";
        name = "Marble Token";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;//100 tokens with 18 decimals
        balances[msg.sender] = _totalSupply; //Let the creator hold all to coin
    }
    
    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint256){
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view
    returns(uint256){
        return allowed[tokenOwner][spender];
    }
    
    function transfer(address receiver, uint256 value) public returns (bool success){
        balances[msg.sender] = balances[msg.sender].safeSubstract(value);
        balances[receiver] = balances[receiver].safeAdd(value);
        emit Transfer(msg.sender, receiver, value);
        success = true;
    }
    
    //Let the spender to use an approved token from the msg.sender balance
    function approve(address spender, uint256 value) public returns (bool success){
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        success = true;
    }
    
    function transferFrom(address from, address to, uint256 value) 
    public returns (bool success){
        balances[from] =balances[from].safeSubstract(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].safeSubstract(value);
        balances[to] = balances[to].safeAdd(value);
        emit Transfer(from,to,value);
        success = true;
    }
    
    function approveAndCall(address spender, uint256 value, bytes data)
    public returns (bool success){
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender,spender,value);
        ApproveAndCallFallBack(spender).receiveApproval(
            msg.sender,
            value,
            this,
            data
            );
        //Dummy call since there is no implementation of the function here
        success = true;
    }
    
    function () public payable{
        revert();
        //This means the contract don't accept ETH
        //ETH will be refund to the sender
    }
    
    function transferAnyERC20Token(address tokenAddress, uint value) 
    public onlyOwner returns(bool){
        return ERC20Interface(tokenAddress).transfer(owner, value);
    }
}
