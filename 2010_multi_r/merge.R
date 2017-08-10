#!/usr/bin/env Rscript

# Take a section from the image for each reanalysis and combine them
#  into one output.

library(png)

Imagedir<-sprintf("%s/Posters/2010_multi_r",Sys.getenv('SCRATCH'))

twcr2c<-readPNG(sprintf("%s/20CR2c.png",Imagedir))

# Background image - uniform yellow
bg<-twcr2c
bg[,,4]<-1 # Opaque
bg[,,1]<-1 # Yellow
bg[,,2]<-1
bg[,,3]<-0.5

# With of separator
e<-0.0003

# Centre point
c.x<-0.4-0.006
c.y<-0.45-0.065

# Coordinates on 0-1 for each pixel
coord.y<-rep(seq(1,length(bg[,1,1]))/length(bg[,1,1]),length(bg[1,,1]))
coord.x<-rep(seq(1,length(bg[1,,1]))/length(bg[1,,1]),length(bg[,1,1]))
coord.x<-array(dim=c(length(bg[1,,1]),length(bg[,1,1])),data=coord.x)
coord.x<-aperm(coord.x)
coord.x<-as.vector(coord.x)

# 20CR sector
w<-which(atan2(coord.y+e-c.y,coord.x-c.x)>.685*pi |
         atan2(coord.y-e-c.y,coord.x-c.x)< -.65*pi |
         atan2(coord.y-e-c.y,coord.x-c.x)*atan2(coord.y+e-c.y,coord.x-c.x)<0)
for(col in seq(1,4)) {
    t<-as.vector(bg[,,col])
    t[w]<-as.vector(twcr2c[,,col])[w]
    bg[,,col]<-t
}
rm(twcr2c)
gc()

cera20c<-readPNG(sprintf("%s/CERA20C.png",Imagedir))
w<-which(atan2(coord.y-e-c.y,coord.x-c.x)<.685*pi &
         atan2(coord.y-e-c.y,coord.x-c.x)> .35*pi)
for(col in seq(1,4)) {
    t<-as.vector(bg[,,col])
    t[w]<-as.vector(cera20c[,,col])[w]
    bg[,,col]<-t
}
rm(cera20c)
gc()

era5<-readPNG(sprintf("%s/ERA5.png",Imagedir))
w<-which(atan2(coord.y+e-c.y,coord.x-c.x)<.35*pi &
         atan2(coord.y-e-c.y,coord.x-c.x)> -.10*pi)
for(col in seq(1,4)) {
    t<-as.vector(bg[,,col])
    t[w]<-as.vector(era5[,,col])[w]
    bg[,,col]<-t
}
rm(era5)
gc()

# ERAI sector
erai<-readPNG(sprintf("%s/ERAI.png",Imagedir))
w<-which(atan2(coord.y+e-c.y,coord.x-c.x)< -.10*pi &
         atan2(coord.y+e-c.y,coord.x-c.x)> -.65*pi)
for(col in seq(1,4)) {
    t<-as.vector(bg[,,col])
    t[w]<-as.vector(erai[,,col])[w]
    bg[,,col]<-t
}
rm(erai)
gc()


writePNG(bg,sprintf("%s/merged.png",Imagedir))

