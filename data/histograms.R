#!/usr/bin/env Rscript
source('common.R')

df <- subset(db("select * from tapir where stat_following_counts is not null and name like '%v0.14%'"),
  nclients == 32
  & initusers == 4096
)
df$grp <- with(df, sprintf("%s\n%s\nmix:%s/%s,\n%s", name, ccmode, mix, alpha, gen))


histogram.facets <- function(df, measure, grp) {
  d <- data.frame(x=c(),y=c(),version=c())
  for (i in 1:nrow(df)) {
    d <- rbind(d, df.histogram(df[i,measure], df[i,grp]))
  }
  return(d)
}

d.repost <- histogram.facets(subset(df, initusers == 4096 & mix == 'geom_repost'), 'stat_repost_counts', 'grp')
save(
  ggplot(d.repost, aes(x=x, weight=y))+
    # stat_summary(fun.y=sum, geom='bar', fill=c.blue)+
    # geom_bar(stat="identity", fill=c.blue)+
    # geom_histogram(binwidth=.1, fill=c.blue)+
    stat_ecdf(color=c.blue)+
    xlab('# reposts')+ylab('count')+
    scale_x_log10(breaks=c(1,10,100,1000))+scale_y_log10(breaks=c(0.1,0.2,0.4,0.6,0.8,1.0))+
    # scale_x_log10(breaks = trans_breaks("log10", function(x) 10^x),
    #               labels = trans_format("log10", function(x) round(10^x, digits=2)))+
    # scale_y_log10(breaks = trans_breaks("log10", function(x) 10^x),
    #               labels = trans_format("log10", function(x) round(10^x, digits=2)))+
    
    xlab('# reposts (log scale)')+ylab('CDF (log scale)')+
    # facet_wrap(~version, scale="free")+
    theme_mine
, name='hist_reposts', w=4, h=4)


d.post <- histogram.facets(df, 'stat_post_counts', 'grp')
save(
  ggplot(d.post, aes(x=x, weight=y))+
    # stat_summary(fun.y=sum, geom='bar', fill=c.blue)+
    # geom_bar(stat="identity", fill=c.blue)+
    geom_histogram(binwidth=1, fill=c.blue)+
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
    geom_histogram(binwidth=0.1, fill=c.blue)+
    stat_ecdf()+
    xlab('# followers / user')+ylab('count')+
    scale_y_log10()+scale_x_log10()+
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
