# Project
- Promote a data-structure-store design paradigm: build your applications out of known data types so that the system can reason about commutativity, replication, etc, and you can use *strict consistency*
- Use commutativity to avoid falling over from contention on *bursty, skewed, update-heavy workloads*
  - i.e. Ellen retweet, Truffle auction, Reddit
- Apply *abstract locks* (from database and multi-core STM communities) to *distributed* *ad-hoc* applications like those that use Redis
- Faster, better, linearizable, transactional Redis.

## Goals
- to apply ideas from combining and abstract locks to distributed transactions
- avoid hotspots automatically by splitting/replicating on the fly
- apply a more rigorous notion of serializability and consistency on data structures
    - basically at the level of \cite{Herlihy:PPoPP08} & \cite{Golan-Gueta:PLDI13}
- more generalized notion of commutative ops make transactions more efficient (allow them to commit even while operating on replicas, more concurrency)
- better programming model that allows complex operations to be efficiently/scalably executed
    - other systems require inventing new operators with different semantics, or splitting out into multiple records/keys in database
    - e.g. keep track of max bid, separate from who did the bid, from the total number of bids. if it was just a *set*, it would be easier to think about

## Hypotheses
- asynchronous phasing/reconciliation will perform better than global bulk-synchronous approaches
- exposing more mergeable operations will allow more concurrency and therefore greater performance
- combining will reduce the overhead (processing time & data movement) of staging and reordering transactions
- data structures = better programming model

