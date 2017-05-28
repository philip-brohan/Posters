# Apply the variable fog mask to the main image
#  Needs lots of RAM - run under salloc -mem=32000

library(png)

image.dir<-sprintf("%s/Posters/data.rescue",Sys.getenv('SCRATCH'))

orig<-readPNG(sprintf("%s/20.png",image.dir))

# Make the blurred version with imagemagic (faster)
#system(sprintf("convert %s/20.png -blur 0x20 %s/20.blurred.png",
#        image.dir,image.dir))
fogged<-readPNG(sprintf("%s/20.blurred.png",image.dir))
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
writePNG(fogged,sprintf("%s/20.fogged.png",image.dir))

# Merge fogged and original according to mask
#system(sprintf("convert -density 300  -blur 0x20 %s/fog.overlay.pdf %s/fog.overlay.png",
#        image.dir,image.dir))
mask<-readPNG(sprintf("%s/fog.overlay.png",image.dir))
#mask<-readPNG(sprintf("%s/tmp.png",image.dir))
mask<-1-as.vector(mask[,,1])**2
for(ch in seq(1,3)) {
  fogged[,,ch]<-fogged[,,ch]*mask+orig[,,ch]*(1-mask)
}
writePNG(fogged,sprintf("%s/20.masked.png",image.dir))

                                               
