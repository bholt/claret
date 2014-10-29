# Related Work

## Phase Reconciliation for Contended In-Memory Transactions
- \cite{186204}: OSDI'14, Neha Narula, Robert Morris (MIT CSAIL)
- Doppel: multicore, in-memory key/value store
- Split hot keys, allow a handful of commutative operations on them
- Periodically recombine split keys and allow non-commutative ops on them
- *Weaknesses*
	- a couple ad-hoc commutative operations, no broader theory about which operations to allow, etc.
	- only for key/value store kinds of workloads
	- not sure if it works for multi-key transactions
- *Benchmarks/workloads*
	- Social network "Like"s (keep track of count of likes as they come in)
	- RUBiS auction website (7 tables, 26 interactions)

## Enhancing Concurrency in DTM through Commutativity 
- \cite{Kim_2013}: EuroPar'13, Junwhan Kim, Roberto Palmieri, Binoy Ravindran
- Commutative requests first (CRF)
- HyFlow: Scala DTM framework
- *Benchmarks:* TPC-C, linked-list, skip-list

## Commutativity-based concurrency control for abstract data types
- W. Weihl, *IEEE Transactions on Computers*, 1988.

## Transactional boosting
- PPoPP'08, Maurice Herlihy, Eric Koskinen
- abstract locks

## Concurrent libraries with foresight
- PLDI'13, Mooly Sagiv
- Composing atomic library operations (e.g. operations on synchronized data structures)
- "atomic composite operations": restricted form of transaction
