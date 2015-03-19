#!/usr/bin/env Rscript
source('common.R')

d <- claret_data("name like 'claret-v0.14%'")

d$cc_approx <- sprintf('%s:%s', d$ccmode, d$approx)
d$variant <- revalue(d$cc_approx, c(
  'rw:1'='reader/writer',
  'simple:0'='precise',
  'simple:1'='approx'
))


save(
  ggplot(subset(d, initusers==4096 & nshards == 4 & nclients != 96), aes(
    x = nclients,
    y = throughput / 1000,
    group = variant,
    fill = variant,
    color = variant,
    linetype = cc
  ))+
  #stat_summary(fun.y=mean, geom="line")+
  stat_smooth()+
  xlab('Concurrent clients')+ylab('Throughput (k / sec)')+
  expand_limits(y=0)+
  facet_wrap(~workload)+
  my_theme()+
  scale_fill_manual(values=my_palette, name='Variant')+
  scale_color_manual(values=my_palette, name='Variant')+
  scale_linetype_manual(name='Mode', values=c('commutative'=1,'reader/writer'=2))+
  theme(legend.position='top', legend.direction='horizontal')
, name='approx_throughput_explore', w=8, h=8)
