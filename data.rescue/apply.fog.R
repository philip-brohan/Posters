# Apply the variable fog mask to the main image

library(png)

orig<-readPNG('20.png')

# Make the blurred version with imagemagic (faster)
#system('convert 20.png -blur 0x10 20.blurred.png')
fogged<-readPNG('20.blurred.png')
grey<-0.3*fogged[,,1]+0.59*fogged[,,2]+0.11*fogged[,,3]
grey.weight<-0.5
for(ch in seq(1,3)) {
    fogged[,,ch]<-grey*grey.weight+fogged[,,ch]*(1-grey.weight)
}
to.colour<-c(0.2,0.2,0.2)
colour.weight<-0.1
for(ch in seq(1,3)) {
   fogged[,,ch]<-fogged[,,ch]*(1-colour.weight)+to.colour[ch]*colour.weight
}
writePNG(fogged,'20.fogged.png')

# Merge fogged and original according to mask
mask<-readPNG('fog.overlay.png')
mask<-1-as.vector(mask[,,2])
for(ch in seq(1,3)) {
  fogged[,,ch]<-fogged[,,ch]*mask+orig[,,ch]*(1-mask)
}
writePNG(fogged,'20.masked.png')

                                               
