//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    DeployFundMe deployFundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    function setUp() external {
        deployFundMe = new DeployFundMe();
        console.log("Address of deploy script", address(deployFundMe));

        fundMe = deployFundMe.run();

        vm.deal(USER, STARTING_BALANCE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOwnerIsMsgSender() public view {
        address owner = fundMe.getOwner();
        assertEq(owner, msg.sender);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    function onlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        //Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
        /**
         * +gasUsed
         */
    }

    function testWithdrawWithMultipleFunders() public {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        //Act

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    // function testEnoughAmountSpent() public payable {
    //     uint256  sendValue = fundMe.MINIMUM_USD();
    //     vm.deal(address(this), sendValue); // Give the test contract enough ETH
    //     console.log("This is the send Value",sendValue);
    //     fundMe.fund{value : sendValue}();
    //     uint256 tx1 = fundMe.addressToAmountFunded(address(this));
    //     console.log("This is transaction",tx1);
    //     assertEq(tx1 , sendValue);
    // }
}
