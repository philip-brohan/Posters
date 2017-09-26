#!/usr/bin/env Rscript

# Add the overlays to the merged image

library(png)

Imagedir<-sprintf("%s/Posters/data.rescue",Sys.getenv('SCRATCH'))

mi<-readPNG(sprintf("%s/data.rescue.masked.png",Imagedir))
ol<-readPNG(sprintf("%s/overlay.png",Imagedir))

t<-as.vector(ol[,,4])
for(col in seq(1,3)) {
  a<-as.vector(mi[,,col])
  b<-as.vector(ol[,,col])
  a<-a*(1-t)+b*t
  mi[,,col]<-a
}

writePNG(mi,sprintf("%s/final.png",Imagedir))
