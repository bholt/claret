#!/usr/bin/env Rscript
source('common.R')

my_smooth <- function() stat_smooth(method=loess) #, span=0.3)
cc_line <- function() list(
  stat_summary(fun.y=mean, geom='line'),
  cc_scales()
)

capply <- function(col, func) unlist(lapply(col, func))

data <- function(d) {
  d$failure_rate <- d$txn_failed / (d$txn_count + d$txn_failed)
  d$throughput <- d$txn_count * num(d$nclients) / d$total_time
  # d$throughput <- d$ntxns * num(d$nclients) / d$total_time
  d$avg_latency_ms <- d$txn_time / d$txn_count * 1000
  
  d$prepare_total <- d$prepare_retries + d$txn_count
  d$prepare_retry_rate <- d$prepare_retries / d$prepare_total
    
  d$cc <- factor(revalue(d$ccmode, c(
    'rw'='reader/writer',
    'simple'='commutative'
  )), levels=c('commutative','reader/writer','base'))
  d$`Concurrency Control` <- d$cc
  
  d$opmix <- factor(revalue(d$mix, c(
    'mostly_update'='35% read / 65% update',
    'update_heavy'='50% read / 50% update',
    'read_heavy'='90% read / 10% update'
  )))
  
  d$zmix <- sprintf('%s/%s', d$mix, d$alpha)
  d$facet <- sprintf('%s\n%d keys', d$zmix, d$nkeys)
  
  return(d)
}

d <- data(db("
  select * from tapir where 
  total_time is not null
  and name like 'stress-v0.14%'
",
  factors=c('nshards', 'nclients'),
  numeric=c('total_time', 'txn_count')
))

d$op_retries_total <- d$op_retries * num(d$nclients)
d$op_retry_ratio <- d$op_retries / d$op_count

d.u <- subset(d, 
  nshards == 4
  & nkeys == 10000
)

save(
  ggplot(subset(d, nkeys == 10000 & alpha == 0.6 & grepl('update_heavy|read_heavy', mix) & nclients != 48), aes(
    x = nclients,
    y = throughput,
    group = cc,
    fill = cc,
    color = cc,
    linetype = cc
  ))+
  theme_mine+
  cc_line()+
  xlab('Concurrent clients')+ylab('Throughput (transactions / sec)')+
  facet_wrap(~opmix)+
  theme(legend.position="top")+
  expand_limits(y=0)
, name='stress_throughput', w=4, h=4)

save(
  ggplot(d, aes(
    x = nclients,
    y = throughput,
    group = `Concurrency Control`,
    fill = `Concurrency Control`,
    color = `Concurrency Control`
  ))+
  theme_mine+
  my_smooth()+
  facet_wrap(~facet)+
  expand_limits(y=0)
, name='stress_throughput_explore', w=8, h=8)

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
#   facet_wrap(~opmix)+
#   expand_limits(y=0)+
#   theme_mine
# , name='avg_latency', w=4, h=5)

# save(
#   ggplot(d.u, aes(
#       x = nclients,
#       y = prepare_retry_rate,
#       group = `Concurrency Control`,
#       fill = `Concurrency Control`,
#       color = `Concurrency Control`
#   ))+
#   my_smooth()+
#   facet_wrap(~facet)+
#   theme_mine
# , name='retry_rate', w=7, h=8)

save(
  ggplot(d.u, aes(
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
, name='stress_check_rate', w=7, h=12)

save(
  ggplot(d.u, aes(
      x = nclients,
      y = failure_rate,
      group = cc,
      fill = cc,
      color = cc
  ))+
  my_smooth()+
  facet_wrap(~facet)+
  theme_mine
, name='stress_failure_rates', w=7, h=5)

# save(
#   ggplot(d.u, aes(
#       x = nclients,
#       y = op_retry_ratio,
#       group = `Concurrency Control`,
#       fill = `Concurrency Control`,
#       color = `Concurrency Control`
#   ))+
#   my_smooth()+
#   geom_hline(y=0)+
#   facet_wrap(~facet)+
#   theme_mine
# , name='op_retries', w=8, h=6)
#

d$total <- d$server_ops_read + d$server_ops_write
d$read <- d$server_ops_read * num(d$nshards) # / d$total
d$write <- d$server_ops_write * num(d$nshards) # / d$total
d.rw <- melt(d, measure=c('read', 'write'))
d.rw$op_type <- d.rw$variable
save(
  ggplot(subset(d.rw, nshards == 4 & nclients == 32), aes(
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
  facet_grid(cc~length~nkeys~zmix)+
  theme_mine
, name='op_rw', w=12, h=6)

print("success!")