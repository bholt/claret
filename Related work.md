# Related Work

- escrow transactions (Neha got a question about these after her talk)

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

## Enhancing Concurrency in DTM through Commutativity 
- \cite{Kim:EuroPar13}: EuroPar'13, Junwhan Kim, Roberto Palmieri, Binoy Ravindran
- Commutative requests first (CRF)
- HyFlow: Scala DTM framework
- *Benchmarks:* TPC-C, linked-list, skip-list

## Commutativity-based concurrency control for abstract data types
- \cite{Weihl:1988}: W. Weihl, *IEEE Transactions on Computers*, 1988.
- some historical background on using abstract data structure semantics for concurrency control

## Transactional boosting
- PPoPP'08, Maurice Herlihy, Eric Koskinen
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
