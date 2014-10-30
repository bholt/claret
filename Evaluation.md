## Evaluation

- *Goals*
    - show that this approach does better than OCC/contending
    - show that it scales out in terms of increasing contention and number of nodes
    - show that the technique subsumes existing work avoiding contention
    - new workloads enabled by this? (may just be made significantly more efficient)
- graph database
    - must we support multi-node transactions? is it worth it?
    - transactions:
        - read queries (over small parts of the graph)
        - add edge & update vertices on both side