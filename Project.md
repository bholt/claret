# Project

## Goals
- to apply ideas from combining and abstract locks to distributed transactions
- avoid hotspots automatically by splitting/replicating on the fly
- use a rigorous 
- more generalized notion of commutative ops make transactions more efficient (allow them to commit even while operating on replicas, more concurrency)

## Hypotheses
- asynchronous phasing/reconciliation will perform alright and reduce the overhead of waiting
- exposing more mergeable operations will allow more concurrency and therefore greater performance
- these techniques will allow us to enforce strong consistency with low cost, provided your operations are designed well

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

## Evaluation
- *Goals*
    - show that this approach does better than OCC/contending
    - 
    - 
- graph database
    - must we support multi-node transactions? is it worth it?
    - transactions:
        - read queries (over small parts of the graph)
        - add edge & update vertices on both side