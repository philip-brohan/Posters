#!/usr/bin/env Rscript

# Add the ovselays to the merged image

library(png)

Imagedir<-sprintf("%s/Posters/2010_multi_e_portrait",Sys.getenv('SCRATCH'))

mi<-readPNG(sprintf("%s/merged.png",Imagedir))
ol<-readPNG(sprintf("%s/overlay.png",Imagedir))

t<-as.vector(ol[,,4])
for(col in seq(1,3)) {
  a<-as.vector(mi[,,col])
  b<-as.vector(ol[,,col])
  a<-a*(1-t)+b*t
  mi[,,col]<-a
}

writePNG(mi,sprintf("%s/with.overlay.png",Imagedir))
