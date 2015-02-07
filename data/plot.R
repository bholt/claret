#!/usr/bin/env Rscript
source('common.R')

capply <- function(col, func) unlist(lapply(col, func))

data <- function(d) {
  d$abort_rate <- d$txn_failed / (d$txn_count + d$txn_failed)
  d$throughput <- d$txn_count * num(d$nclients) / d$total_time
  # d$throughput <- d$ntxns * num(d$nclients) / d$total_time
  d$avg_latency_ms <- d$txn_time / d$txn_count * 1000
  
  d$`Concurrency Control` <- revalue(d$ccmode, c(
    'bottom'='base (none)',
    'rw'='reader/writer',
    'simple'='commutative'
  ))
  
  d$Graph <- capply(d$gen, function(s) gsub('kronecker:.+','kronecker',s))
  
  d$facet <- sprintf('sh: %d, u: %d, g: %s', num(d$nshards), d$initusers, d$Graph)

  d$gen_label <- sprintf('%d users\n%s', d$initusers, d$Graph)
  
  return(d)
}

d.all <- data(db("
  select * from tapir where 
  generator_time is not null and total_time is not null
  and name like 'claret-v%'
",
  factors=c('nshards', 'nclients'),
  numeric=c('total_time', 'txn_count')
))

d <- data(db("
  select * from tapir where 
  generator_time is not null and total_time is not null
  and name like 'claret-v0.5.1%'
  and ccmode != 'bottom'
",
  factors=c('nshards', 'nclients'),
  numeric=c('total_time', 'txn_count')
))

common_layers <- list(theme_mine
, facet_grid(.~nshards, labeller=label_pretty)
)

save(
  ggplot(d.all, aes(
    x = nclients,
    y = throughput,
    group = ccmode,
    fill = ccmode,
    color = ccmode
  ))+
  # geom_meanbar()+
  stat_smooth()+
  facet_wrap(~name)+
  theme_mine
, name='throughput_compare_versions', w=6, h=7)

d.u <- subset(d, (initusers == 4096 | initusers == 512) & nshards == 4)

save(
  ggplot(d.u, aes(
    x = nclients,
    y = throughput,
    group = `Concurrency Control`,
    fill = `Concurrency Control`,
    color = `Concurrency Control`
  ))+
  # geom_meanbar()+
  stat_smooth()+
  facet_wrap(~gen_label)+
  theme_mine
, name='throughput', w=4, h=5)

save(
  ggplot(d, aes(
    x = nclients,
    y = throughput,
    group = `Concurrency Control`,
    fill = `Concurrency Control`,
    color = `Concurrency Control`
  ))+
  # geom_meanbar()+
  stat_smooth()+
  # facet_grid(nshards~initusers, labeller=label_pretty)+
  facet_wrap(~facet)+
  theme_mine
, name='throughput_explore', w=8, h=7)

save(
  ggplot(d.u, aes(
      x = nclients,
      y = avg_latency_ms,
      group = `Concurrency Control`,
      fill = `Concurrency Control`,
      color = `Concurrency Control`
  ))+
  stat_smooth()+
  geom_hline(y=0)+
  facet_wrap(~gen_label)+
  theme_mine
, name='avg_latency', w=4, h=5)

save(
  ggplot(d, aes(
      x = nclients,
      y = avg_latency_ms,
      group = `Concurrency Control`,
      fill = `Concurrency Control`,
      color = `Concurrency Control`
  ))+
  # geom_meanbar()+
  # stat_summary(fun.y='mean', geom='bar', position='dodge')+
  stat_smooth()+
  common_layers+
  geom_hline(y=0)+
  facet_grid(nshards~initusers, labeller=label_pretty)
, name='avg_latency_explore', w=8, h=6)

# subset(d.u, select=c('nshards','nclients','Graph','Concurrency Control','abort_rate','throughput'))

save(
  ggplot(d.u, aes(
      x = nclients,
      y = abort_rate,
      group = `Concurrency Control`,
      fill = `Concurrency Control`,
      color = `Concurrency Control`
  ))+
  stat_smooth()+
  facet_wrap(~gen_label)+
  theme_mine
, name='abort_rates', w=4, h=5)

save(
  ggplot(d, aes(
      x = nclients,
      y = abort_rate,
      group = `Concurrency Control`,
      fill = `Concurrency Control`,
      color = `Concurrency Control`
  ))+
  # geom_meanbar()+
  # stat_summary(fun.y='mean', geom='bar', position='dodge')+
  stat_smooth()+
  common_layers+
  # geom_hline(y=0)+
  facet_wrap(~facet)
, name='abort_rates_exploration', w=7, h=7)

d$op_retries_total <- d$op_retries * num(d$nclients)
d$op_retry_ratio <- d$op_retries / d$op_count

save(
  ggplot(subset(d), aes(
      x = nclients,
      y = op_retry_ratio,
      group = `Concurrency Control`,
      fill = `Concurrency Control`,
      color = `Concurrency Control`
  ))+
  stat_smooth()+
  common_layers+
  geom_hline(y=0)+
  # facet_grid(nshards~initusers, labeller=label_pretty)
  facet_wrap(~facet)
, name='op_retries', w=8, h=6)


d.u$retwis_newuser_latency <- d.u$retwis_newuser_time / d.u$retwis_newuser_count
d.u$retwis_post_latency <- d.u$retwis_post_time / d.u$retwis_post_count
d.u$retwis_repost_latency <- d.u$retwis_repost_time / d.u$retwis_repost_count
d.u$retwis_timeline_latency <- d.u$retwis_timeline_time / d.u$retwis_timeline_count
d.u$retwis_follow_latency <- d.u$retwis_follow_time / d.u$retwis_follow_count

save(
  ggplot(d.u, aes(
      x = nclients,
      y = retwis_repost_latency * 1000,
      group = `Concurrency Control`,
      color = `Concurrency Control`,
      fill = `Concurrency Control`
  ))+
  stat_smooth()+
  facet_wrap(~Graph)+
  theme_mine
, name='repost_txn_latency', w=4, h=3)



d.lat <- melt(d.u,
  measure=c(
    'retwis_newuser_latency',
    'retwis_post_latency',
    'retwis_repost_latency',
    'retwis_timeline_latency',
    'retwis_follow_latency'
  )
)
d.lat$txn_type <- capply(d.lat$variable, function(s) gsub('retwis_(\\w+)_latency','\\1', s))
d.lat$latency_ms <- d.lat$value * 1000
save(
  ggplot(d.lat, aes(
      x = nclients,
      y = latency_ms,
      group = txn_type,
      color = txn_type,
      fill = txn_type
  ))+
  stat_smooth()+
  facet_wrap(~Graph)+
  theme_mine
, name='txn_breakdown_latency', w=4, h=3)


d.ct <- melt(d.u,
  measure=c(
    'retwis_newuser_count',
    'retwis_post_count',
    'retwis_repost_count',
    'retwis_timeline_count',
    'retwis_follow_count'
  )
)

d.ct$txn_type <- capply(d.ct$variable, function(s) gsub('retwis_(\\w+)_count','\\1', s))
d.ct$total_count <- d.ct$value * num(d.ct$nclients)

save(
  ggplot(d.ct, aes(
      x = txn_type,
      y = total_count,
      group = txn_type,
      fill = txn_type
  ))+
  geom_meanbar()+
  facet_wrap(~Graph)+
  theme_mine
, name='txn_counts', w=4, h=3)


d.s <- subset(d, nshards == 4 & initusers == 4096)

d.m <- melt(d.s,
  measure=c(
    'retwis_newuser_success',
    'retwis_post_success',
    'retwis_repost_success',
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
  # stat_summary(fun.y='mean', geom='smooth')+
  stat_smooth()+
  common_layers+
  # facet_wrap(~facet)
  facet_grid(Graph~ccmode, labeller=label_pretty)
, name='txn_breakdown', w=8, h=6)


d.m <- melt(d.s,
  measure=c(
    'retwis_newuser_retries',
    'retwis_post_retries',
    'retwis_repost_retries',
    'retwis_timeline_retries',
    'retwis_follow_retries'
  )
)
d.m$txn_type <- unlist(lapply(
  d.m$variable,
  function(s) gsub('retwis_(\\w+)_retries','\\1', s))
)
d.m$retries <- num(d.m$value) * num(d.m$nclients)

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
  # facet_wrap(~facet)
  facet_grid(Graph~ccmode, labeller=label_pretty)
, name='txn_breakdown_retries', w=8, h=6)
