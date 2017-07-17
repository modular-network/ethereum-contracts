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
  if(network !== "live"){
    deployer.link(BasicMathLib, MintedTokenAuctionTest);
    deployer.link(ArrayUtilsLib, MintedTokenAuctionTest);
    deployer.link(ERC20Lib, MintedTokenAuctionTest);
    deployer.link(ERC20Lib, StandardToken);
    if(network == "rinkeby") {
      var d = new Date().valueOf();
      d = (d-5000)/1000;
      deployer.deploy(StandardToken).then(function() {
        return deployer.deploy(MintedTokenAuctionTest, StandardToken.address,
                                10000000000000000000000000,
                                5000000000000000000000000,
                                1000000000000000000,
                                web3.toWei(10,'finney'),
                                web3.toWei(1,'finney'),
                                web3.toWei(1,'finney'),
                                d);
      });
    }
  } else {
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
