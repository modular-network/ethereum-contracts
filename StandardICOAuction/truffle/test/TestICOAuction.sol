pragma solidity ^0.4.11;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/StandardICOAuction.sol";
import "../contracts/ICOAuctionTestContract.sol";

contract TestICOAuction{
  event Number(uint n);
  uint public initialBalance = 200000 ether;
  ICOAuctionTestContract instance;
  ICOAuctionTestContract instanceUnderSubscribed;
  ICOAuctionTestContract instanceOverSubscribed;
  StandardICOAuction testConstruct;
  ICOAuctionStandardToken testToken;
  uint256[] expectedPricePoints;
  uint256[] tokenPricePoints;
  bool bResult;
  uint expected;
  uint result;

  //10 ether standard test deposit
  uint256 deposit = 10000000000000000000;
  //2 finney standard test bid price
  uint256 price = 2000000000000000;
  //Timestamp for standard test deposit time
  uint256 testTime = 1499886409;
  //Name for generated test ERC20 token
  string name = "Test token";
  //Ticker for generated test token
  string ticker = "TEST";
  //Not used for this auction, but required parameter
  string seed = "Seed";
  //Expected best token price, should be lowest price if auction not oversubscribed
  uint256 expectedPrice = 1000000000000000;
  //Index of price in tokenPricePoints array
  uint256 expectedIndex = 0;
  //All token supply with 90% being auctioned
  uint256 expectedInitialSupply = 11111112000000000000000000;
  //90% of token supply being auctioned, 10,000 ether cap at 1 finney per token
  uint256 expectedAuctionSupply = 10000000000000000000000000;
  //Used only for oversubscribed auction
  uint256 expectedBytes = 0;
  uint256 expectedDivisor = 0;
  //Cap amount left should equal cap amount minus all bids, 2,000 ether
  //initially populated and 10 ether bid in test
  uint256 expectedCapLeft = 5990000000000000000000;
  //Tokens available for withdraw after auction should be auction supply minus
  //tokens left over
  uint256 expectedTokensAvail = 4010000000000000000000000;

  function() payable {}

  function beforeAll(){
    uint256 d = 1499886309;
    uint256 _price;
    uint256 depositValue;
    instance = new ICOAuctionTestContract(10000000000000000000000, //Auction cap 10,000 ether
                                          1000000000000000000000, //Minimum target raise 1,000 ether
                                          10000000000000000000, //Minimum bid allowed 10 ether
                                          10000000000000000, //Highest price/token 10 finney
                                          1000000000000000, //Lowest price/token 1 finney
                                          1000000000000000, //Generate price in 1 finney increments
                                          18, //Generated ERC20 token goes to 18 decimals
                                          90, //90% of total token supply auctioned
                                          d); //Auction start timestamp

//Generate 2 200 ether bids at each price point, auction finishes between min and max
    for(uint256 i = 0; i<2; i++){
      for(uint256 z = 1; z<11; z++){
        depositValue = 200000000000000000000;
        _price = z * (10**15);
        instance.deposit.value(depositValue)(_price, testTime);
      }
    }

    instanceOverSubscribed = new ICOAuctionTestContract(10000000000000000000000,
                                                        1000000000000000000000,
                                                        10000000000000000000,
                                                        10000000000000000,
                                                        1000000000000000,
                                                        1000000000000000,
                                                        18,
                                                        90,
                                                        d);
//Generate 2 100 ether bids at each price point except one 9,900 ether bid at 7 finney
    for(i = 0; i<2; i++){
      for(z = 1; z<11; z++){
        if(z==7 && i==1)
          depositValue = 9900000000000000000000;
        else
          depositValue = 100000000000000000000;
        _price = z * (10**15);
        instanceOverSubscribed.deposit.value(depositValue)(_price, testTime);
      }
    }

    instanceUnderSubscribed = new ICOAuctionTestContract(10000000000000000000000,
                                                         1000000000000000000000,
                                                         10000000000000000000,
                                                         10000000000000000,
                                                         1000000000000000,
                                                         1000000000000000,
                                                         18,
                                                         90,
                                                         d);
//Generate 1 50 ether bid at each price point
    for(z = 1; z<11; z++){
      depositValue = 50000000000000000000;
      _price = z * (10**15);
      instanceUnderSubscribed.deposit.value(depositValue)(_price, testTime);
    }
  }

  function testInputConditions(){
    uint256 i;
    uint256 _capAmount = instance.capAmount();
    uint256 _minimumTargetRaise = instance.minimumTargetRaise();
    uint256 _minimumBid = instance.minimumBid();
    uint256 _highTokenPrice = 10000000000000000;
    uint256 _lowTokenPrice =  1000000000000000;
    uint256 _priceIncrement = 1000000000000000;
    uint256 _decimals = instance.decimals();
    for(i = _lowTokenPrice; i<=_highTokenPrice; i += _priceIncrement){
      expectedPricePoints.push(i);
    }
    for(i = 0; i<expectedPricePoints.length; i++){
      tokenPricePoints.push(instance.tokenPricePoints(i));
    }
    uint256 _percentAuctioned = instance.percentOfTokensAuctioned();

    Assert.equal(_capAmount,10000000000000000000000, "The auction cap should equal 10,000 ether");
    Assert.equal(_minimumTargetRaise,1000000000000000000000, "The minimum target raise should equal 1,000 ether");
    Assert.equal(_minimumBid, 10000000000000000000, "The minimum bid should be 10 ether");
    Assert.equal(tokenPricePoints, expectedPricePoints, "The price point array should be calculated from 1 finney to 10 finney in 1 finney increments");
    Assert.equal(_decimals, 18, "The contract should store the decimals variable for ERC20 token");
    Assert.equal(_percentAuctioned, 90, "The percentage of total initial token supply available for auction should be 90 percent");
  }

  function testDepositFunctionTime() {
    uint256 _testTime = 1499886209; //Time before auction start
    bResult = instance.deposit.value(deposit)(price, _testTime);

    Assert.isFalse(bResult, "Deposit should be rejected prior to auction start");
  }

  function testDepositFunctionBadPrice() {
    uint256 _price = 200000000000000; //Missing a zero, 200 micro instead of 2 finney
    bResult = instance.deposit.value(deposit)(_price, testTime);
    uint256 balance = this.balance;

    uint256 failedDeposit = instance.failedDeposit(this);
    instance.getFailedDeposit();
    uint256 newBalance = this.balance;

    Assert.isFalse(bResult, "Deposit should be rejected if requested token price not listed");
    Assert.equal(newBalance - balance, deposit, "Failed deposit should be available and returned through getFailedDeposit()");
  }

  function testDepositFunctionBelowMin() {
    uint256 _deposit = 1000000000000000000; //1 ether deposit below min
    bResult = instance.deposit.value(_deposit)(price, testTime);

    Assert.isFalse(bResult, "Deposit should be rejected if below minimum bid");
  }

  function testDepositFunctionAccepted() {
    address bidder;
    uint256 totalBid;
    bResult = instance.deposit.value(deposit)(price, testTime);

    uint256 priceLocation = instance.bidLocation(this, 0);
    uint256 indexLocation = instance.bidLocation(this, 1);
    (bidder, totalBid) = instance.bids(priceLocation, indexLocation);

    Assert.isTrue(bResult, "Function should return true if deposit accepted");
    Assert.equal(totalBid, deposit, "Deposit should be recorded in bids, bid location in bidLocation");
    Assert.equal(bidder, this, "Bidder should be recorded in bids with deposit");
  }

  function testProcessAuctionTooEarly() {
    bResult = instance.processAuction(name, ticker, seed, testTime);

    Assert.isFalse(bResult, "Function should return false if processAuction is called before auction end");
  }

  function testFundTokensTooEarly() {
    bResult = instance.fundTokens();

    Assert.isFalse(bResult, "Function should return false because tokens have not been generated");
  }

  function testProcessAuction() {
    uint256 _testTime = testTime + 2592060; //Add 30 days and one minute to pass end of auction
    instance.processAuction(name, ticker, seed, _testTime);
    uint256 bestPrice = instance.bestPrice();
    uint256 bpIndex = instance.bpIndex();
    bool fundAll = instance.fundAll();
    testToken = instance.token();
    uint256 initialSupply = testToken.INITIAL_SUPPLY();
    uint256 auctionSupply = instance.auctionSupply();
    uint256 numberOfBytes = instance.numberOfBytes();
    uint256 byteDivisor = instance.byteDivisor();

    Assert.equal(bestPrice, expectedPrice, "Best price should be lowest price when auction is not over subscribed");
    Assert.equal(bpIndex, expectedIndex, "The index of the best price should be the index of 1 finney");
    Assert.isTrue(fundAll, "The tokens should be provided to all bidders");
    Assert.equal(auctionSupply, expectedAuctionSupply, "The auction supply should be auction cap divided by best price");
    Assert.equal(initialSupply, expectedInitialSupply, "The initial total token supply should be calculated such that auction supply is 90% of total supply");
    Assert.equal(numberOfBytes, 0, "No random(ish) generator necessary for this auction");
    Assert.equal(byteDivisor, 0, "No random(ish) generator necessary for this auction");
  }

  function testProcessAuctionOverSubscribe() {
    uint256 _testTime = testTime + 2592060;
    instanceOverSubscribed.processAuction(name, ticker, seed, _testTime);
    uint256 bestPrice = instanceOverSubscribed.bestPrice();
    uint256 bpIndex = instanceOverSubscribed.bpIndex();
    bool fundAll = instanceOverSubscribed.fundAll();
    testToken = instanceOverSubscribed.token();
    uint256 initialSupply = testToken.INITIAL_SUPPLY();
    uint256 auctionSupply = instanceOverSubscribed.auctionSupply();
    uint256 numberOfBytes = instanceOverSubscribed.numberOfBytes();
    uint256 byteDivisor = instanceOverSubscribed.byteDivisor();

    Assert.equal(bestPrice, 7000000000000000, "Best price should be 7 finney");
    Assert.equal(bpIndex, 6, "The index of the best price should be the index of 7 finney");
    Assert.isFalse(fundAll, "Not everyone receives tokens when auction is oversubscribed");
    Assert.equal(auctionSupply, 1428572000000000000000000, "The auction supply should be auction cap divided by best price with decimals added");
    Assert.equal(initialSupply, 1587303000000000000000000, "The initial total token supply should be calculated such that auction supply is 90% of total supply");
    Assert.equal(numberOfBytes, 1, "The generator should use 1 byte for 8 possible bids");
    Assert.equal(byteDivisor, 32, "The generated byte should be divided by 32 for 8 possible bids");
  }

  function testProcessAuctionUnderFunded() {
    uint256 _testTime = testTime + 2592060;
    instanceUnderSubscribed.processAuction(name, ticker, seed, _testTime);
    for(uint i = 0; i<10; i++){
      bResult = instanceUnderSubscribed.allowWithdraw(i);
      Assert.isTrue(bResult, "All funds should be released if auction is underfunded");
    }

    uint256 auctionSupply = instanceUnderSubscribed.auctionSupply();

    Assert.equal(auctionSupply, 0, "There should be no supply generated if auction underfunded");
  }

  function testAllowWithdrawForLowBidders(){
    for(uint i = 0; i<6; i++){
      bResult = instanceOverSubscribed.allowWithdraw(i);
      Assert.isTrue(bResult, "Funds for inelligible low bidders should be released when oversubcribed, 6 finney and lower for this test");
    }

    for(i = 6; i<10; i++){
      bResult = instanceOverSubscribed.allowWithdraw(i);
      Assert.isFalse(bResult, "Funds for elligible bidders should be held until tokens funded");
    }
  }

  function testFundTokens() {
    bResult = instance.fundTokens();
    uint256 capLeft = instance.capAmount();
    bool allowRes;
    for(uint i = 0; i<10; i++){
      allowRes = instance.allowWithdraw(i);
      Assert.isTrue(allowRes, "All funds should be released after funding tokens");
    }

    Assert.isTrue(bResult,"The fund tokens function should return true");
    Assert.equal(capLeft, expectedCapLeft, "The raise cap should be reduced to leftover cap");
  }

  function testFundTokensOverSubscribe() {
    bResult = instanceOverSubscribed.fundTokens();
    uint256 cap = instanceOverSubscribed.capAmount();
    bool allowRes;
    for(uint i = 0; i<10; i++){
      allowRes = instanceOverSubscribed.allowWithdraw(i);
      Assert.isTrue(allowRes, "All funds should be released after funding tokens");
    }

    Assert.isTrue(bResult,"The fund tokens function should return true");
    Assert.equal(cap, 0, "The raise cap should be depleted after funding tokens");

  }

  function testWithdrawTokens(){
    uint256 tokensAvail = instance.withdrawTokensMap(this);
    //All tokens are in the same testing account
    uint256 beforeBalance = testToken.balanceOf(this) - tokensAvail;

    instance.withdrawTokens();
    uint256 tokensAfter = instance.withdrawTokensMap(this);
    uint256 tokenBalance = testToken.balanceOf(this);

    Assert.equal(tokensAvail,expectedTokensAvail,"All tokens should be in the withdraw map");
    Assert.equal(tokensAfter, 0, "The withdrawTokens function should reduce the withdraw map to 0");
    Assert.equal(tokenBalance, tokensAvail + beforeBalance, "Tokens should be transferred to bidder");
  }

  function testWithdrawDeposit(){
    address bidder;
    uint256 beforeDeposit;
    uint256 afterDeposit;
    uint256 _price = instanceOverSubscribed.bidLocation(this, 0);
    uint256 _index = instanceOverSubscribed.bidLocation(this, 1);
    uint256 beforeBalance = this.balance;
    (bidder, beforeDeposit) = instanceOverSubscribed.bids(_price, _index);
    instanceOverSubscribed.withdrawDeposit(testTime);
    uint256 afterBalance = this.balance;
    (bidder, afterDeposit) = instanceOverSubscribed.bids(_price, _index);

    Assert.equal(afterBalance, beforeBalance + beforeDeposit, "The withdrawDeposit function should return the balance to the bidder");
    Assert.equal(afterDeposit, 0, "There should be no deposit remaining after calling the withdrawDeposit function");
  }

  //The time test in the standard contract around line 154 needs to be commented
  //out to test this function, this tests denying more than one bid from an account
  /*
    function testDepositFunctionDenyBid(){
      //Test multiple bid denial mechanisim in standard contract
      address testDeploy = new StandardICOAuction(10000000000000000000000, 1000000000000000000000, 10000000000000000000, 10000000000000000, 1000000000000000, 1000000000000000, 90, t);
      testConstruct = StandardICOAuction(testDeploy);

      bResult = testConstruct.deposit.value(10000000000000000000)(2000000000000000);
      bResult = testConstruct.deposit.value(10000000000000000000)(3000000000000000);

      Assert.isFalse(bResult, "Deposit should be rejected if already bid");
    }
  */
}
