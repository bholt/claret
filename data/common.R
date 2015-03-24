suppressPackageStartupMessages(require(RMySQL))
suppressPackageStartupMessages(require(sqldf))
suppressPackageStartupMessages(require(ggplot2))
suppressPackageStartupMessages(require(reshape))
options(RMySQL.dbname="claret") # (rest comes from $HOME/.my.cnf)

suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(scales))

json.to.df <- function(jstr) {
  d <- fromJSON(jstr)
  return(data.frame(x=names(d),y=unlist(d)))
}


db <- function(query, factors=c(), numeric=c()) {
  d <- sqldf(query)
  d[factors] <- lapply(d[factors], factor)
  d[numeric] <- lapply(d[numeric], as.numeric)
  return(d)
}

num <- function(var) as.numeric(as.character(var))

capply <- function(col, func) unlist(lapply(col, func))

df.histogram <- function(json, version="none") {
  d <- fromJSON(json)
  return(data.frame(x=num(names(d)), y=num(unlist(d)), version=version))
}


save <- function(g, name=FILE_BASE, file=sprintf("%s/%s.pdf",FILE_DIR,name), w=3.3, h=3.1) {
  ggsave(plot=g, filename=file, width=w, height=h)
  print(sprintf("saved: %s", file))
}

prettify <- function(str) gsub('_',' ',gsub('([a-z])([a-z]+)',"\\U\\1\\E\\2",str,perl=TRUE))

regex_match <- function(reg,str) length(grep(reg,str)) > 0

label_pretty <- function(variable, value) {
  vname <- if (regex_match('variable|value',variable)) '' else sprintf('%s:', variable)
  lapply(paste(vname, prettify(as.character(value))), paste, collapse="\n")
}

geom_mean <- function(geom) stat_summary(fun.y='mean', geom=geom, labeller=label_pretty)

geom_meanbar <- function(labeller=label_pretty) {
  return(list(
    stat_summary(fun.y=mean, geom='bar', position='dodge'),
    stat_summary(fun.data=mean_cl_normal, geom='errorbar', width=0.2, position='dodge')
  ))
}

c.blue   <- "#0072B2"
c.yellow <- "#E69F00"
c.green  <- "#009E73"
c.red    <- "#D55E00"
c.pink   <- "#CC79A7"
c.gray   <- "#999999"

my_palette <- c(
  'rw'=c.yellow,
  'simple'=c.blue,
  
  'reader/writer'=c.yellow,
  'commutative'=c.blue,

  'approx'=c.green,
  'precise'=c.blue,
  
  'follow'=c.blue,
  'newuser'=c.yellow,
  'post'=c.green,
  'repost'=c.red,
  'timeline'=c.pink,
  
  'kronecker'=c.blue,
  
  'read'=c.pink,
  'write'=c.green,
  
  'none'=c.gray  
)

# The palette with grey:
cbPalette <- c("#0072B2", "#E69F00", "#009E73", "#D55E00", "#CC79A7", "#56B4E9", "#F0E442", "#999999")

my_colors <- function(title="") list(
  scale_fill_manual(values=my_palette, name=title),
  # To use for line and point colors, add
  scale_color_manual(values=my_palette, name=title)
)

cc_scales <- function(field=cc, title="Concurrency control:") list(
  scale_fill_manual(values=my_palette, name=title),
  scale_color_manual(values=my_palette, name=title),
  scale_linetype_manual(name=title, values=c('commutative'=1,'reader/writer'=2))
)

my_theme <- function() theme(
  panel.background = element_rect(fill="white"),
  panel.border = element_rect(fill=NA, color="grey50"),
  panel.grid.major = element_line(color="grey80", size=0.2),
  panel.grid.minor = element_line(color="grey90", size=0.2),
  strip.background = element_rect(fill="grey90", color="grey50"),
  strip.background = element_rect(fill="grey80", color="grey50"),
  axis.ticks = element_line(colour="black"),
  panel.grid = element_line(colour="black"),
  axis.text.y = element_text(colour="black"),
  axis.text.x = element_text(colour="black"),
  text = element_text(size=10, family="Helvetica")
)


theme_mine <- list(
  scale_fill_manual(values=my_palette),
  # To use for line and point colors, add
  scale_color_manual(values=my_palette),
  # To use for fills, add
  # basic black and white theme
  my_theme()
)


claret_data <- function(where) {
  d <- db(
    sprintf("select * from tapir where total_time is not null and %s", where),
    factors=c('nshards', 'nclients'),
    numeric=c('total_time', 'txn_count')
  )
  
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

data.ldbc <- function(where = "ldbc_config is not null") {
  d.all <- 
    if(exists("DATA.MODE") && DATA.MODE == 'local') {
      d_ldbc <- do.call("rbind", fromJSON("ldbc.json"))
      sqldf(sprintf("select * from d_ldbc where ldbc_results is not null and %s",where), drv="SQLite")
    } else {
      db(sprintf("select * from ldbc where ldbc_results is not null and ldbc_results != \"\" and %s", where))
    }
  d <- subset(d.all, grepl("\\s*\\{",ldbc_results))
  
  d$cc <- factor(revalue(d$ccmode, c(
    # 'bottom'='base',
    'rw'='reader/writer',
    'simple'='commutative'
  )), levels=c('commutative','reader/writer','base'))
  
  d <- adply(d, 1, function(r){
    o <- fromJSON(r$ldbc_results)
    m <- o$all_metrics
    mr <- m$run_time
    colnames(mr) <- sprintf("time_%s", colnames(mr))
    
    data.frame(
      throughput=as.numeric(r$ntotal)/as.numeric(o$total_duration),
      total_time=o$total_duration,
      name=o$all_metrics$name,
      count=o$all_metrics$count,
      mr
    )
  })
  
  d$name <- gsub('^.*(?:(Query\\d)|\\d(.*))$','\\1\\2',d$name)
  
  d
}
