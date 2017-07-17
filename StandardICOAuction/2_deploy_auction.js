var BasicMathLib = artifacts.require("./BasicMathLib.sol");
var ArrayUtilsLib = artifacts.require("./ArrayUtilsLib.sol");
var ERC20Lib = artifacts.require("./ERC20Lib.sol");
var StandardICOAuction = artifacts.require("./StandardICOAuction.sol");

module.exports = function(deployer, network) {
  deployer.deploy(BasicMathLib,{overwrite: false});
  deployer.link(BasicMathLib, ArrayUtilsLib);
  deployer.deploy(ArrayUtilsLib,{overwrite: false});
  deployer.link(BasicMathLib, ERC20Lib);
  deployer.deploy(ERC20Lib,{overwrite: false});
  deployer.link(BasicMathLib, StandardICOAuction);
  deployer.link(ArrayUtilsLib, StandardICOAuction);
  deployer.link(ERC20Lib, StandardICOAuction);
/*  Set constructor to desired parameters and uncomment when ready to go live
    var d = new Date().valueOf();
    d = (d+5000000)/1000; <--Javascript timestamp is in milliseconds, Ethereum is
    in seconds, set d to the future timestamp you wish to start the auction
    deployer.deploy(StandardICOAuction, web3.toWei(10000,'ether'),
                    web3.toWei(1000,'ether'), web3.toWei(10,'ether'),
                    web3.toWei(10,'finney'), web3.toWei(1,'finney'),
                    web3.toWei(1,'finney'), 18, 90, d);
*/
  }
};
