MintedTokenAuction
=========================

An auction contract [provided by Majoolr](https://github.com/Majoolr "Majoolr's Github") and developed alongside the StandardICOAuction contract for standard tokens that have already been minted. This contract allows for open bidding for 30 days followed by a random(ish) selection process that decides which bidders will participate if the auction is oversubscribed. If the auction is not oversubscribed then the contract will issue tokens to all bidders. Auction creators will also set a minimum number of tokens to sell that, if not met, will refund all bid money. This contract has some of the following characteristics:

*Creators set a minimum number and maximum number of tokens to sell
*Only one bid allowed per account

   All of us in the community understand that it is easy to create and bid from multiple accounts, see the discussion below for tracking multiple bids.

*Creators will set a minimum bid amount for each bid
*Creators set a high price per token, low price per token, and a price increment

   The contract will use this information to create an array of price points each bidder should choose from when they submit a bid.

*This contact will select a token price based on the reverse Dutch Auction format

   When the auction is over, the contract's logic will calculate total bids starting from the highest price per token and then move down each price point until the raise cap is reached. The contract sets that point as the best price per token and all bidders who picked that point or higher will be included in the selection process and all bidders that picked a lower price will be able to redeem their bid deposit. From there, each winning bidder will receive a number of tokens calculated as totalBid/bestPrice.

   If the auction is not oversubscribed then the lowest price will be selected and all bidders will be issued tokens at that price. Again, if the minimum raise is not met then no tokens will be issued and all bidders will receive their bid deposit.

*Creators will determine the number of tokens to sell out of their supply.

*Creators set the starttime by submitting a future timestamp value and the endtime will be calculated as 30 days after that.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [License and Warranty](#license-and-warranty)
- [How to deploy and test](#how-to-deploy-and-test)
  - [Truffle Deployment](#truffle-deployment)
    - [Deployer Setup:](#deployer-setup)
    - [Testing the contract in truffle](#testing-the-contract-in-truffle)
- [Other Compilation Methods](#other-compilation-methods)
  - [solc Compilation](#solc-compilation)
    - [With standard JSON input](#with-standard-json-input)
    - [solc without standard JSON input](#solc-without-standard-json-input)
    - [solc documentation](#solc-documentation)
  - [solc-js Compilation](#solc-js-compilation)
    - [Solc-js Compilation via Linking](#solc-js-compilation-via-linking)
    - [Solc-js documentation](#solc-js-documentation)
    - [Deploying Compiled Bytecode](#deploying-compiled-bytecode)
    - [Deployment Gas](#deployment-gas)
    - [Bottom Line](#bottom-line)
- [Auction Process](#auction-process)
  - [MintedTokenAuction Constructor](#mintedtokenauction-constructor)
    - [*adress* _token](#adress-_token)
    - [*uint256* _numberOfTokens](#uint256-_numberoftokens)
    - [*uint256* _minimumBid](#uint256-_minimumbid)
    - [*uint256* _highTokenPrice](#uint256-_hightokenprice)
    - [*uint256* _lowTokenPrice](#uint256-_lowtokenprice)
    - [*uint256* _priceIncrement](#uint256-_priceincrement)
    - [*uint256* _startTime](#uint256-_starttime)
  - [During the Auction](#during-the-auction)
    - [Bid Example](#bid-example)
  - [After The Auction](#after-the-auction)
    - [processAuction function](#processauction-function)
      - [*string* _seed](#string-_seed)
    - [Funding Tokens](#funding-tokens)
    - [Withdrawing](#withdrawing)
      - [Failed Bids](#failed-bids)
- [Conclusion](#conclusion)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## License and Warranty

Be advised that while we strive to provide professional grade, tested code we cannot
guarantee its fitness for your application. This is released under [The MIT License (MIT)](https://github.com/Majoolr/ethereum-contracts/blob/master/LICENSE "MIT License")
and as such we will not be held liable for lost funds, etc. Please use your best
judgment and note the following:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## How to deploy and test

The MintedTokenAuction contract uses three libraries built by Majoolr and a standard token contract.

In order to use the MintedTokenAuction contract do the following:

1. [Install BasicMathLib](https://github.com/Majoolr/ethereum-libraries/tree/master/BasicMathLib "BasicMathLib link") .
2. [Install ArrayUtilsLib](https://github.com/Majoolr/ethereum-libraries/tree/master/ArrayUtilsLib "ArrayUtilsLib link") .
3. [Install ERC20Lib](https://github.com/Majoolr/ethereum-libraries/tree/master/ERC20Lib "ERC20Lib link") .
4. Put this MintedTokenAuction contract in your project.

Each library has its own README with instructions, detailed explanations, and compilation instructions.

### Truffle Deployment

**version 3.3.0**

If you haven't done this prior to setting up the earlier dependencies:

First install truffle via npm using `npm install -g truffle` .

Please [visit Truffle's installation guide](http://truffleframework.com/docs/getting_started/installation "Truffle installation guide") for further information and requirements.

#### Deployer Setup:

This assumes you went through the earlier steps and now have the library artifact .json files in your build/contracts folder and all contracts in your contracts folder.

Place the `2_deploy_auction.js` file into the migrations folder of your project. If there are any other migration files being used be sure the number prefix is unique and in order.

#### Testing the contract in truffle

The following process will allow you to `truffle test` this library in your project.

1. `git clone --recursive` or download the truffle directory.
   Each folder in the truffle directory correlates to the folders in your truffle installation.
2. Place each file in their respective directory in **your** truffle project.
   **Note**: The `2_test_contracts.js` file should either be renamed to the next highest number among your migrations files i.e. `3_deploy_test_contracts.js` or you can place the code in your existing deployment migration file. *See Quick Install above.*
3. [Start a testrpc node](https://github.com/ethereumjs/testrpc "testrpc's Github")

   **Note**: The tests are written using Truffle's awesome truffle testing mechanisms and they are gas hungry. When starting your testrpc node be sure to set the gas and starting ether options high to allow for consumption. For example:

   ```
   $ testrpc --gasLimit 0xffffffffffffffffffffffffffffffffffffff --account="0xfacec5711eb0a84bbd13b9782df26083fc68cf41b2210681e4d478687368fdc3,1000000000000000000000000000000000000000000"
   ```

   Additionally you need to set the caller's gas limit high enough as well. This is done in the truffle.js file and it should look like this:

   ```js
    //imports and such
    ...
    module.exports = {
      networks: {
         development: {
           host: "localhost",
           port: 8545,
           gas: 4700000000000000, //This is the important line
           network_id: "*",
         },
         ...
         //other network configurations
       }
    }
   ```
4. In your terminal go to your truffle project directory and run `truffle migrate`.
5. After migration run `truffle test`.

## Other Compilation Methods

### solc Compilation

**version 0.4.11**

For direction and instructions on how the Solidity command line compiler works [see the documentation](https://solidity.readthedocs.io/en/develop/using-the-compiler.html#using-the-commandline-compiler "Solc CLI Doc").



#### With standard JSON input

[The Standard JSON Input](https://solidity.readthedocs.io/en/develop/using-the-compiler.html#input-description "Standard JSON Input") provides an easy interface to include libraries. Include the following as part of your JSON input file:

```json
{
  "language": "Solidity",
  "sources":
  {
    "MintedTokenAuction.sol": {
      "content": "[Contents of MintedTokenAuction.sol]"
    },
    "BasicMathLib.sol": {
      "content": "[Contents of BasicMathLib.sol]"
    },
    "ArrayUtilsLib.sol": {
      "content": "[Contents of ArrayUtilsLib.sol]"
    },
    "ERC20Lib.sol": {
      "content": "[Contents of ERC20Lib.sol]"
    }
  },
  "settings":
  {
    ...
    "libraries": {
      "ArrayUtilsLib.sol": {
        "BasicMathLib" : "0x3e25cde3fb9c93e4c617fe91c8c0d6720c87d61e"
      },
      "ERC20Lib.sol": {
        "BasicMathLib" : "0x3e25cde3fb9c93e4c617fe91c8c0d6720c87d61e"
      },
      "MintedTokenAuction.sol": {
        "BasicMathLib" : "0x3e25cde3fb9c93e4c617fe91c8c0d6720c87d61e",
        "ArrayUtilsLib": "0xf44ab905eba847774848c43735c8ec7d0530956f",
        "ERC20Lib": "0x71ecde7c4b184558e8dba60d9f323d7a87411946"
      },
    }
    ...
  }
}
```
**Note**: The library name should match the name used in your contract.

#### solc without standard JSON input

When creating unlinked binary, the compiler currently leaves special substrings in the compiled bytecode in the form of '__LibraryName______' which leaves a 20 byte space for the library's address. In order to include the deployed libraries in your bytecode, you can create a file with one library string per line and include this library as follows:

```
"BasicMathLib:0x3e25cde3fb9c93e4c617fe91c8c0d6720c87d61e"
"ArrayUtilsLib:0xf44ab905eba847774848c43735c8ec7d0530956f"
"ERC20Lib:0x71ecde7c4b184558e8dba60d9f323d7a87411946"
```

then add the following flag to your command:

`--libraries filename`

Finally, if you have an unlinked binary already stored with the '__LibraryName______' placeholder, you can run the compiler with the --link flag and also include the following flag:

`--libraries "BasicMathLib:0x3e25cde3fb9c93e4c617fe91c8c0d6720c87d61e ArrayUtilsLib:0xf44ab905eba847774848c43735c8ec7d0530956f  ERC20Lib:0x71ecde7c4b184558e8dba60d9f323d7a87411946"`

#### solc documentation

[See the solc documentation for further information](https://solidity.readthedocs.io/en/develop/using-the-compiler.html#using-the-commandline-compiler "Solc CLI Doc").

### solc-js Compilation

**version 0.4.11**

Solc-js provides javascript bindings for the Solidity compiler and [can be found here](https://github.com/ethereum/solc-js "Solc-js compiler"). Please refer to their documentation for detailed use.

This version of Solc-js also uses the [standard JSON input](#with-standard-json-input) to compile a contract. The entry function is `compileStandardWrapper()` and you can create a standard JSON object explained under the [solc section](#with-standard-json-input) and incorporate it as follows:

```js
var solc = require('solc');
var fs = require('fs');

var auction = fs.readFileSync('/path/to/MintedTokenAuction.sol','utf8');
var basicMathLib = fs.readFileSync('./path/to/BasicMathLib.sol','utf8');
var arrayLib = fs.readFileSync('./path/to/ArrayUtilsLib.sol','utf8');
var ERC20Lib = fs.readFileSync('./path/to/ERC20Lib.sol','utf8');

var input = {
  "language": "Solidity",
  "sources":
  {
    "MintedTokenAuction.sol": {
      "content": auction
    },
    "BasicMathLib.sol": {
      "content": basicMathLib
    },
    "ArrayUtilsLib.sol": {
      "content": arrayLib
    },
    "ERC20Lib.sol": {
      "content": ERC20Lib
    }
  },
  "settings":
  {
    ...
    "libraries": {
      "ArrayUtilsLib.sol": {
        "BasicMathLib" : "0x3e25cde3fb9c93e4c617fe91c8c0d6720c87d61e"
      },
      "ERC20Lib.sol": {
        "BasicMathLib" : "0x3e25cde3fb9c93e4c617fe91c8c0d6720c87d61e"
      },
      "MintedTokenAuction.sol": {
        "BasicMathLib" : "0x3e25cde3fb9c93e4c617fe91c8c0d6720c87d61e",
        "ArrayUtilsLib": "0xf44ab905eba847774848c43735c8ec7d0530956f",
        "ERC20Lib": "0x71ecde7c4b184558e8dba60d9f323d7a87411946"
      },
    }
    ...
  }
}

var output = JSON.parse(solc.compileStandardWrapper(JSON.stringify(input)));

//Where the output variable is a standard JSON output object.
```

#### Solc-js Compilation via Linking

Solc-js also provides a linking method if you have compiled binary code already with the placeholder. To link this library the call would be:

 ```js
 bytecode = solc.linkBytecode(bytecode, {
                "BasicMathLib" : "0x3e25cde3fb9c93e4c617fe91c8c0d6720c87d61e",
                "ArrayUtilsLib": "0xf44ab905eba847774848c43735c8ec7d0530956f",
                "ERC20Lib": "0x71ecde7c4b184558e8dba60d9f323d7a87411946"

            });
 ```

#### Solc-js documentation

[See the Solc-js documentation for further information](https://github.com/ethereum/solc-js "Solc-js compiler").

#### Deploying Compiled Bytecode

Once you have the contract compiled you can then deploy the contract using web3 as follows

```js
var abi = [YourAuctionContractsabi];
var bytecode = YourAuctionContractsbytecode;
var YourAuctionContract = web3.eth.contract(abi);
var deployedInstance = YourAuctionContract.new(allConstructorArguments,{
    data: '0x' + bytecode,
    from: yourAddress
});
```

#### Deployment Gas

The deployment gas cost appears to be around 3.5 million gas.

#### Bottom Line

Know the process, then use Truffle.

## Auction Process

### MintedTokenAuction Constructor

The contact constructor is as follows:
```
function MintedTokenAuction(address _token,
                    uint256 _numberOfTokens,
                    uint256 _minimumTokensToSell,
                    uint256 _minimumBid,
                    uint256 _highTokenPrice,
                    uint256 _lowTokenPrice,
                    uint256 _priceIncrement,
                    uint256 _startTime)
```
#### *adress* _token

The address of the deployed standard token

#### *uint256* _numberOfTokens

The number of tokens to auction

Required to be greater than creator's balance.

#### *uint256* _minimumBid

The minimum bid required from each bidder. If each bid should be at least 1 ETH then this would be 1000000000000000000.

Required to be greater than zero.

#### *uint256* _highTokenPrice

The highest price per token. If the top price for a token is .5 ETH then this would be 500000000000000000.

Required to be greater than _lowTokenPrice.

#### *uint256* _lowTokenPrice

The lowest price per token. If the bottom price is .1 ETH then this would be 100000000000000000.

Required to be greater than zero.

#### *uint256* _priceIncrement

The incremental prices between high and low token price. If it is defined as .1 ETH, then the auction would have 5 price points for the tokens generated as `[.1,.2,.3,.4,.5]` in the defined units. In this case, wei.

Required to be greater than zero.

#### *uint256* _startTime

The future timestamp of the auction start. The auction will end 30 days after this point.

Required to be a future time.

### During the Auction

During the auction bidders will call the `deposit(_tokenPrice)` function to submit a bid.

If the bid does not meet requirements the contract **will not** generate an EVM exception and revert the deposit. It will send an error message to notify the bidder of the problem and then place the deposit in a `failedDeposit` map. Bidders should then retrieve their deposit by calling `getFailedDeposit()`. This allows descriptive errors for your bidders. Bidders should watch for the `ErrorMsg()` filtered by their address to see any errors.

The following requirements must be met:

   *It must be during auction time
   *The account must not have a previousy accepted bid
   *The _tokenPrice must be an integer listed in the price point array
   *The bid value must meet the minimum bid requirements
   *The bid value must be equal or greater than the submitted _tokenPrice

#### Bid Example

In the previous example auction, a bidder would submit a bid as follows:

```
//Bidder bids .5 ETH at .1 ETH per token
DeployedICOAuctionContract.deposit(100000000000000000,{from: eth.accounts[0], value: web3.toWei(.5, 'ether'), gas: 500000, gasPrice: web3.toWei(30,'gwei')});
```

### After The Auction

#### processAuction function
Once the auction completes, the contract creators will call the `processAuction(_seed)` function. The parameters are as follows:

##### *string* _seed

The string used to generate a hash for token selection.

   **Note**: While this does not produce complete randomness, the seed provides a hashing start point for the bidder selection process. The function combines the string with the block miner's address to produce a hash. This leaves most of the hash generating control in the hands of the auction creators but this should not be a conflict of interest because it is the auction creators who chose this auction process.

This function will determine whether or not the offering is over subscribed and, if so, calculates the highest price at which the auction is full. All bidders at or above this price will pay this price and be part of the selection process. All bidders below this price will have their deposits released and will not participate.

If the auction is not full, then it will generate tokens at the lowest price point and prepare to distribute them to all bidders. If the auction did not meet the minimum raise then all bids will be released and no tokens generated.

#### Funding Tokens
After the auction has been processed, the creators will call the `fundTokens()` method. This method accepts no arguments and recursively sends the deposits to the auction creators and distributes tokens until either all tokens are distributed in the case of a full auction or all bidders have received tokens otherwise. If the minimum was not met this function will do nothing.

The function keeps track of gas remaining during each loop and, if gas is running low, it will save state and return `false`. The auction creators will need to keep calling this method until it returns `true`.

#### Withdrawing
There are two withdraw methods, `withdrawTokens()` and `withdrawDeposit()`. When a bidder has been funded with tokens they can call the `withdrawTokens()` function at any point to retrieve their tokens. When a bidder has bid lower than the selected best token price, their funds will be released and they can call `withdrawDeposit()` to retrieve their bid.

Thirty days after the auction has ended, all deposits will automatically be released for withdraw. This would be in the case that the auction creator has taken no action and funds are locked up.

##### Failed Bids
Any bids that failed DURING the bid process will be available for immediate withdraw using the `getFailedDeposit()` function. This is only to catch bids that did not meet bidding requirements.

## Conclusion
This process was brought up in [this reddit post](https://www.reddit.com/r/ethereum/comments/6iwyta/the_ico_contract_to_end_all_of_the_nonsense/ "Reddit post") in the wake of the Status ICO and suggesting a way to separate the bidding process from distribution. This was a natural development next to the StandardICOAuction and could have many market auctioning implications.
