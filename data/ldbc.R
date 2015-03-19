#!/usr/bin/env Rscript
# setwd('/Users/bholt/hub/claret/data')
source('common.R')

d <- data.ldbc(where="name like '%-multinode'")
# d$ntotal <- factor(d$ntotal)

save(
  ggplot(subset(d,
    # ccmode == 'simple'
    ntotal == 50000
    # & name == 'Query2'
  ), aes(
    x = snb_time_ratio,
    y = total_time / 1e6,
    group = cc,
    fill = cc,
    color = cc,
    label = ntotal,
  ))+
  geom_point()+
  # geom_text(size=1.7)+
  # stat_summary(aes(label=ntotal), fun.y=mean, geom="text")+
  stat_smooth()+
  expand_limits(y=0)+
  facet_wrap(~name)+
  scale_x_log10(breaks=trans_breaks("log10", function(x) 10^x),
                labels=trans_format("log10", math_format(10^.x)))+
  my_theme()
  # scale_fill_manual(values=my_palette, name='Variant')+
  # scale_color_manual(values=my_palette, name='Variant')
, name='ldbc_explore', w=10, h=8)

save(
  ggplot(subset(d,
    # ccmode == 'simple'
    ntotal == 50000
    # & name == 'Query2'
  ), aes(
    x = snb_time_ratio,
    y = total_time / 1e6,
    group = cc,
    fill = cc,
    color = cc,
    label = ntotal,
  ))+
  geom_point()+
  # geom_text(size=1.7)+
  # stat_summary(aes(label=ntotal), fun.y=mean, geom="text")+
  stat_smooth()+
  expand_limits(y=0)+
  facet_wrap(~name)+
  scale_x_log10(breaks=trans_breaks("log10", function(x) 10^x),
                labels=trans_format("log10", math_format(10^.x)))+
  my_theme()
  # scale_fill_manual(values=my_palette, name='Variant')+
  # scale_color_manual(values=my_palette, name='Variant')
, name='explore_retries', w=10, h=8)

