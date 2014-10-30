# Project

## Goals
- to apply ideas from combining and abstract locks to distributed transactions
- avoid hotspots automatically by splitting/replicating on the fly
- more rigorous notion of serializability and consistency
    - basically at the level of \cite{Golan-Gueta:PLDI13}
- more generalized notion of commutative ops make transactions more efficient (allow them to commit even while operating on replicas, more concurrency)

## Hypotheses
- asynchronous phasing/reconciliation will perform better than global bulk-synchronous approaches
- exposing more mergeable operations will allow more concurrency and therefore greater performance
- combining will reduce the overhead (processing time & data movement) of staging and reordering transactions

## Implementation
- How to do splitting?
    - *Complete replicas:* Keep track of operations, combine them into more efficient update, and send to all replicas
        - don't have to collapse replicas just to do ops that need global state
        - after sharing, everyone has the complete "log", so we can service all requests locally
        - is this too much more communication? seems like we can expect that hot records will continue to be hot, so we should keep them split...
        - all replicas have to know about all other replicas... (maybe we can do as a tree?)
    - *Splits:* Essentially "empty" versions of original data structure, with defined semantics for merging into the original
        - could be done with a Monoid-like interface
        - limited operations, anything requiring concrete state must wait
    - *Proxies:* Custom logic for how to take in operations, combine them, and spit out an answer.
        - allows for annihilation
        - saves from sending state of large object at splitting time
        - data structure maintainer must implement by hand?
- Asynchronous record/object reconciliations or global phases?
    - Seems like most of the current work I've seen relies on global phases (both OSDI'14 papers at least). My intuition is that any time you implement a global synchronization, you're probably leaving performance on the floor. Are they doing this because it's an easier implementation? Maybe in the presence of coordinating multi-object transactions, it's too hard to do asynchronously and you just default to global phases?