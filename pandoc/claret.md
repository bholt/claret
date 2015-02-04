---
title: 'Claret: Using Data Types for Highly Concurrent Distributed Transactions'
preprint: true

author:
  - {family: Holt,  given: Brandon, affiliation: 1, email: bholt}
  - {family: Zhang, given: Irene,   affiliation: 1, email: iyzhang}
  - {family: Ports, given: Dan,     affiliation: 1, email: dkp}
  - {family: Oskin, given: Mark,    affiliation: 1, email: oskin}
  - {family: Ceze,  given: Luis,    affiliation: 1, email: luisceze}

organization:
  - {id: 1, name: University of Washington}

conference:
  name: PaPoC 2015
  location: 'April 21, 2015, Bordeaux, France'
  year: 2015
  
doi: 0

layout: sigplanconf
bibliography: bibliography/biblio.bib

abstract: |
  Building database applications out of data structures rather than simple string values allows the flexibility and fine-grained control of typical key-value databases while providing better performance and scalability. Composing transactions out of linearizable data structure operations exposes concurrency in a safe way, making it simple to implement efficiently and easy to reason about.
---

# Introduction
Most web-scale services these days rely on NoSQL databases to provide scalable, fault-tolerant persistent storage.

A recent trend in the transactional memory community is to raise the level of abstraction to data structure operations to reduce the overhead of tracking individual memory accesses as well as leverage the commutativity of operations to avoid unnecessary rollbacks. [@Herlihy:PPoPP08]

# Evaluation
To show the efficacy of leveraging commutative operations, we use an application typical of web workloads: a simplified Twitter clone known as *Retwis*.
