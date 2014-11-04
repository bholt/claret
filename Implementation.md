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
    - Is the code in a good place to be extended? Is the plan to maintain it going forward?
- Seems like there is some synergy in that there are already multiple replicas in memory to work on.
- Reads typically just need to hit one replica; maybe commutative/combining ops can do the same?
- Do combining at replicas; when sharing results with others, apply them in a deterministic order (or if all commute, then whatever order you want)

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

