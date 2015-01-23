## Evaluation

- *Goals*
    - show that this approach does better than OCC/contending
    - show that it scales out in terms of increasing contention and number of nodes
    - show that the technique subsumes existing work avoiding contention
    - new workloads enabled by this? (may just be made significantly more efficient)
- key/value store database
    - TPC-C
    - LIKE
    - RUBiS (auction website)
    - what has more interesting operations on the records than just `incr`?
    - YCSB: Yahoo Cloud Serving Benchmark
- graph database
    - must we support multi-node transactions? is it worth it?
    - transactions:
        - read queries (over small parts of the graph)
        - add edge & update vertices on both side
    - LinkBench?
    - SNBC?

### Tapir
- Retwis
    - vary the zipfian coeff. to change the contention
    - see how Paxos, Tapir, and Tapir+Claret scale with increased contention x cluster size


### Desired workload characteristics
- Naturally skewed (e.g. resulting from power-law graph structure, auction bids, viral content, etc)
- Update-heavy: leads to *contention* when skewed
- Commutative data structure operations available to be exploited
  - preferably a more complex commutativity structure, rather than simply a boolean "commutes or not"

### Examples
- Retwis++
  - add repost/retweets: another contentious 