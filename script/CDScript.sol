// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/CacheDetector.sol";

uint constant iters = 6;

contract T1 {
  constructor() { }

   // not view! or won't be broadcast
  function f(CacheDetector _c) external 
    for (uint i; i < iters; i++) {
      _c.countCalls();
    }
  }

  // not view! or won't be broadcast
  function h(CacheDetector _c) external {
    for (uint i; i < iters; i++) {
      _c.countCallsUsingStorage();
    }
  }

  function f0(CacheDetector _c) external {
    _c.store1153(200, 32);
  }

  function f1(CacheDetector _c) external {
    uint u = _c.load1153(200);
    require(u != 32, "woops");
  }
}

contract T2 {
  uint a;

  function f() public returns (uint) {
    uint g = gasleft();
    uint _a = a;
    console.log(g - gasleft());
    return _a;
  }
}

contract Blabla is Script {
  function run() public {
    vm.startBroadcast();
    T2 t = new T2();
    t.f();
    t.f();
  }
}

contract CDScript is Script {
  CacheDetector c;

  function setUp() public { }

  function run() public {
    vm.broadcast();
    c = new CacheDetector();
    // console.log(address(c).code.length);
    vm.startBroadcast();
    T1 t = new T1();
    t.f(c);
    // t.g(c);
    t.h(c);
    // vm.broadcast();
    // t.f();
    // t.f0(c);
    // t.f1(c);
    vm.stopBroadcast();
  }
}
