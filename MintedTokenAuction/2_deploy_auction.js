var BasicMathLib = artifacts.require("./BasicMathLib.sol");
var ArrayUtilsLib = artifacts.require("./ArrayUtilsLib.sol");
var ERC20Lib = artifacts.require("./ERC20Lib.sol");
var MintedTokenAuction = artifacts.require("./MintedTokenAuction.sol");

module.exports = function(deployer, network) {
  deployer.deploy(BasicMathLib,{overwrite: false});
  deployer.link(BasicMathLib, ArrayUtilsLib);
  deployer.deploy(ArrayUtilsLib,{overwrite: false});
  deployer.link(BasicMathLib, ERC20Lib);
  deployer.deploy(ERC20Lib,{overwrite: false});
  deployer.link(BasicMathLib, MintedTokenAuction);
  deployer.link(ArrayUtilsLib, MintedTokenAuction);
  deployer.link(ERC20Lib, MintedTokenAuction);
/*  Set constructor to desired parameters and uncomment when ready to go live
    var d = new Date().valueOf();
    d = (d+5000000)/1000;
    deployer.deploy(MintedTokenAuctionTest, [Need token address],
                    10000000000000000000000000,
                    5000000000000000000000000,
                    1000000000000000000,
                    web3.toWei(10,'finney'),
                    web3.toWei(1,'finney'),
                    web3.toWei(1,'finney'),
                    d);
*/
  }
};
