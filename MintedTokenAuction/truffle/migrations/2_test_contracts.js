var BasicMathLib = artifacts.require("./BasicMathLib.sol");
var ArrayUtilsLib = artifacts.require("./ArrayUtilsLib.sol");
var ERC20Lib = artifacts.require("./ERC20Lib.sol");
var StandardToken = artifacts.require("./StandardToken.sol");
var MintedTokenAuctionTest = artifacts.require("./MintedTokenAuctionTest.sol");
var MintedTokenAuction = artifacts.require("./MintedTokenAuction.sol");

module.exports = function(deployer, network) {
  deployer.deploy(BasicMathLib,{overwrite: false});
  deployer.link(BasicMathLib, ArrayUtilsLib);
  deployer.deploy(ArrayUtilsLib,{overwrite: false});
  deployer.link(BasicMathLib, ERC20Lib);
  deployer.deploy(ERC20Lib,{overwrite: false});
  deployer.link(BasicMathLib, MintedTokenAuctionTest);
  deployer.link(ArrayUtilsLib, MintedTokenAuctionTest);
  deployer.link(ERC20Lib, MintedTokenAuctionTest);
  deployer.link(ERC20Lib, StandardToken);
};
