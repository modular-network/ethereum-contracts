var BasicMathLib = artifacts.require("./BasicMathLib.sol");
var ArrayUtilsLib = artifacts.require("./ArrayUtilsLib.sol");
var ERC20Lib = artifacts.require("./ERC20Lib.sol");
var ICOAuctionTestContract = artifacts.require("./ICOAuctionTestContract.sol");
var StandardICOAuction = artifacts.require("./StandardICOAuction.sol");

module.exports = function(deployer, network) {
  deployer.deploy(BasicMathLib,{overwrite: false});
  deployer.link(BasicMathLib, ArrayUtilsLib);
  deployer.deploy(ArrayUtilsLib,{overwrite: false});
  deployer.link(BasicMathLib, ERC20Lib);
  deployer.deploy(ERC20Lib,{overwrite: false});
  deployer.link(BasicMathLib, ICOAuctionTestContract);
  deployer.link(ArrayUtilsLib, ICOAuctionTestContract);
  deployer.link(ERC20Lib, ICOAuctionTestContract);
};
