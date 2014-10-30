# Project

## Goals
- to apply ideas from combining and abstract locks to distributed transactions
- avoid hotspots automatically by splitting/replicating on the fly
- apply a more rigorous notion of serializability and consistency on data structures
    - basically at the level of \cite{Herlihy:PPoPP08} & \cite{Golan-Gueta:PLDI13}
- more generalized notion of commutative ops make transactions more efficient (allow them to commit even while operating on replicas, more concurrency)

## Hypotheses
- asynchronous phasing/reconciliation will perform better than global bulk-synchronous approaches
- exposing more mergeable operations will allow more concurrency and therefore greater performance
- combining will reduce the overhead (processing time & data movement) of staging and reordering transactions
