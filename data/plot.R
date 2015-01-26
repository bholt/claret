#!/usr/bin/env Rscript
source('common.R')

d <- db('select * from tapir where 
  generator_time is not null and total_time is not null',
        factors=c('nshards', 'nclients'),
        numeric=c('total_time', 'txn_count'))

d$txn_abort_rate <- d$txn_failed / d$txn_count + d$txn_failed
d$throughput <- d$txn_count * as.numeric(d$nclients) / d$total_time

common_layers <- list(theme_mine
, facet_grid(.~nshards, labeller=label_pretty)
)

save(
  ggplot(d, aes(
    x = nclients,
    y = throughput,
    fill = nshards,
    group = nshards,
    # color = nshards
  ))+
  geom_meanbar()+
  common_layers
, w=4, h=3)


d.m <- melt(d, 
  measure=c(
    'retwis_newuser_success',
    'retwis_post_success',
    'retwis_timeline_success',
    'retwis_follow_success'
  )
)
d.m$txn_type <- unlist(lapply(
  d.m$variable,
  function(s) gsub('retwis_(\\w+)_success','\\1', s))
)
save(
  ggplot(d.m, aes(
      x = nclients,
      y = value,
      fill = txn_type,
  ))+
  # geom_meanbar()+
  stat_summary(fun.y='mean', geom='bar', position='dodge')+
  common_layers+
  facet_grid(nshards~initusers, labeller=label_pretty)
, name='abort_rates', w=8, h=6)
