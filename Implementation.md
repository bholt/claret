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
- Combining with transactions
    - combined ops (*patches*) include a set of transactions, but 1 transaction may be split among multiple patches
    - is there any chance of having unserializable sets of combined ops? (for example, can I end up with some operations in one patch that rely on a particular order, which is different than the order observed for the second patch?)
        - I'm thinking that this shouldn't be a problem since we're only combining ops that commute w.r.t the current state/mode of the object, but because we're splitting transactions and recombining them per-object this is worth considering carefully. 
	- how do we efficiently keep track of which transactions are in a given patch? how do we know when it's been completed?
- Futures
    - using the notion of futures (returned by atomic ops) may make this easier to think about.
    - can allow futures to be *chained* into multi-hop transactions
    - individual futures can be *combined* locally into more compact multi-futures

### TAPIR Extension
- *Feasible*?
    - Would the resulting protocol be too complex?
    - Is it weird to work on it while in submission?
- Seems like there is some synergy in that there are already multiple replicas in memory to work on.
- Reads typically just need to hit one replica; maybe commutative/combining ops can do the same?
- Do combining at replicas; when sharing results with others, apply them in a deterministic order (or if all commute, then whatever order you want)

##### *First pass:* add Redis data structure ops to increase concurrency / reduce aborts
- local backing store for each shard/replica
    - currently a KV store (put/get)
    - *todo:* extend/replace with Redis (or something like Redis)
- OCC layer
    - before things get put in the backing store, you stage them through the OCC layer, which tracks read/write sets of all in-flight txs
    - on `prepare`, you add to the read/write sets
    - on `commit`, put them into the backing store and remove them from the read/write sets
    - use timestamps to determine if something conflicts.
        - can do some reordering because you can sometimes choose the timestamp so that it works
    - *todo*
        - extend this to allow commutative ops to not abort; need something more than just read/write sets.
        - could also try doing it with locks...
        - use timestamps to determine *commutative phases* 
    - **zeroth pass:** disable txn/serializability by just returning `true` all the time (then you basically get a form of distributed Redis)
- run under Tapir or just traditional Paxos (or both)
    - try to stick all the higher-level operations into `put` ops as far as the upper layers (Tapir/Paxos) are concerned. the OCC layer can sort out what the operations actually are (given the type of the object) and determine if they conflict or not

#### Batching & combining
- add a level of batching to the system that allows you to amortize the checks over commutative phases
- expose the fact that you're combining multiple txs into a single message to the upper layers
- try to come up with a protocol for combining over replicas

#### Contention avoidance by splitting
- split hot keys across multiple shards
    - in tapir: consensus then has to happen first across the replicas of each split, then over the combined result
    - in paxos: the leaders of each shard's replica groups have to elect a leader, who then combines all of their results
- this adds many extra round trips, probably only will pay off if you have highly contentious keys so you can batch many transactions and do the extra layer of coordination infrequently
- *first* evaluate this on Grappa or a non-fault-tolerant (or non-replicated) platform and see what the performance tradeoffs are for splitting, given particular workloads
- *then* try the fault-tolerant version with higher cost for synchronizing
- dynamic splitting
    - use consistent hashing, plus a replica number (`k => hash(k)+hash(replica_idx) % nnode`)
    - everyone just needs to know how many replicas a given key has (or a *lower bound* on it) so they can choose from the set of hashed locations

### Example: Counter (not to be confused with *counterexample*)
- Usage:
    - "Likes" on social network pages
- Operations:
    - `read: => T`
    - `write: => void`
    - `incr: => void`
    - `fetch_add: => T` (??)
- Transactions
    - display: `read`
    - like: `incr >> read` (or `fetch_add`)
    - new: `write`

