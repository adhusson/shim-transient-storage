// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";

/*
  Use cache state to detect multiple within-tx calls, shim EIP-1153 and write with view functions. */
contract CacheDetector {
  uint private constant ALREADY_CALLED_SLOT = uint(keccak256("ALREADY_CALLED_SLOT"));
  uint private constant COUNT_CALLS_SLOT = uint(keccak256("COUNT_CALLS_SLOT"));
  uint private constant COUNT_CALLS_USING_STORAGE_SLOT =
    uint(keccak256("COUNT_CALLS_USING_STORAGE_SLOT"));

  uint private constant COLD_SLOAD_COST = 2100;

  /**
   *
   *     Detect and count within-tx repeated calls
   *
   */

  // In any transaction, will retun false the first time it's called, and true
  // every other time.
  function alreadyCalled() external view returns (bool) {
    return isSlotWarm(ALREADY_CALLED_SLOT);
  }

  // In any transaction, will retun false the first time it's called by a given address, and true every other time.
  function alreadyCalledBySender() external view returns (bool) {
    return isSlotWarm(uint(keccak256(abi.encodePacked(ALREADY_CALLED_SLOT,msg.sender))));
  }

  // returns n, the number of times the function was called in this tx, starting
  // from 1 from n ~ 5, more expensive that counting (n ~ 6 if you add reset to
  // 0 at last call)
  function countCalls() external view returns (uint) {
    return countCalls(COUNT_CALLS_SLOT);
  }

  // returns n, the number of times the function was called in this tx by a
  // given address
  function countCallsBySender() external view returns (uint) {
    return countCalls(uint(keccak256(abi.encodePacked(COUNT_CALLS_SLOT,msg.sender))));
  }

  // call counter keyed by slot
  function countCalls(uint slot) internal view returns (uint n) {
    while (isSlotWarm(slot + n++)) { }
  }

  /**
   *
   *     Shim EIP-1153
   *
   *     Breaks if there is read/write interference on the used slots by other
   *     functions.
   */

  // Simple sstore helper function
  function store1153(uint slot, uint data) public {
    assembly ("memory-safe") {
      sstore(slot, data)
    }
  }

  // Load data with the same semantics as 1153
  // Warning: uses the same space as regular storage (unlike 1153)
  function load1153(uint slot) external view returns (uint) {
    (bool warm, uint data) = stealthLoadWithCacheState(slot);
    // (bool warm, uint data) = stealthLoadWithCacheState(slot);
    return warm ? data : 0;
  }

  // same semantics as countCalls, but uses a 1153-like storage counter
  function countCallsUsingStorage() external returns (uint count) {
    (bool warm, uint data) = loadWithCacheState(COUNT_CALLS_USING_STORAGE_SLOT);
    count = (warm ? data : 0) + 1;
    store1153(COUNT_CALLS_USING_STORAGE_SLOT, count);
  }

  /**
   *
   *     Store arbitrary numbers with a view function
   *
   */

  // !We are completely ignoring collisions here!

  // Store number with label
  function storeInCache(string calldata label, uint16 number) external view {
    uint slot = dataSlot(label, true);
    while (number > 0) {
      isSlotWarm(slot + --number);
    }
  }

  // Read number with label
  function loadFromCache(string calldata label) external view returns (uint) {
    return stealthCountCalls(dataSlot(label, false));
  }

  // Utility: get data slot from label
  // Will return slot for a fresh version if updateVersion is true, the current one otherwise
  function dataSlot(string calldata label, bool updateVersion) internal view returns (uint) {
    require(bytes(label).length != 0, "empty label forbidden");
    uint versionSlot = uint(keccak256(bytes(label)));
    uint version = updateVersion ? countCalls(versionSlot) : stealthCountCalls(versionSlot);
    return uint(keccak256(abi.encodePacked(label, version)));
  }

  /**
   *
   *     Low-level functions
   *
   */

  // return SLOAD result & cache warmth info
  // A caller that ignores the data argument may get its SLOAD optimized away.
  // Writing the Box struct prevents that in solc 0.8.17.
  struct Box {
    uint data;
  }

  function loadWithCacheState(uint slot) internal view returns (bool warm, uint data) {
    uint gasBefore = gasleft();
    assembly ("memory-safe") {
      data := sload(slot)
    }
    warm = (gasBefore - gasleft()) < COLD_SLOAD_COST;
    // prevent optimizer from inlining & removing the sload
    Box memory b = Box({data: data});
  }

  // Whether a given slot is warm or not
  function isSlotWarm(uint slot) internal view returns (bool warm) {
    (warm,) = loadWithCacheState(slot);
  }

  // return call count in revert data
  function countCallsAndRevert(uint slot) external view {
    uint n = countCalls(slot);
    assembly ("memory-safe") {
      mstore(0, n)
      revert(0, 32)
    }
  }

  // count calls, but don't increment the counter doing so
  function stealthCountCalls(uint slot) internal view returns (uint n) {
    try this.countCallsAndRevert(slot) { }
    catch (bytes memory _n) {
      n = abi.decode(_n, (uint)) - 1;
    }
  }

  function loadWithCacheStateAndRevert(uint slot) external view {
    (bool warm, uint data) = loadWithCacheState(slot);
    assembly ("memory-safe") {
      mstore(0, warm)
      mstore(32, data)
      revert(0, 64)
    }
  }

  // count calls, but don't increment the counter doing so
  function stealthLoadWithCacheState(uint slot) internal view returns (bool warm, uint data) {
    try this.loadWithCacheStateAndRevert(slot) { }
    catch (bytes memory _bundle) {
      (warm, data) = abi.decode(_bundle, (bool, uint));
    }
  }
}
