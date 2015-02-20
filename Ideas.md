# Miscellaneous ideas

- Luis: combining futures, replicas with permissions that allow some of the operations to be applied without collapsing
- Luis: staging operations so you can re-execute them whenever they're ready to proceed
	- may not need to enforce "atomicity" directly, may just need a weaker memory model?
- Madan-like symbolic execution without actually having the result, you can pre-compute some things
- Hotspot avoidance
	- hot vertices in graph, replicate their state (or parts of it)
- Fences
    - difference between a *global* fence (tx committed on all replicas of objects) and *anywhere* or *local* fence (tx committed on *a* replica, so we can get a result, but may not know its global order yet)
- Opportunistic (or optional) transactions
    - could have some transaction scheduler that is allowed to drop some txs if they are marked as optional
    - example: sampled query of values. any that are "too hard" to read we can just skip. or use weaker semantics (i.e. require only *local* fence)

## Type system to integrate weaker consistency
- We should be able to add weaker consistency (CRDT-like) within data types by just replicating the data structure on multiple shards, then asynchronously communicating updates between them
- is that sufficient to allow people to use these alongside other data types?
- it *may be* (need to investigate) that you would want to make sure that eventually consistent information isn't used in strictly serializable contexts because that might violate the stronger guarantees there
    - (it also may be that no one cares, or that it's irrelevant because the programmer already explicitly stated that they're okay with out-of-date values, so what they do with it is their own business
- but: if there is sufficient motivation for it we could make a type system that separates eventually consistent types from strongly consistent ones so that you have to do some explicit cast or synchronization to convert weak to strong
    - is there any work in multicore consistency models that does something like this? seems like that's the first place it would show up