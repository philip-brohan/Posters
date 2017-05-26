library(png)

image.dir<-sprintf("%s/Posters/data.rescue",Sys.getenv('SCRATCH'))

orig<-readPNG(sprintf("%s/small.png",image.dir))

# Blurred version
blurred<-orig
system(sprintf("convert %s/small.png -blur 0x10 %s/blurred.png",
               image.dir,image.dir))
blurred<-readPNG(sprintf("%s/blurred.png",image.dir))
# Blended blurred
blended<-orig
max.x<-dim(orig)[2]
for(i in seq(1,max.x)) {
    weight<-i/max.x
    blended[,i,]<-orig[,i,]*weight+blurred[,i,]*(1-weight)
}
writePNG(blended,target=sprintf("%s/blended.blurred.png",image.dir))

# Desaturated version
desat<-orig
grey<-0.3*orig[,,1]+0.59*orig[,,2]+0.11*orig[,,3]
for(ch in seq(1,3)) {
    desat[,,ch]<-grey
}
writePNG(desat,target=sprintf("%s/desaturated.png",image.dir))
# Blended desaturated
blended<-orig
max.x<-dim(orig)[2]
for(i in seq(1,max.x)) {
    weight<-i/max.x
    blended[,i,]<-orig[,i,]*weight+desat[,i,]*(1-weight)
}
writePNG(blended,target=sprintf("%s/blended.desaturated.png",image.dir))

# Colorised version
colourised<-orig
to.colour<-c(0.2,0.2,0.2)
for(ch in seq(1,3)) {
   colourised[,,ch]<-colourised[,,ch]*0.5+to.colour[ch]*0.5
}
writePNG(colourised,target=sprintf("%s/colourised.png",image.dir))
# Blended colourised
blended<-orig
max.x<-dim(orig)[2]
for(i in seq(1,max.x)) {
    weight<-i/max.x
   for(ch in seq(1,3)) {
      colourised[,i,ch]<-colourised[,i,ch]*weight+to.colour[ch]*weight
   }
}
writePNG(blended,target=sprintf("%s/blended.colourised.png",image.dir))

# All three
fogged<-orig
sigma=10
grey<-0.3*orig[,,1]+0.59*orig[,,2]+0.11*orig[,,3]
grey.weight<-0.5
for(ch in seq(1,3)) {
    o2<-blur(as.im(fogged[,,ch]),sigma=sigma)
    fogged[,,ch]<-o2$v
}
grey<-0.3*fogged[,,1]+0.59*fogged[,,2]+0.11*fogged[,,3]
for(ch in seq(1,3)) {
    fogged[,,ch]<-grey*grey.weight+fogged[,,ch]*(1-grey.weight)
}
to.colour<-c(0.2,0.2,0.2)
colour.weight<-0.9
for(ch in seq(1,3)) {
   fogged[,,ch]<-fogged[,,ch]*colour.weight+to.colour[ch]*(1-colour.weight)
}
writePNG(fogged,target=sprintf("%s/fogged.png",image.dir))
# Blended fogged
blended<-orig
max.x<-dim(orig)[2]
for(i in seq(1,max.x)) {
    weight<-i/max.x
    weight<-weight**2
    blended[,i,]<-orig[,i,]*weight+fogged[,i,]*(1-weight)
}
writePNG(blended,target=sprintf("%s/blended.fogged.png",image.dir))
