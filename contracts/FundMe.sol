// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

//we can then interace with the contract that has these below functions: decimals, description, version
//interfaces compile down to ABI, anytime you want to interact with the smartcontract that already deployed, you need an ABI

/*interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}
*/

contract FundMe {
    using SafeMathChainlink for uint256;

    //this is to create a view which can be called to retrieve the address
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        //set the minimum USD to be 50 dollars
        uint256 minimumUSD = 1 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        //what the ETH -> USD conversion rate
        funders.push(msg.sender);
    }

    //This will show us the powerful of using interface from others contract
    function getVersion() public view returns (uint256) {
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        /*this is the same as to say
        (uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound) = priceFeed.latestRoundData();
        */
        //return price with 18 decimals
        return uint256(answer * 10000000000);
    }

    // 1000000000 = 1 Gwei
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
        // 0.000004246220000000 the result of getPrice is always 18 decimals and this is 1 Gwei which equals to this many dollars
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        //run the rest of the code
        _;
    }

    function withdraw() public payable onlyOwner {
        // only want the contract admin/owner
        // require msg.sender = owner
        // require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);

        //set a for loop so that we set the address to 0
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset the array to 0
        funders = new address[](0);
    }
}
