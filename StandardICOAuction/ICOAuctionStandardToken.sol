pragma solidity ^0.4.11;


import "./ERC20Lib.sol";

/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This contract is a modified version of the Standard Token for appication along
 * with the StandardICOAuction.
 * https://github.com/Majoolr/ethereum-contracts/tree/master/StandardICOAuction
 *
 * Majoolr works on open source projects in the Ethereum community with the
 * purpose of testing, documenting, and deploying reusable code onto the
 * blockchain to improve security and usability of smart contracts. Majoolr
 * also strives to educate non-profits, schools, and other community members
 * about the application of blockchain technology.
 * For further information: majoolr.io
 */

 contract ICOAuctionStandardToken {
   using ERC20Lib for ERC20Lib.TokenStorage;

   ERC20Lib.TokenStorage token;

   string public name;
   string public symbol;
   uint public INITIAL_SUPPLY;
   uint public decimals;

   event Transfer(address indexed from, address indexed to, uint value);
   event Approval(address indexed owner, address indexed spender, uint value);
   event ErrorMsg(string msg);

   function ICOAuctionStandardToken(string _name, string _symbol, uint _initialSupply, uint _decimals, address _owner) {
     name = _name;
     symbol = _symbol;
     INITIAL_SUPPLY = _initialSupply;
     decimals = _decimals;
     token.init(INITIAL_SUPPLY);
     token.transfer(_owner, _initialSupply);
   }

   function totalSupply() constant returns (uint) {
     return token.totalSupply;
   }

   function balanceOf(address who) constant returns (uint) {
     return token.balanceOf(who);
   }

   function allowance(address owner, address spender) constant returns (uint) {
     return token.allowance(owner, spender);
   }

   function transfer(address to, uint value) returns (bool ok) {
     return token.transfer(to, value);
   }

   function transferFrom(address from, address to, uint value) returns (bool ok) {
     return token.transferFrom(from, to, value);
   }

   function approve(address spender, uint value) returns (bool ok) {
     return token.approve(spender, value);
   }
 }
