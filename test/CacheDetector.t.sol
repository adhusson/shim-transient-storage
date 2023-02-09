// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/CacheDetector.sol";

contract CacheDetectorTest is Test {
  CacheDetector public cd;

  function setUp() public {
    cd = new CacheDetector();
    console.log("iterations: %s", iters);
    cd.store1153(12, 32);
  }

  function test_load1153_is_0_despite_setUp() public {
    assertEq(cd.load1153(12), 0);
    assertEq(cd.load1153(12), 0);
  }

  uint immutable iters = 4;

  function test_alreadyCalled() public {
    assertEq(cd.alreadyCalled(), false);
    assertEq(cd.alreadyCalled(), true);
    assertEq(cd.alreadyCalled(), true);
  }

  function test_numberOfCalls() public {
    for (uint i; i < iters; i++) {
      assertEq(cd.countCalls(), i + 1);
    }
  }

  function test_view_storage(string memory label, uint16 num1, uint16 num2) public {
    // string memory label = "label";
    // uint16 num1 = 4321;
    // uint16 num2 = 63000;

    vm.assume(keccak256(bytes(label)) != keccak256("b"));
    vm.assume(bytes(label).length != 0);
    cd.storeInCache(label, num1);
    assertEq(cd.loadFromCache(label), num1);
    assertEq(cd.loadFromCache(label), num1);
    assertEq(cd.loadFromCache("b"), 0);
    cd.storeInCache(label, num2);
    assertEq(cd.loadFromCache(label), num2);
    assertEq(cd.loadFromCache(label), num2);
    assertEq(cd.loadFromCache("b"), 0);
  }

  function test_view_storage2(string memory label, uint256 num1, uint256 num2) public {
//    string memory label = "label";
//    uint256 num1 = 4321;
//    uint256 num2 = 63000;

    vm.assume(keccak256(bytes(label)) != keccak256("b2"));
    vm.assume(bytes(label).length != 0);
    cd.storeInCache2(label, num1);
    assertEq(cd.loadFromCache2(label), num1);
    assertEq(cd.loadFromCache2(label), num1);
    assertEq(cd.loadFromCache2("b2"), 0);
    cd.storeInCache2(label, num2);
    assertEq(cd.loadFromCache2(label), num2);
    assertEq(cd.loadFromCache2(label), num2);
    assertEq(cd.loadFromCache2("b2"), 0);
  }

  function test_countCalls_simple() public {
    assertEq(cd.countCalls(), 1);
    assertEq(cd.countCalls(), 2);
    assertEq(cd.countCalls(), 3);
  }

  function test_countCallsUsingStorage() public {
    assertEq(cd.countCallsUsingStorage(), 1);
    assertEq(cd.countCallsUsingStorage(), 2);
    assertEq(cd.countCallsUsingStorage(), 3);
  }
}
