#!/usr/bin/env Rscript

# Apply the variable fog mask to the main image
#  Needs lots of RAM - run under salloc -mem=32000

library(png)

image.dir<-sprintf("%s/Posters/data.rescue",Sys.getenv('SCRATCH'))

orig<-readPNG(sprintf("%s/data.rescue.png",image.dir))

fogged<-readPNG(sprintf("%s/data.rescue.blurred.png",image.dir))
grey<-0.3*fogged[,,1]+0.59*fogged[,,2]+0.11*fogged[,,3]
grey.weight<-0.2
for(ch in seq(1,3)) {
    fogged[,,ch]<-grey*grey.weight+fogged[,,ch]*(1-grey.weight)
}
to.colour<-c(214/555,221/555,210/555)
colour.weight<-0.4
for(ch in seq(1,3)) {
   fogged[,,ch]<-fogged[,,ch]*(1-colour.weight)+to.colour[ch]*colour.weight
}
writePNG(fogged,sprintf("%s/data.rescue.fogged.png",image.dir))

mask<-readPNG(sprintf("%s/fog.overlay.blurred.png",image.dir))
mask<-1-as.vector(mask)**2
for(ch in seq(1,3)) {
  fogged[,,ch]<-fogged[,,ch]*mask+orig[,,ch]*(1-mask)
}
writePNG(fogged,sprintf("%s/data.rescue.masked.png",image.dir))

                                               
