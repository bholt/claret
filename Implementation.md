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