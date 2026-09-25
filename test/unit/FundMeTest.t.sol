//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract fundMeTest is Test {
    address USER = makeAddr("user"); //creating a fake user to send all our tx
    uint256 SEND_VALUE = 0.1 ether;
    FundMe fundMe;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // gives fake money to user
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsSender() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    // cheatcodes
    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert(); // the code after this should revert else it will fail
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //this means the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAdddsFundersToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();
        vm.expectRevert();
        vm.prank(USER); // expect revert ignores this one, so its
        fundMe.withdraw(); // this one that revets cause it is a tx
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange: arrange the test st up the test
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingfundMeBalance = address(fundMe).balance;

        //Act: do the action you want to test
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert: assert the test
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingfundMeBalance = address(fundMe).balance;
        assertEq(endingfundMeBalance, 0);
        assertEq(startingfundMeBalance + startingOwnerBalance, endingOwnerBalance); //whae we are using anvil the gas is zero
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // ot 0 because soetimes 0th address reverts and dont let you do stuffs with it
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address
            //vm.deal that new address
            //hoax(someaddress, SEND_VALUE)
            hoax(address(i), SEND_VALUE);
            // fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingfundMeBalance = address(fundMe).balance;

        //Act

        //normally gas price is defaulted to zero on anvil, but we can set a default gas price for the rest of our code using vm.txGasPrice
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw(); // anything between start and stop is going to be sent bythe pretender
        vm.stopPrank();
        //Assert

        assert(address(fundMe).balance == 0);
        assert(startingfundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}
