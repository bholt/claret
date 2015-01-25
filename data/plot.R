#!/usr/bin/env Rscript
source('common.R')

d <- db('select * from tapir',
        factors=c('nshards'),
        numeric=c('total_time', 'txn_count'))

d$txn_abort_rate <- d$txn_failed / d$txn_count + d$txn_failed
d$throughput <- d$txn_count * d$nclients / d$total_time

common_layers <- list(theme_mine
, facet_grid(nshards~., labeller=label_pretty)
)

save(ggplot(d, aes(
    x = nclients,
    y = throughput,
    fill = nshards,
    group = nshards,
    # color = nshards
  ))+
  geom_meanbar()+
  common_layers
)
