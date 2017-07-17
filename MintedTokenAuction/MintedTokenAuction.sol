pragma solidity ^0.4.11;

import "./BasicMathLib.sol";
import "./ArrayUtilsLib.sol";
import "./StandardToken.sol";

/**
 * @title Minted Token ICO Auction Contract w/Random Bid Selection
 * @author Hackdom
 * @dev https://majoolr.io
 *
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * Majoolr works on open source projects in the Ethereum community with the
 * purpose of testing, documenting, and deploying reusable code onto the
 * blockchain to improve security and usability of smart contracts. Majoolr
 * also strives to educate non-profits, schools, and other community members
 * about the application of blockchain technology.
 * For further information: majoolr.io
 *
 * This provides the same functionality as the StandardICOAuction contract
 * except it does not generate an ERC20 token. A currently deployed ERC20
 * standard token contract is provided in the constructor and that token
 * will be auctioned in this contract.
 */

contract MintedTokenAuction {
  event Number(uint256 n);
  using ArrayUtilsLib for uint256[];
  using BasicMathLib for uint256;

  address public owner;
  StandardToken public token;

  struct Bid {
    address bidder;
    uint256 totalBid;
  }

  mapping (uint256 => Bid[]) public bids; //Maps each price point to an array of bids at that price
  mapping (address => uint256[2]) public bidLocation; //Maps bidder address to location in bids

  uint256 public minimumTokensToSell; //Minimum amount acceptable for successful auction
  uint256 public percentOfTokensAuctioned; //How much of token supply available in auction
  uint256 public auctionSupply; //Token initial supply times percentOfTokensAuctioned
  uint256 public decimals; //Number of zeros to add to token supply, usually 18
  uint256 public minimumBid; //Lowest acceptable bid
  uint256 public startTime; //ICO start time, timestamp
  uint256 public endTime; //ICO end time, timestamp automatically calculated
  uint256 public bestPrice; //Will store the price everyone will pay after moving down price points
  uint256 public bpIndex; //Array index of the best price in the price point array, stored to reduce calculation gas
  uint256 public totalEligibleBids; //Total bids at or above the calculated best price
  uint256[] public tokenPricePoints; //List of token price points
  uint256[] public bidAmount; //Running count revenue raised for each price point
  uint256[] public endIndex; //Used to calculate winning bid index across all eligible price point lists
  bool[] public allowWithdraw; //Trigger for allowing ether refund in each target price bucket
  bool public fundAll; //True if amount raised is between minimum target and cap
  bool public cancelAuction; //True if minimum not met after auction over

  mapping (address => uint) public withdrawTokensMap; //For token withdraw function
  mapping (address => uint256) public failedDeposit; //Catch for failed deposits, allows descriptive ErrorMsg

  uint256 public numberOfBytes; //Used for random number generation
  uint256 public byteDivisor; //Also used for random number selection
  bytes32 hashCode; //Stored hash which we derive winning bidder from

  event Deposit(address indexed _bidder, uint256 Amount, uint256 TokenPrice);

  //Events fired during random selection process, can comment out to reduce gas
  event BidSelected(address indexed _bidder, bool Success);
  event BidderPB(uint256 PriceBucket);
  event BidderBI(uint256 BucketIndex);
  event BidderTB(uint256 TotalBid);
  event BidderFQ(uint256 FilledQuantity);
  event BidderFT(uint256 FilledTotal);
  event AuctionSL(uint256 AuctionSupplyLeft);

  event TokensWithdrawn(address indexed _bidder, uint256 Amount);
  event DepositWithdrawn(address indexed _bidder, uint256 Amount);
  event NoticeMsg(address indexed _from, string Msg);
  event ErrorMsg(address indexed _from, string Msg);

  modifier andIsOwner {
    require(msg.sender == owner);
    _;
  }

  //Fallback function, not payable, sends message if executed
  function(){ ErrorMsg(msg.sender, "Provided inputs invalid bid rejected"); }

  /// @dev Constructor for auction contract
  /// @param _token Address of token being auctioned
  /// @param _numberOfTokens Number of tokens being auctioned, without decimal
  /// zeros, ie if 18 decimals and auctioning 10 just put 10,
  /// do NOT put 10000000000000000000
  /// @param _minimumTokensToSell The minimum acceptable raise amount, will
  /// allow withdrawals and cancel auction if not met
  /// @param _minimumBid The lowest acceptable total bid
  /// @param _highTokenPrice The highest token price per token
  /// @param _lowTokenPrice The lowest token price per token
  /// @param _priceIncrement Price increment between each price point, will
  /// determine the number of price points
  /// @param _startTime The timestamp of the auction start time
  function MintedTokenAuction(address _token,
                      uint256 _numberOfTokens,
                      uint256 _minimumTokensToSell,
                      uint256 _minimumBid,
                      uint256 _highTokenPrice,
                      uint256 _lowTokenPrice,
                      uint256 _priceIncrement,
                      uint256 _startTime)
  {
    uint256 _tokensAvail;

    token = StandardToken(_token);
    decimals = token.decimals();
    _tokensAvail = token.balanceOf(msg.sender);
    _tokensAvail = _tokensAvail/(10**decimals);

    bool err;
    uint256 res;
    (err, res) = _tokensAvail.minus(_numberOfTokens);

    require(_numberOfTokens > 0 && !err);
    require(_lowTokenPrice > 0 && _startTime > now);
    require(_minimumBid > 0 && _minimumTokensToSell > 0);
    require(_highTokenPrice > _lowTokenPrice && _priceIncrement > 0);

    //This ensures there are no overflow issues later with the number of tokens
    require((_tokensAvail * _highTokenPrice)<(11*10**(72-decimals)));

    err = !(token.approve(this, _numberOfTokens));
    require(!err);
    auctionSupply = _numberOfTokens * 10**decimals;

    for(uint256 i = _lowTokenPrice; i<=_highTokenPrice; i+=_priceIncrement){
      tokenPricePoints.push(i);
    }
    uint256 _len = tokenPricePoints.length;

    owner = msg.sender;

    minimumTokensToSell = _minimumTokensToSell;
    minimumBid = _minimumBid;
    startTime = _startTime;
    endTime = _startTime + 2592000; //Add 30 days
    bidAmount.length = _len;
    endIndex.length = _len;
    allowWithdraw.length = _len;
  }

  /// @dev Function to submit a bid
  /// @param _tokenPrice Desired token price point, must be listed in
  /// tokenPricePoints array
  function deposit(uint256 _tokenPrice) payable returns (bool ok) {
    uint256 _bucketIndex;
    bool found;

    //Failures do not result in throwing an error due to the current lack of
    //information when throwing. There is instead a failedDeposit map
    //where bidders can retrieve their deposit by calling getFailedDeposit()
    if((now < startTime) || (endTime < now)){
      failedDeposit[msg.sender] = msg.value;
      ErrorMsg(msg.sender, "Not auction time, call getFailedDeposit()");
      return false;
    }

    if(bidLocation[msg.sender][0] != 0){
      failedDeposit[msg.sender] = msg.value;
      ErrorMsg(msg.sender, "This account already bid, call getFailedDeposit()");
      return false;
    }

    (found, _bucketIndex) = tokenPricePoints.indexOf(_tokenPrice, true);
    if(!found){
      failedDeposit[msg.sender] = msg.value;
      ErrorMsg(msg.sender, "Price point not listed, call getFailedDeposit() and try again");
      return false;
    }

    if(msg.value < minimumBid){
      failedDeposit[msg.sender] = msg.value;
      ErrorMsg(msg.sender, "Bid too low, call getFailedDeposit() and try again");
      return false;
    }

    if(msg.value < _tokenPrice){
      failedDeposit[msg.sender] = msg.value;
      ErrorMsg(msg.sender, "Bid below lowest price, call getFailedDeposit() and try again");
      return false;
    }

    uint256 _len = bids[_tokenPrice].length++;
    Bid _lastIndex = bids[_tokenPrice][_len];
    if(_lastIndex.totalBid != 0){
      failedDeposit[msg.sender] = msg.value;
      ErrorMsg(msg.sender, "Submission error, call getFailedDeposit() and try again");
      return false;
    }

    _lastIndex.bidder = msg.sender;
    _lastIndex.totalBid = msg.value;
    bidLocation[msg.sender][0] = _tokenPrice;
    bidLocation[msg.sender][1] = _len;
    Deposit(msg.sender, msg.value, _tokenPrice);

    bidAmount[_bucketIndex] += msg.value; //records total amount raised at each price point

    return true;
  }

  /// @dev Utility function called after auction, finds the price point from
  /// high to low until cap is met in reverse Dutch style, also checks that
  /// minimum target was met
  function findTokenPrice() private {
    uint256 _total;
    uint256 _totalTokens;
    uint256 _indexOfBucket = bidAmount.length;
    uint256 _tokensAvail = auctionSupply/(10**decimals);

    while(_totalTokens < _tokensAvail){
      _indexOfBucket--;
      _total += bidAmount[_indexOfBucket];
      _totalTokens = _total / tokenPricePoints[_indexOfBucket];
      if(_indexOfBucket == 0)
        break;
    }

    if(_totalTokens < minimumTokensToSell){
      cancelAuction = true;
      for(uint256 i = 0; i<allowWithdraw.length; i++){
        allowWithdraw[i] = true;
      }
    } else if(_totalTokens <= _tokensAvail){
      fundAll = true;
    }

    if(!cancelAuction)
      bestPrice = tokenPricePoints[_indexOfBucket];

    bpIndex = _indexOfBucket;
  }

  /// @dev Ties auction results with provided ERC20 token
  /// @param _seed String provided for first hash in selection sequence
  function processAuction(string _seed)
           andIsOwner
           returns (bool ok)
  {

    if(now < endTime){
      ErrorMsg(msg.sender, "Auction is not over");
      return false;
    }

    findTokenPrice();
    if(cancelAuction){
      auctionSupply = 0;
      NoticeMsg(msg.sender, "Minimum not met, auction cancelled");
      return true;
    }

    if(!fundAll) {
      calcMaxBytes();

      //The first hash uses the seed and miner address. The miner can't control
      //the seed, the caller can't control which miner. This leaves some control
      //to caller but caller is token issuer who is implementing this random
      //auction in the first place.
      bytes32 _hash = sha3(_seed, block.coinbase);
      hashCode = _hash;

      //Release funds for inelligible low bidders
      for(uint256 i = 0; i<bpIndex; i++){
        allowWithdraw[i] = true;
      }
    }
    return true;
  }

  /// @dev Utility function to calculate number of bytes in a hash to use for
  /// random number
  function calcMaxBytes() private {
    uint256 _numberOfBytes;
    uint256 _bestPrice;
    uint256 x;

    for(uint256 i = bpIndex; i<tokenPricePoints.length; i++){
      _bestPrice = tokenPricePoints[i];
      totalEligibleBids += bids[_bestPrice].length;
      endIndex[i] = totalEligibleBids - 1;
    }

    while(x < totalEligibleBids){
      x = 0;
      ++_numberOfBytes;
      x = 16**(_numberOfBytes*2);
    }
    uint256 maxNumber = x;
    uint256 _byteDivisor = 0;

    while(x >= totalEligibleBids){
      x = maxNumber;
      ++_byteDivisor;
      x = x/_byteDivisor;
    }
    numberOfBytes = _numberOfBytes;
    byteDivisor = _byteDivisor - 1;
  }

  /// @dev Utility function to build number from hash
  /// @param _hash Hash provided
  /// @return uint The number generated
  function buildNumber(bytes32 _hash) private returns (uint index){
    uint256 x;
    for (uint i = 0; i < numberOfBytes; i++) {
      uint b = uint(_hash[numberOfBytes - i]);
      x += b * 256**i;
    }

    return x/byteDivisor;
  }

  /// @dev ICO owner calls this function after token generation to fund accounts
  /// @return bool Returns false if call ran low on gas, true when funding is
  /// complete. This allows function to stop without OOG error. When false is
  /// returned, ICO owner should call function again until complete is true.
  function fundTokens() andIsOwner returns(bool ok){
    if(auctionSupply == 0 || bestPrice == 0){
      ErrorMsg(msg.sender, "Call processAuction() first");
      return false;
    }

    uint256 _winnerIndex;
    uint256 _startIndex;
    uint256 _quantity;
    uint256 _filledQuantity;
    uint256 _filledTotal;
    uint256 _bucket;
    uint256 _len;
    bool err;
    uint256 i;

    if(!fundAll){
      while(auctionSupply != 0){
        if(msg.gas < 50000){
          ErrorMsg(msg.sender, "Gas running low call again");
          return false;
        }

        _winnerIndex = buildNumber(hashCode);
        _startIndex = 0;

        if(_winnerIndex < totalEligibleBids){
          for(i = bpIndex; i<endIndex.length; i++){
            if(_winnerIndex <= endIndex[i]){
  	          _bucket = tokenPricePoints[i];
              i = endIndex.length;
            } else {
              _startIndex = endIndex[i] + 1;
            }
          }
        } else {
          //If hash is too high, hash again and start over
          hashCode = sha3(hashCode);
          continue;
        }

        Bid _winningBid = bids[_bucket][_winnerIndex - _startIndex];
        if(_winningBid.totalBid < bestPrice){
          hashCode = sha3(hashCode);
          continue;
        }

        _quantity = (_winningBid.totalBid / bestPrice);
        _filledQuantity = _quantity * (10**decimals);

        //Some copy work from Nick Johnson's contract
        //If there's not enough tokens left, they get the remaining tokens
        if(auctionSupply < _filledQuantity) {
            _filledQuantity = auctionSupply;
        }

        (err, _filledTotal) = bestPrice.times(_filledQuantity / (10**decimals));

        // Sell the user the tokens
        if(_winningBid.totalBid > _filledTotal){
          _winningBid.totalBid -= _filledTotal;
        } else {
          _winningBid.totalBid = 0;
        }

        auctionSupply -= _filledQuantity;
        owner.transfer(_filledTotal);

        withdrawTokensMap[_winningBid.bidder] += _filledQuantity;

        hashCode = sha3(hashCode);

//These can be commented out to reduce gas cost during execution
        BidSelected(_winningBid.bidder, true);
        BidderPB(_bucket);
        BidderBI(_winnerIndex - _startIndex);
        BidderFQ(_filledQuantity);
        BidderFT(_filledTotal);
        AuctionSL(auctionSupply);
      }
    } else {
      for(i = 0; i < tokenPricePoints.length; i++){
        _bucket = tokenPricePoints[i];
        _len = bids[_bucket].length;

        for(uint256 z = 0; z < _len; z++){
          if(msg.gas < 30000){
            ErrorMsg(msg.sender, "Gas running low call again");
            return false;
          }

          _winningBid = bids[_bucket][z];
          _quantity = _winningBid.totalBid / bestPrice;
          _filledQuantity = _quantity * (10**decimals);
          (err, _filledTotal) = bestPrice.times(_filledQuantity / (10**decimals));

          if(_winningBid.totalBid > _filledTotal){
            //Leave the leftover change
            _winningBid.totalBid -= _filledTotal;
          } else {
            _winningBid.totalBid = 0;
          }

          auctionSupply -= _filledQuantity;
          owner.transfer(_filledTotal);

          withdrawTokensMap[_winningBid.bidder] += _filledQuantity;
        }
      }
    }

    for(i = 0; i<allowWithdraw.length; i++){
      if(msg.gas < 20000){ return false; }
      allowWithdraw[i] = true;
    }

    return true;
  }

  /// @dev Function called by winning bidders to pull tokens
  function withdrawTokens() {
    var total = withdrawTokensMap[msg.sender];
    withdrawTokensMap[msg.sender] = 0;
    bool ok = token.transferFrom(owner, msg.sender, total);
    if(ok)
      TokensWithdrawn(msg.sender, total);
  }

  /// @dev Function called by bidders to withdraw remaining funds
  function withdrawDeposit() {
    uint256 _price = bidLocation[msg.sender][0];
    bool found;
    uint256 _bucket;
    (found, _bucket) = tokenPricePoints.indexOf(_price, true);

    //If auction is completed and funded, cancelled, or 30 days after completion
    //allow withdraw of remaining funds.
    if(allowWithdraw[_bucket] || (now > (endTime+2592000))){
      uint256 _index = bidLocation[msg.sender][1];
      var total = bids[_price][_index].totalBid;
      bids[_price][_index].totalBid = 0;
      msg.sender.transfer(total);
      DepositWithdrawn(msg.sender, total);
    } else {
      ErrorMsg(msg.sender, "Withdraw not allowed");
    }
  }

  /// @dev Function called by bidders to retrieve failed bid
  function getFailedDeposit() {
    uint256 amount = failedDeposit[msg.sender];
    failedDeposit[msg.sender] = 0;
    msg.sender.transfer(amount);
  }
}
