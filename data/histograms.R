#!/usr/bin/env Rscript
source('common.R')

df <- db("
  select * from tapir
  where stat_following_counts is not null
  and mix like '%geom%'
")
df$grp <- with(df, sprintf("%s\n%s\nmix:%s,\n%s\nclients:%d", name, ccmode, mix, gen, nclients))


histogram.facets <- function(df, measure, grp) {
  d <- data.frame(x=c(),y=c(),version=c())
  for (i in 1:nrow(df)) {
    d <- rbind(d, df.histogram(df[i,measure], df[i,grp]))
  }
  return(d)
}

d.repost <- histogram.facets(df, 'stat_repost_counts', 'grp')
save(
  ggplot(d.repost, aes(x=x, weight=y))+
    # stat_summary(fun.y=sum, geom='bar', fill=c.blue)+
    # geom_bar(stat="identity", fill=c.blue)+
    # geom_histogram(binwidth=.1, fill=c.blue)+
    stat_ecdf()+
    xlab('# reposts')+ylab('count')+
    scale_y_log10()+scale_x_log10()+
    facet_wrap(~version, scale="free")+
    theme_mine
, name='hist_reposts', w=8, h=8)


d.post <- histogram.facets(df, 'stat_post_counts', 'grp')
save(
  ggplot(subset(d.post, x > 0), aes(x=x, weight=y))+
    # stat_summary(fun.y=sum, geom='bar', fill=c.blue)+
    # geom_bar(stat="identity", fill=c.blue)+
    geom_histogram(binwidth=2, fill=c.blue)+
    xlab('# posts / user')+ylab('count')+
    # scale_y_log10()+
    facet_wrap(~version, scale="free")+
    theme_mine
, name='hist_posts', w=8, h=8)


d.follow <- histogram.facets(df, 'stat_follower_counts', 'grp')
save(
  ggplot(d.follow, aes(x=x, weight=y))+
    # stat_summary(fun.y=sum, geom='bar', fill=c.blue)+
    # geom_bar(stat="identity", fill=c.blue)+
    geom_histogram(binwidth=2, fill=c.blue)+
    xlab('# followers / user')+ylab('count')+
    # scale_y_log10()+
    facet_wrap(~version, scale="free")+
    theme_mine
, name='hist_followers', w=8, h=8)

d.follow <- histogram.facets(df, 'stat_following_counts', 'grp')
save(
  ggplot(d.follow, aes(x=x, weight=y))+
    # stat_summary(fun.y=sum, geom='bar', fill=c.blue)+
    # geom_bar(stat="identity", fill=c.blue)+
    geom_histogram(binwidth=2, fill=c.blue)+
    xlab('# following / user')+ylab('count')+
    # scale_y_log10()+
    facet_wrap(~version, scale="free")+
    theme_mine
, name='hist_following', w=8, h=8)
