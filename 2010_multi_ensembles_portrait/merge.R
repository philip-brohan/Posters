#!/usr/bin/env Rscript

# Take a section from the image for each reanalysis ensemble member and combine them
#  into one output.

library(png)

Imagedir<-sprintf("%s/Posters/2010_multi_e_portrait",Sys.getenv('SCRATCH'))

# Background image - uniform yellow
bg<-readPNG(sprintf("%s/20CR2c_01.png",Imagedir))
bg[,,1]<-1 # Yellow
bg[,,2]<-1
bg[,,3]<-0.5

# Width of separator
e<-0

# Centre point
c.x<-0.4-0.006
c.y<-1.0-(0.45-0.065)

# Coordinates on 0-1 for each pixel
coord.y<-rev(rep(seq(1,length(bg[,1,1]))/length(bg[,1,1]),length(bg[1,,1])))
coord.x<-rep(seq(1,length(bg[1,,1]))/length(bg[1,,1]),length(bg[,1,1]))
coord.x<-array(dim=c(length(bg[1,,1]),length(bg[,1,1])),data=coord.x)
coord.x<-aperm(coord.x)
coord.x<-as.vector(coord.x)

# Range for 20CR2c
t2c.max<-  0.53*pi
t2c.min<- -0.19*pi

# Add a 20CR2c slice
add.t2c.slice<-function(member,bg) {
  image<-readPNG(sprintf("%s/20CR2c_%02d.png",Imagedir,member))
  s.max<-t2c.min+(t2c.max-t2c.min)*member/10
  s.min<-t2c.min+(t2c.max-t2c.min)*(member-1)/10
  es1<-e/abs(cos(s.max))
  es2<-e/abs(cos(s.min))
  w<-which(atan2(coord.y-es1-c.y,coord.x-c.x)<s.max &
           atan2(coord.y-es2-c.y,coord.x-c.x)>s.min &
           ((coord.x-c.x)>0 | ((coord.y-es1-c.y)*(coord.y-es2-c.y))>0) )
  for(col in seq(1,3)) {
      t<-as.vector(bg[,,col])
      t[w]<-as.vector(image[,,col])[w]
      bg[,,col]<-t
  }
  return(bg)
}

for(member in seq(1,10,1)) {
  print(sprintf("20CR2c %2d",member))
  bg<-add.t2c.slice(member,bg)
  g<-gc()
}

# Range for CERA20C
cera20c.max<- -0.19*pi
cera20c.min<- -0.69*pi

# Add a CERA20C slice
add.cera20c.slice<-function(member,bg) {
  image<-readPNG(sprintf("%s/CERA20C_%02d.png",Imagedir,member))
  s.max<-cera20c.min+(cera20c.max-cera20c.min)*(member+1)/10
  s.min<-cera20c.min+(cera20c.max-cera20c.min)*member/10
  es1<-e/abs(cos(s.max))
  es2<-e/abs(cos(s.min))
  w<-which(atan2(coord.y-es1-c.y,coord.x-c.x)<s.max &
           atan2(coord.y-es2-c.y,coord.x-c.x)>s.min &
           ((coord.x-c.x)>0 | ((coord.y-es1-c.y)*(coord.y-es2-c.y))>0))
  for(col in seq(1,3)) {
      t<-as.vector(bg[,,col])
      t[w]<-as.vector(image[,,col])[w]
      bg[,,col]<-t
  }
  return(bg)
}

for(member in seq(0,9,1)) {
  print(sprintf("CERA20C %2d",member))
  bg<-add.cera20c.slice(member,bg)
  g<-gc()
}

# Add a ERA5 slice
add.era5.slice<-function(member,bg,n,o) {
  image<-readPNG(sprintf("%s/ERA5_%02d.png",Imagedir,member))
  s.max<-era5.min+(era5.max-era5.min)*(member-o+1)/n
  s.min<-era5.min+(era5.max-era5.min)*(member-o)/n
  es1<-e/abs(cos(s.max))
  es2<-e/abs(cos(s.min))
  w<-which(atan2(coord.y-es1-c.y,coord.x-c.x)<s.max &
           atan2(coord.y-es2-c.y,coord.x-c.x)>s.min &
           ((coord.x-c.x)>0 | ((coord.y-es1-c.y)*(coord.y-es2-c.y))>0))
  for(col in seq(1,3)) {
      t<-as.vector(bg[,,col])
      t[w]<-as.vector(image[,,col])[w]
      bg[,,col]<-t
  }
  return(bg)
}
# Two ranges for ERA5
era5.max<- -0.69*pi
era5.min<- -1.00*pi
for(member in seq(1,4,1)) {
  print(sprintf("ERA5 %2d",member))
  bg<-add.era5.slice(member,bg,3,1)
  g<-gc()
}

era5.max<-  1.00*pi
era5.min<-  0.53*pi
for(member in seq(5,10,1)) {
  print(sprintf("ERA5 %2d",member))
  bg<-add.era5.slice(member,bg,6,5)
  g<-gc()
}

writePNG(bg,sprintf("%s/merged.png",Imagedir))

