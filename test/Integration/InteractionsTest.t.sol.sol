//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract fundMeTestIntegration is Test {
    address USER = makeAddr("user"); //creating a fake user to send all our tx
    uint256 SEND_VALUE = 0.1 ether;
    FundMe fundMe;
    uint256 constant STARTING_BALANCE = 10 ether;

    function  setUp () external{
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testUsersCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        // vm.prank(USER);
        //  vm.deal(USER, 1e18);
        // vm.deal(address(fundFundMe), 1 ether); // fund the contract that pays

        fundFundMe.fundFundMe(address(fundMe));
        
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);





        //  address funder = fundMe.getFunder(0);
        // assertEq(funder, USER);

    }
}