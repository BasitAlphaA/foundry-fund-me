//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

/**
 * @title FundMeTest
 * @dev This contract tests the FundMe contract using Foundry.
 */

contract FundMeTest is Test {
    FundMe fundMe;
    DeployFundMe deployFundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

  /**
     * @notice Deploys the FundMe contract before running tests.
     */

    function setUp() external {
        deployFundMe = new DeployFundMe();
        console.log("Address of deploy script", address(deployFundMe));

        fundMe = deployFundMe.run();

        vm.deal(USER, STARTING_BALANCE);
    }

 /**
     * @notice Modifier to fund the contract before executing a function.
     */

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

/**
     * @notice Ensures that the contract owner is the deployer.
     */

    function testOwnerIsMsgSender() public view {
        address owner = fundMe.getOwner();
        assertEq(owner, msg.sender);
    }

 /**
     * @notice Verifies that funding fails if insufficient ETH is sent.
     */

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    /**
     * @notice Checks that funding updates the mapping of funded amounts.
     */

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

 /**
     * @notice Ensures that a funder is added to the array of funders.
     */

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

/**
     * @notice Ensures that only the contract owner can withdraw funds.
     */

    function onlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

   /**
     * @notice Tests withdrawal with a single funder.
     * @dev Ensures that the contract balance is properly transferred to the owner.
     */

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

    /**
     * @notice Tests withdrawal with multiple funders.
     * @dev Simulates multiple funders contributing before withdrawal.
     */

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


}
