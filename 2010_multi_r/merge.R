#!/usr/bin/env Rscript

# Take a section from the image for each reanalysis and combine them
#  into one output.

library(png)

twcr2c<-readPNG('20CR2c.png')

# Background image - uniform yellow
bg<-twcr2c
bg[,,4]<-1 # Opaque
bg[,,1]<-1 # Yellow
bg[,,2]<-1
bg[,,3]<-0.5

# With of separator
e<-0.0002

# Centre point
c.x<-0.4
c.y<-0.45

# Coordinates on 0-1 for each pixel
coord.y<-rep(seq(1,length(bg[,1,1]))/length(bg[,1,1]),length(bg[1,,1]))
coord.x<-rep(seq(1,length(bg[1,,1]))/length(bg[1,,1]),length(bg[,1,1]))
coord.x<-array(dim=c(length(bg[1,,1]),length(bg[,1,1])),data=coord.x)
coord.x<-aperm(coord.x)
coord.x<-as.vector(coord.x)

# 20CR sector
w<-which(atan2(coord.y+e-c.y,coord.x-c.x)>.75*pi |
         atan2(coord.y-e-c.y,coord.x-c.x)< -.75*pi |
         atan2(coord.y-e-c.y,coord.x-c.x)*atan2(coord.y+e-c.y,coord.x-c.x)<0)
for(col in seq(1,4)) {
    t<-as.vector(bg[,,col])
    t[w]<-as.vector(twcr2c[,,col])[w]
    bg[,,col]<-t
}
rm(twcr2c)
gc('no')

# ERA5 sector
era5<-readPNG('ERA5.png')
w<-which(atan2(coord.y-e-c.y,coord.x-c.x)<.75*pi &
         atan2(coord.y-e-c.y,coord.x-c.x)> .25*pi)
for(col in seq(1,4)) {
    t<-as.vector(bg[,,col])
    t[w]<-as.vector(era5[,,col])[w]
    bg[,,col]<-t
}
rm(era5)
gc('no')

# CERA20C sector
cera20c<-readPNG('CERA20C.png')
w<-which(atan2(coord.y+e-c.y,coord.x-c.x)<.25*pi &
         atan2(coord.y-e-c.y,coord.x-c.x)> -.25*pi)
for(col in seq(1,4)) {
    t<-as.vector(bg[,,col])
    t[w]<-as.vector(cera20c[,,col])[w]
    bg[,,col]<-t
}
rm(cera20c)
gc('no')

# ERAI sector
erai<-readPNG('ERAI.png')
w<-which(atan2(coord.y+e-c.y,coord.x-c.x)< -.25*pi &
         atan2(coord.y+e-c.y,coord.x-c.x)> -.75*pi)
for(col in seq(1,4)) {
    t<-as.vector(bg[,,col])
    t[w]<-as.vector(erai[,,col])[w]
    bg[,,col]<-t
}
rm(erai)
gc('no')


writePNG(bg,'merged.png')

