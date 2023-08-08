// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;
import "./SafeMath.sol";

/*

  88      88      8888      8888888      8888888888
  88      88     88  88     88    88            88
  88      88    88    88    88     88          88
  88      88    888         88      88        88
  88      88      8888      88      88       88
  88      88         888    88      88      88
  88      88    88    88    88     88      88
   88    88      88  88     88    88      88
    888888        8888      8888888      8888888888

*/

contract USDZToken is SafeMath {
    string public constant standard = 'ZRC20';
    uint8 public constant decimals = 8; // it's recommended to set decimals to 8 in ZHCASH

    // you need change the following three values
    string public constant name = 'United States Dollar ZHCHAIN';
    string public constant symbol = 'USDZ';
    //Default assumes totalSupply can't be over max (2^256 - 1).
    //you need multiply 10^decimals by your real total supply.
    uint256 public totalSupply = 10 ** 10 * 10 ** uint256(decimals);
    //The owner can add and remove smart contract addresses accepting USDZ
    address owner;
    //Pool of smart contracts accepting USDZ
    address [] public pool;
    mapping (address => bool) public isAddressFromPool;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }
    // validates owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function transfer(address _to, uint256 _value)
    public
    validAddress(_to)
    returns (bool)
    {
        if (isAddressFromPool[_to]){
            (bool success, ) = _to.call(abi.encodeWithSignature("transferForUSDZ(address,uint256)",  msg.sender, _value));
            if (success == false) {
                return false;
            }
        }

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public
    validAddress(_from)
    validAddress(_to)
    returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
    public
    validAddress(_spender)
    returns (bool success)
    {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function addToPool(address _contract_address)
    public
    onlyOwner
    {
        isAddressFromPool[_contract_address] = true;
        pool.push(_contract_address);
    }

    function deleteContractAddress(uint256 _index)
    public
    onlyOwner
    {
        isAddressFromPool[pool[_index]] = false;
        pool[_index] = pool[pool.length-1];
        pool.pop();
    }

    function ChangeAddressFromPool(address _contract_address,bool _isAddressFromPool)
    public
    onlyOwner
    {
        isAddressFromPool[_contract_address] = _isAddressFromPool;
    }

    function getPool()
    public view
    returns (address [] memory)
    {
        return pool;
    }

    receive() external payable {
        revert();
    }

}
