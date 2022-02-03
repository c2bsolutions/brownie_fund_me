//SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol"; //remix understands but brownie cannot download from npm but can from github

contract FundMe {
    //only for less than v0.8
    //using SafeMathChainlink for uint256; library similar to contracts, but their purpose is that they are deployed only once at a specific address and their code is reused

    mapping(address => uint256) public addressToAmountFunded; //create key for address
    //interface compiles down to ABI and ABI tells solidity and other programming languages how it can interact with another contract
    address[] public funders; //
    address public owner;
    AggregatorV3Interface public priceFeed;

    //add
    constructor(address _priceFeed) public {
        //constructors are called the instant the smart contract is deployed(used to set owners and admin)
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender; //set owner of deployer
    }

    function fund() public payable {
        //payable means function can be used to pay for things
        uint256 minimumUSD = 50 * 10**18; //10**18=10^18
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        ); //if conversion rate not enough either revert transaction(user gets back money and unspent gas)
        addressToAmountFunded[msg.sender] += msg.value; //msg.sender(sender of function call) and msg.value(how much sent) are keywords in every contract call and every transaction
        funders.push(msg.sender);
    }

    //check
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //using tuple to define returned values from contract
        return uint256(answer * 10000000000); //how to type cast
        //answer has 8 decimals ex 2357.83356969
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        //minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        //use modifier to create condition for calling function
        require(msg.sender == owner); //check for these validations when function called
        _; //run rest of code
    }

    function withdraw() public payable onlyOwner {
        //only want the contract admin/owner to allow withdrawal
        payable(msg.sender).transfer(address(this).balance); //transfer function to call on any address to send from one to another
        // has to be payable in v.8
        //who ever calls this function transfer all money
        //this means contract currently in, address means address of contract currently in, balance attribute

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
