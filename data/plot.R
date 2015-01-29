#!/usr/bin/env Rscript
source('common.R')

d <- db("
  select * from tapir where 
  generator_time is not null and total_time is not null
  and (initusers = 50 or initusers = 500)
  and name like 'claret-v0.2%'
",
  factors=c('nshards', 'nclients'),
  numeric=c('total_time', 'txn_count')
)

d$abort_rate <- d$txn_failed / (d$txn_count + d$txn_failed)
d$throughput <- d$txn_count * as.numeric(d$nclients) / d$total_time
d$avg_latency_ms <- d$txn_time / d$txn_count * 1000

common_layers <- list(theme_mine
, facet_grid(.~nshards, labeller=label_pretty)
)

save(
  ggplot(d, aes(
    x = nclients,
    y = throughput,
    group = ccmode,
    fill = ccmode,
    color = ccmode
  ))+
  # geom_meanbar()+
  stat_smooth()+
  common_layers
, name='throughput', w=4, h=3)

save(
  ggplot(d, aes(
      x = nclients,
      y = avg_latency_ms,
      group = ccmode,
      fill = ccmode,
      color = ccmode
  ))+
  # geom_meanbar()+
  # stat_summary(fun.y='mean', geom='bar', position='dodge')+
  stat_smooth()+
  common_layers+
  geom_hline(y=0)+
  facet_grid(nshards~initusers, labeller=label_pretty)
, name='avg_latency', w=8, h=6)

save(
  ggplot(d, aes(
      x = nclients,
      y = abort_rate,
      group = ccmode,
      fill = ccmode,
      color = ccmode
  ))+
  # geom_meanbar()+
  # stat_summary(fun.y='mean', geom='bar', position='dodge')+
  stat_smooth()+
  common_layers+
  geom_hline(y=0)+
  facet_grid(nshards~initusers, labeller=label_pretty)
, name='abort_rates', w=8, h=6)

d$op_retries_total <- d$op_retries * num(d$nclients)
d$op_retry_ratio <- d$op_retries / d$op_count

save(
  ggplot(d, aes(
      x = nclients,
      y = op_retry_ratio,
      group = ccmode,
      fill = ccmode,
      color = ccmode
  ))+
  stat_smooth()+
  common_layers+
  geom_hline(y=0)+
  facet_grid(nshards~initusers, labeller=label_pretty)
, name='op_retries', w=8, h=6)


d.m <- melt(subset(d, ccmode == 'simple'),
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
# d.m$grp <- sprintf('s:%d, c:%d, u:%d', d.m$nshards, d.m$nclients, d.m$initusers)
#
# d.m$grp
#
# save(
#   ggplot(d.m, aes(
#       x = txn_type,
#       y = value,
#       fill = txn_type,
#       color = txn_type,
#       group = grp,
#   ))+
#   # geom_meanbar()+
#   stat_summary(fun.y='mean', geom='bar', position='dodge')+
#   # stat_summary(fun.y='mean', geom='line')+
#   common_layers+
#   # facet_grid(nshards~initusers, labeller=label_pretty)
#   facet_wrap(~grp, ncol=nlevels(d.m$nclients))
# , name='abort_breakdown', w=8, h=6)

save(
  ggplot(d.m, aes(
      x = nclients,
      y = value,
      fill = txn_type,
      color = txn_type,
      group = txn_type,
  ))+
  ylab('success rate')+
  # geom_meanbar()+
  stat_summary(fun.y='mean', geom='smooth')+
  common_layers+
  facet_grid(nshards~initusers, labeller=label_pretty)
, name='txn_breakdown', w=8, h=6)


d.m <- melt(subset(d, ccmode == 'simple'),
  measure=c(
    'retwis_newuser_retries',
    'retwis_post_retries',
    'retwis_timeline_retries',
    'retwis_follow_retries'
  )
)
d.m$txn_type <- unlist(lapply(
  d.m$variable,
  function(s) gsub('retwis_(\\w+)_retries','\\1', s))
)
d.m$retries <- d.m$values * num(d.m$nclients)

save(
  ggplot(d.m, aes(
      x = nclients,
      y = retries,
      fill = txn_type,
      color = txn_type,
      group = txn_type,
  ))+
  ylab('retries')+
  stat_smooth()+
  common_layers+
  facet_grid(nshards~initusers, labeller=label_pretty)
, name='txn_breakdown_retries', w=8, h=6)
