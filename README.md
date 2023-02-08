# Update EVM cache state to remember things

See the explanatory [article]().

How to use: inherit `CacheDetector`. The main functions are:

## Call counting

Know if you've been called before in the current transaction.

### `alreadyCalled()` 
Return `false` the first time it's called in a tx. Return `true` every subsequent time.

### `alreadyCalledBySender()` 
Return `false` the first time it's called in a tx by the current `msg.sender`. Return `true` every time it is called by that same `msg.sender`.

### `countCalls()`
Return the number of times it was called during a tx.

### `countCallsBySender()` 
Return the number of times it was called during a tx by the current `msg.sender`.

## [EIP-1153](https://eips.ethereum.org/EIPS/eip-1153)

Simulate transient storage. Any stored data will be forgotten at the end of the tx. Any reading/writing interference to slots used with those functions breaks things.

### `store1153(uint slot, uint data)`
Store `data` in slot `slot`.

### `load1153(uint slot)`
Return any data that was written too `slot` in the current tx.

## Write with view functions

### `storeInCache(string label, uint16 number) view`
Associate `label` to `number` for the duration of the tx.

### `loadFromCache(string label)`
Return the number associated to `label` if there is any, `0` otherwise.





* **Detect and count within-tx repeated calls**: count how many times you've been called in a tx
* **Shim EIP-1153**: store/load data for the duration of the tx only (aka transient storage)
* **Store arbitrary data with view functions**: remember arbitrary data despite the `view` modifier (costs huge gas amounts).
* **Low-level functions** 
