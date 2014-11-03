# Related Work

- Primary "competing systems"
    - Strict serializability
        - Rococo (OSDI'14)
        - Calvin: Pre-ordered locking (SIGMOD'12)
        - Spanner: 2PL (OSDI'12)
        - HStore: OCC (VLDB'07)
    - Serializable
        - Lynx (SOSP'13)
    - Data structures server
        - Redis: values can be sets, hashmaps, hyperloglogs, etc
            - can do sharding across multiple nodes, but only allows single-key operations

## Phase Reconciliation for Contended In-Memory Transactions
- \cite{Narula:OSDI14}: OSDI'14, Neha Narula, Robert Morris (MIT CSAIL)
- Doppel: multicore, in-memory key/value store
- Split hot keys, allow a handful of commutative operations on them
	- only allow a *single* operation (such as `inc` or `get`) in a given split phase
	- operations defined as returning `void` so they can be "split"
- Periodically recombine split keys and allow non-commutative ops on them
	- "stash" conflicting transactions
- *Weaknesses*
	- a couple ad-hoc commutative operations, no broader theory about which operations to allow, etc.
	- only for key/value store kinds of workloads
	- not sure if it works for multi-key transactions (*it does seem to work for multiple records, relying on OCC for non-split records and the fact that anything done to split records is valid in any serialization*)
	- reconcile all splits in bulk-synchronous fashion
- *Benchmarks/workloads*
	- Social network "Like"s (keep track of count of likes as they come in)
	- RUBiS auction website (7 tables, 26 interactions)
- *Questions*
	- what happens when *part* of a transaction has to wait until a joined phase (if run during a split phase)? Does the transaction abort? Suspend and resume and commit later?
	- What is the performance like if you have an `incr` and `read` in the *same* transaction, on the same record? Didn't see if there were any performance numbers for that, but seems like it would probably interact badly with the phasing.
	- escrow transactions (Neha got a question about these after her talk)

## Extracting More Concurrency from Distributed Transactions
- \cite{Mu:OSDI14} Rococo - two-phase protocol, implemented on distributed transactional db
    - https://github.com/msmummy/rococo
- defer pieces of transactions to allow reordering execution to avoid conflicts
- two-phase protocol to reorder staged computations
- decentralized dependency tracking
    - all participating nodes receive all observed dependence graphs
    - use deterministic order (*why do we need to track dependence graphs?*)
- do offline checking to find dependences and potential cycles
    - which pieces are "immediate" and which are "deferrable"
    - "merge" immediates with dependent deferrable so you don't accidentally run them too early
- *Benchmarks:* TPC-C
- *Comparisons*
    - doesn't do replication for hot keys
    - how pieces are reordered seems a bit crude (anything that produces a value is "immediate" and cannot be deferred)
    - seems like it would have high runtime overhead (tracking dependences dynamically, despite using offline (static?) analysis)

## Enhancing Concurrency in DTM through Commutativity 
- \cite{Kim:EuroPar13}: EuroPar'13, Junwhan Kim, Roberto Palmieri, Binoy Ravindran
- Commutative requests first (CRF)
- HyFlow: Scala DTM framework
- *Benchmarks:* TPC-C, linked-list, skip-list

## Commutativity-based concurrency control for abstract data types
- \cite{Weihl:1988}: W. Weihl, *IEEE Transactions on Computers*, 1988.
- some historical background on using abstract data structure semantics for concurrency control

## Transactional boosting
- \cite{Herlihy:PPoPP08}: PPoPP'08, Maurice Herlihy, Eric Koskinen
- introduces the idea of using semantics of concurrent-safe data structures to reason about when transactions can be be done safely in parallel
- notion of *abstract locks* which are a generalization of reader/writer locks that encapsulate which operations can proceed in parallel (commute) with other operations

## Concurrent libraries with foresight
- \cite{Golan-Gueta:PLDI13}: PLDI'13, Mooly Sagiv...
- Composing atomic library operations (e.g. operations on synchronized data structures)
- "atomic composite operations": restricted form of transaction
- formalizes a process for determining which possible reorderings lead to serializable executions
- uses locks to prevent only the unsafe (unserialiable) executions
- needs the library to be designed so that it knows how to use "foresight"
- so it actually can't compose operations from more than one library...

## Commit-reconcile & Fences
- \cite{Shen:ISCA99}: ISCA'99, on shared memory models for semantic operations on data replicated in caches
