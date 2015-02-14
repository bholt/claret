#!/usr/bin/env Rscript
source('common.R')

my_smooth <- function() stat_smooth(method=loess) #, span=0.3)

capply <- function(col, func) unlist(lapply(col, func))

data <- function(d) {
  d$failure_rate <- d$txn_failed / (d$txn_count + d$txn_failed)
  d$throughput <- d$txn_count * num(d$nclients) / d$total_time
  # d$throughput <- d$ntxns * num(d$nclients) / d$total_time
  d$avg_latency_ms <- d$txn_time / d$txn_count * 1000
  
  d$prepare_total <- d$prepare_retries + d$txn_count
  d$prepare_retry_rate <- d$prepare_retries / d$prepare_total
  
  # d$cc <- revalue(d$ccmode, c(
  #   'bottom'='base (none)',
  #   'rw'='reader/writer',
  #   'simple'='commutative'
  # ))
  
  d$ccf <- factor(d$ccmode, levels=c('simple','rw','bottom'))
  
  d$cc <- factor(revalue(d$ccmode, c(
    # 'bottom'='base',
    'rw'='reader/writer',
    'simple'='commutative'
  )), levels=c('commutative','reader/writer','base'))
  d$`Concurrency Control` <- d$cc
  
  d$Graph <- capply(d$gen, function(s) gsub('kronecker:.+','kronecker',s))
  
  
  d$workload <- factor(revalue(d$mix, c(
    'geom_repost'='repost-heavy',
    'read_heavy'='read-heavy',
    'update_heavy'='mixed'
  )), levels=c('repost-heavy','read-heavy','mixed'))
  
  d$zmix <- sprintf('%s/%s', d$mix, d$alpha)
  
  d$facet <- sprintf('shards: %d\n%s\n%d users\n%s', num(d$nshards), d$zmix, d$initusers, d$Graph)

  d$gen_label <- sprintf('%d users\n%s', d$initusers, d$Graph)
  
  return(d)
}
#
# d.all <- data(db("
#   select * from tapir where
#   generator_time is not null and total_time is not null
#   and name like 'claret-v%'
#   and nshards = 4
# ",
#   factors=c('nshards', 'nclients'),
#   numeric=c('total_time', 'txn_count')
# ))

d <- data(db("
  select * from tapir where 
  generator_time is not null and total_time is not null
  and name like 'claret-v0.14%'
",
  factors=c('nshards', 'nclients'),
  numeric=c('total_time', 'txn_count')
))

# subset(d, nclients==128 & nshards == 4 & mix == 'update_heavy', select=c('ccmode', 'gen', 'initusers', 'throughput', 'op_retries', 'op_count', 'prepare_retries'))

common_layers <- list(theme_mine
, facet_grid(.~nshards, labeller=label_pretty)
)

# save(
#   ggplot(d.all, aes(
#     x = nclients,
#     y = throughput,
#     group = ccmode,
#     fill = ccmode,
#     color = ccmode
#   ))+
#   # geom_meanbar()+
#   my_smooth()+
#   facet_wrap(~facet)+
#   expand_limits(y=0)+
#   theme_mine
# , name='throughput_compare_versions', w=6, h=7)

d.u <- subset(d, 
  nshards == 4
  # & mix == 'geom_update_heavy'
  & initusers == 4096
  # & (initusers == 1024 | initusers == 4096)
  # & initusers == 128
  # & mix == 'geom_repost'
  & grepl('geom_repost|read_heavy', mix)
)

save(
  ggplot(d.u, aes(
    x = nclients,
    y = throughput,
    group = cc,
    fill = cc,
    color = cc,
    linetype = cc
  ))+
  stat_summary(fun.y=mean, geom="line")+
  xlab('Concurrent clients')+ylab('Throughput (transactions / sec)')+
  expand_limits(y=0)+
  facet_wrap(~workload)+
  theme_mine+theme(legend.position='top', legend.direction='horizontal')+
  cc_scales()
, name='throughput', w=4, h=4)

save(
  ggplot(d, aes(
    x = nclients,
    y = throughput,
    group = `Concurrency Control`,
    fill = `Concurrency Control`,
    color = `Concurrency Control`
  ))+
  # geom_meanbar()+
  my_smooth()+
  # facet_grid(nshards~initusers, labeller=label_pretty)+
  facet_wrap(~facet)+
  expand_limits(y=0)+
  theme_mine
, name='throughput_explore', w=8, h=7)

# save(
#   ggplot(d.u, aes(
#       x = nclients,
#       y = avg_latency_ms,
#       group = `Concurrency Control`,
#       fill = `Concurrency Control`,
#       color = `Concurrency Control`
#   ))+
#   my_smooth()+
#   geom_hline(y=0)+
#   facet_wrap(~gen_label)+
#   expand_limits(y=0)+
#   theme_mine
# , name='avg_latency', w=4, h=5)
#
# save(
#   ggplot(d, aes(
#       x = nclients,
#       y = avg_latency_ms,
#       group = `Concurrency Control`,
#       fill = `Concurrency Control`,
#       color = `Concurrency Control`
#   ))+
#   # geom_meanbar()+
#   # stat_summary(fun.y='mean', geom='bar', position='dodge')+
#   geom_hline(y=0)+
#   my_smooth()+
#   common_layers+
#   expand_limits(y=0)+
#   facet_grid(nshards~initusers, labeller=label_pretty)
# , name='avg_latency_explore', w=8, h=6)

# subset(d.u, select=c('nshards','nclients','Graph','Concurrency Control','abort_rate','throughput'))

save(
  ggplot(d, aes(
      x = nclients,
      y = prepare_retry_rate,
      group = `Concurrency Control`,
      fill = `Concurrency Control`,
      color = `Concurrency Control`
  ))+
  my_smooth()+
  facet_wrap(~facet)+
  theme_mine
, name='retry_rate', w=7, h=8)

save(
  ggplot(subset(d, initusers == 1024), aes(
      x = nclients,
      y = server_cc_check_success,
      group = `Concurrency Control`,
      fill = `Concurrency Control`,
      color = `Concurrency Control`
  ))+
  my_smooth()+
  ylab('success rate')+
  facet_wrap(~facet)+
  theme_mine
, name='cc_check_rate', w=7, h=12)

# save(
#   ggplot(d.u, aes(
#       x = nclients,
#       y = failure_rate,
#       group = `Concurrency Control`,
#       fill = `Concurrency Control`,
#       color = `Concurrency Control`
#   ))+
#   my_smooth()+
#   facet_wrap(~facet)+
#   theme_mine
# , name='failure_rates', w=7, h=5)

save(
  ggplot(d, aes(
      x = nclients,
      y = failure_rate,
      group = `Concurrency Control`,
      fill = `Concurrency Control`,
      color = `Concurrency Control`
  ))+
  my_smooth()+
  common_layers+
  facet_wrap(~facet)
, name='failure_rates_exploration', w=7, h=7)

d$op_retries_total <- d$op_retries * num(d$nclients)
d$op_retry_ratio <- d$op_retries / d$op_count

# save(
#   ggplot(subset(d), aes(
#       x = nclients,
#       y = op_retry_ratio,
#       group = `Concurrency Control`,
#       fill = `Concurrency Control`,
#       color = `Concurrency Control`
#   ))+
#   my_smooth()+
#   common_layers+
#   geom_hline(y=0)+
#   # facet_grid(nshards~initusers, labeller=label_pretty)
#   facet_wrap(~facet)
# , name='op_retries', w=8, h=6)
#

d.u$retwis_newuser_latency <- d.u$retwis_newuser_time / d.u$retwis_newuser_count
d.u$retwis_post_latency <- d.u$retwis_post_time / d.u$retwis_post_count
d.u$retwis_repost_latency <- d.u$retwis_repost_time / d.u$retwis_repost_count
d.u$retwis_timeline_latency <- d.u$retwis_timeline_time / d.u$retwis_timeline_count
d.u$retwis_follow_latency <- d.u$retwis_follow_time / d.u$retwis_follow_count

# save(
#   ggplot(d.u, aes(
#       x = nclients,
#       y = retwis_repost_latency * 1000,
#       group = `Concurrency Control`,
#       color = `Concurrency Control`,
#       fill = `Concurrency Control`
#   ))+
#   my_smooth()+
#   facet_wrap(~Graph)+
#   theme_mine
# , name='repost_txn_latency', w=4, h=3)
#


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
  my_smooth()+
  facet_grid(ccmode~facet)+
  theme_mine
, name='txn_breakdown_latency', w=8, h=6)


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
d.ct$txn_fraction <- d.ct$total_count / (d.ct$txn_count*num(d.ct$nclients))

save(
  ggplot(subset(d.ct, nclients == 64), aes(
      x = txn_type,
      y = total_count,
      group = txn_type,
      fill = txn_type,
      label = total_count,
  ))+
  # scale_y_log10()+
  geom_meanbar()+
  stat_summary(aes(label=round(..y..,2)), fun.y=mean, geom="text", size=2,
               vjust = -0.5)+
  # facet_wrap(~facet)+
  facet_grid(initusers~zmix)+
  theme_mine
, name='txn_counts', w=8, h=6)

d.u$total <- d.u$server_ops_read + d.u$server_ops_write
d.u$read <- d.u$server_ops_read / d.u$total
d.u$write <- d.u$server_ops_write / d.u$total
d.rw <- melt(d.u, measure=c('read', 'write'))
d.rw$op_type <- d.rw$variable
# d.rw$op_count <- d.rw$value * num(d.rw$nclients)
save(
  ggplot(subset(d.rw, nclients == 32 & op_count > 0), aes(
    x = op_type,
    y = value,
    group = op_type,
    fill = op_type,
    label = value,
  ))+
  geom_meanbar()+
  stat_summary(aes(label=round(..y..,2)), fun.y=mean, geom="text", size=2,
               vjust = -0.5)+
  # facet_wrap(~facet)+
  facet_grid(initusers~zmix)+
  theme_mine
, name='op_rw', w=8, h=6)


d.s <- subset(d,
  nshards == 4
  # & initusers == 4096
)

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
  my_smooth()+
  # common_layers+
  facet_wrap(~facet)+
  theme_mine
  # facet_grid(Graph~ccmode, labeller=label_pretty)
, name='txn_breakdown', w=8, h=6)

#
# d.s$newuser_retry_rate <- d.s$retwis_newuser_retries / (d.s$retwis_newuser_count + d.s$retwis_newuser_retries)
# d.s$post_retry_rate <- d.s$retwis_post_retries / (d.s$retwis_post_count + d.s$retwis_post_retries)
# d.s$repost_retry_rate <- d.s$retwis_repost_retries / (d.s$retwis_repost_count + d.s$retwis_repost_retries)
# d.s$timeline_retry_rate <- d.s$retwis_timeline_retries / (d.s$retwis_timeline_count + d.s$retwis_timeline_retries)
# d.s$follow_retry_rate <- d.s$retwis_follow_retries / (d.s$retwis_follow_count + d.s$retwis_follow_retries)
#
# d.m <- melt(d.s,
#   measure=c(
#     'newuser_retry_rate',
#     'post_retry_rate',
#     'repost_retry_rate',
#     'timeline_retry_rate',
#     'follow_retry_rate'
#   )
# )
# d.m$txn_type <- unlist(lapply(
#   d.m$variable,
#   function(s) gsub('(\\w+)_retry_rate','\\1', s))
# )
# # d.m$retries <- num(d.m$value) * num(d.m$nclients)
# d.m$retry_rate <- d.m$value
#
# save(
#   ggplot(d.m, aes(
#       x = nclients,
#       y = retry_rate,
#       fill = txn_type,
#       color = txn_type,
#       group = txn_type,
#   ))+
#   ylab('retry rate')+
#   my_smooth()+
#   common_layers+
#   facet_wrap(~facet)
#   # facet_grid(Graph~ccmode, labeller=label_pretty)
# , name='txn_breakdown_retries', w=8, h=6)

print("success!")