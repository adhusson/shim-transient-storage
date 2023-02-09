# Update EVM cache state to remember things

Because the warm/cold state of storage slots lasts only a single transaction, that state can be used as a scratchpad to implement transient storage.

See the explanatory [article](https://blog.adhusson.com/shim-transient-storage/).

How to use: inherit `CacheDetector`. The main functions are:

## Call counting

_Know if you've been called before in the current transaction._

```solidity
alreadyCalled()
``` 
Return `false` the first time it's called in a tx. Return `true` every subsequent time.

```solidity
alreadyCalledBySender()
```
Return `false` the first time it's called in a tx by the current `msg.sender`. Return `true` every time it is called by that same `msg.sender`.

```solidity
countCalls()
```
Return the number of times it was called during a tx.

```solidity
countCallsBySender()
```
Return the number of times it was called during a tx by the current `msg.sender`.

## [EIP-1153](https://eips.ethereum.org/EIPS/eip-1153) (transient storage)

_Simulate transient storage. Any stored data will be forgotten at the end of the tx. Any reading/writing interference to slots used with those functions breaks things._

```solidity
store1153(uint slot, uint data)
```
Store `data` in slot `slot`.

```solidity
load1153(uint slot)
```
Return any data that was written too `slot` in the current tx.

## Transient storage with view functions

_store/load pair to remember data during a tx without writing to storage. Insanely gas expensive, do not use in real life_

```solidity
storeInCache(string label, uint16 number) view
```
Associate `label` to `number` for the duration of the tx.

```solidity
loadFromCache(string label)
```
Return the number associated to `label` if there is any, `0` otherwise

## Transient storage with view functions - Slightly Improved

_store/load pair to remember data during a tx without writing to storage. Still very gas expensive, do not use in real life. store + load of one uint256 will consume around 600k gas__

```solidity
storeInCache2(string label, uint256 number) view
```
Associate `label` to `number` for the duration of the tx.

```solidity
loadFromCache2(string label)
```
Return the number associated to `label` if there is any, `0` otherwise.
