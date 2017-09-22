#!/usr/bin/env Rscript

# Find dates with large numbers of additional obs

years<-c(1880,1887,1894,1900,1909,1917,1924,1931,1939,1946,
         1953,1961,1968,1975,1983,1990,1997,2005,2012)

get_counts<-function(year,version) {
  base.dir<-sprintf("%s/20CR/version_%s/observations/%04d",
                    Sys.getenv('SCRATCH'),version,year)
  op<-tempfile()
  cmd<-sprintf("wc -l %s/prepbufrobs_assim_*.txt > %s",
               base.dir,op)
  system(cmd)
  c.lines<-read.table(op,stringsAsFactors=FALSE)
  c.lines<-c.lines[1:(length(c.lines$V1)-1),]
  c.lines$V2<-basename(c.lines$V2)
  c.lines$V2<-substr(c.lines$V2,19,28)
  return(c.lines)
}

merge_counts<-function(c1,c2) {
  w<-which(c1$V2 %in% c2$V2)
  c1<-c1[w,]
  c1<-c1[order(c1$V2),]
  w<-which(c2$V2 %in% c1$V2)
  c2<-c2[w,]
  c2<-c2[order(c2$V2),]
  o<-order(c2$V1-c1$V1)
  c1<-c1[o,]
  c2<-c2[o,]
  result<-cbind(c1,c2)
  return(result)
}

for(year in years) {
  c1<-get_counts(year,'3.2.1')
  c2<-get_counts(year,'3.5.1')
  m<-merge_counts(c2,c1)
  print(head(m))
}
