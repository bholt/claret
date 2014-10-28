# Miscellaneous ideas

- Luis: combining futures, replicas with permissions that allow some of the operations to be applied without collapsing
- Luis: staging operations so you can re-execute them whenever they're ready to proceed
	- may not need to enforce "atomicity" directly, may just need a weaker memory model?
- Madan-like symbolic execution without actually having the result, you can pre-compute some things
- Hotspot avoidance
	- hot vertices in graph, replicate their state (or parts of it)
