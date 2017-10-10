#!/usr/bin/env Rscript

# Add the ensemble boundary lines and text labels to be overlain on
#  top of the merved reanalysis slices.

library(grid)
library(Cairo)

Imagedir<-sprintf("%s/Posters/2010_multi_e_portrait",Sys.getenv('SCRATCH'))

opt<-list()
opt$year<-2010
opt$month<-9
opt$day<-16
opt$hour<-12

CairoPNG(sprintf("%s/overlay.png",Imagedir),
    height=14038,
    width=9929,
    bg='transparent',
    pointsize=96)


#line style for separating ensemble members
lgp<-gpar(col=rgb(1,1,0.5,1),fill=rgb(1,1,0.5,1),lwd=2)
# line style for separating reanalyses
lgpt<-gpar(col=rgb(1,1,0.5,1),fill=rgb(1,1,0.5,1),lwd=12)

# Centre point
c.x<-11.5/19.4
c.y<-19/27.4

# Delimiters for ERA5
t2c.max<-  0.95*pi
t2c.min<- -0.05*pi

sc<-0.000+runif(1)*0.005
grid.lines(x=unit(c(c.x+cos(t2c.max)*sc,
                    c.x+cos(t2c.max)*10),'npc'),
           y=unit(c(c.y+sin(t2c.max)*sc,
                    c.y+sin(t2c.max)*10),'npc'),
             gp=lgpt)
sc<-0.000+runif(1)*0.005
grid.lines(x=unit(c(c.x+cos(t2c.min)*sc,
                    c.x+cos(t2c.min)*10),'npc'),
           y=unit(c(c.y+sin(t2c.min)*sc,
                    c.y+sin(t2c.min)*10),'npc'),
             gp=lgpt)

# Add a 20CR2c slice
mark.t2c.slice<-function(member) {

  s.max<-t2c.min+(t2c.max-t2c.min)*member/10
  s.min<-t2c.min+(t2c.max-t2c.min)*(member-1)/10

  sc<-0.005+runif(1)*0.005
  grid.lines(x=unit(c(c.x+cos(s.max)*sc,
                      c.x+cos(s.max)*10),'npc'),
             y=unit(c(c.y+sin(s.max)*sc,
                      c.y+sin(s.max)*10),'npc'),
             gp=lgp)
  sc<-0.005+runif(1)*0.005
  grid.lines(x=unit(c(c.x+cos(s.min)*sc,
                      c.x+cos(s.min)*10),'npc'),
             y=unit(c(c.y+sin(s.min)*sc,
                      c.y+sin(s.min)*10),'npc'),
             gp=lgp)

}

for(member in seq(1,10,1)) {
  mark.t2c.slice(member)
}


# Range for CERA20C
cera20c.max<- -0.05*pi
cera20c.min<- -0.59*pi

sc<-0.000+runif(1)*0.005
grid.lines(x=unit(c(c.x+cos(cera20c.max)*sc,
                    c.x+cos(cera20c.max)*10),'npc'),
           y=unit(c(c.y+sin(cera20c.max)*sc,
                    c.y+sin(cera20c.max)*10),'npc'),
             gp=lgpt)
sc<-0.000+runif(1)*0.005
grid.lines(x=unit(c(c.x+cos(cera20c.min)*sc,
                    c.x+cos(cera20c.min)*10),'npc'),
           y=unit(c(c.y+sin(cera20c.min)*sc,
                    c.y+sin(cera20c.min)*10),'npc'),
             gp=lgpt)

# Add a CERA20C slice
mark.cera20c.slice<-function(member) {

  s.max<-cera20c.min+(cera20c.max-cera20c.min)*(member+1)/10
  s.min<-cera20c.min+(cera20c.max-cera20c.min)*member/10

  sc<-0.005+runif(1)*0.005
  grid.lines(x=unit(c(c.x+cos(s.max)*sc,
                      c.x+cos(s.max)*10),'npc'),
             y=unit(c(c.y+sin(s.max)*sc,
                      c.y+sin(s.max)*10),'npc'),
             gp=lgp)
  sc<-0.005+runif(1)*0.005
  grid.lines(x=unit(c(c.x+cos(s.min)*sc,
                      c.x+cos(s.min)*10),'npc'),
             y=unit(c(c.y+sin(s.min)*sc,
                      c.y+sin(s.min)*10),'npc'),
             gp=lgp)

}

for(member in seq(0,9,1)) {
  mark.cera20c.slice(member)
}

# Add a ERA5 slice
mark.era5.slice<-function(member,n,o) {

  s.max<-era5.min+(era5.max-era5.min)*(member-o+1)/n
  s.min<-era5.min+(era5.max-era5.min)*(member-o)/n
  
  sc<-0.005+runif(1)*0.005
  grid.lines(x=unit(c(c.x+cos(s.max)*sc,
                      c.x+cos(s.max)*10),'npc'),
             y=unit(c(c.y+sin(s.max)*sc,
                      c.y+sin(s.max)*10),'npc'),
             gp=lgp)
  sc<-0.005+runif(1)*0.005
  grid.lines(x=unit(c(c.x+cos(s.min)*sc,
                      c.x+cos(s.min)*10),'npc'),
             y=unit(c(c.y+sin(s.min)*sc,
                      c.y+sin(s.min)*10),'npc'),
             gp=lgp)
  
}

# Two ranges for ERA5
era5.max<- -0.59*pi
era5.min<- -1.00*pi
sc<-0.000+runif(1)*0.005
grid.lines(x=unit(c(c.x+cos(era5.max)*sc,
                    c.x+cos(era5.max)*10),'npc'),
           y=unit(c(c.y+sin(era5.max)*sc,
                    c.y+sin(era5.max)*10),'npc'),
             gp=lgpt)

for(member in seq(2,10,1)) {
  mark.era5.slice(member,9,2)
}
era5.max<-  1.00*pi
era5.min<-  0.95*pi
sc<-0.000+runif(1)*0.005
grid.lines(x=unit(c(c.x+cos(era5.min)*sc,
                    c.x+cos(era5.min)*10),'npc'),
           y=unit(c(c.y+sin(era5.min)*sc,
                    c.y+sin(era5.min)*10),'npc'),
             gp=lgpt)
for(member in seq(1,1,1)) {
  mark.era5.slice(member,1,1)
}

draw.label<-function(label,xp,yp,scale=1) {
    label.gp<-gpar(family='Helvetica',font=1,col='black',cex=scale)
    xp<-unit(xp,'npc')
    yp<-unit(yp,'npc')    
    tg<-textGrob(label,x=xp,y=yp,
                              just='center',
                              gp=label.gp)
   bg.gp<-gpar(col=rgb(1,1,1,0),fill=rgb(1,1,1,0.55))
   h<-heightDetails(tg)*(scale/2)
   w<-widthDetails(tg)*(scale/2)
   b<-unit(0.3,'char') # border
   grid.polygon(x=unit.c(xp+w+b,xp-w-b,xp-w-b,xp+w+b),
                y=unit.c(yp+h+b,yp+h+b,yp-h-b,yp-h-b),
                gp=bg.gp)
   grid.draw(tg)
}
  # Add the date
draw.label(sprintf("%04d-%02d-%02d:%02d",opt$year,opt$month,
                   opt$day,opt$hour),
                   0.96,0.01*16/9,1.3)

# Label the reanalyes
draw.label("ERA5 ENDA",0.025,0.95,1.0)
draw.label("CERA20C",0.68,0.01*16/9,1.0)
draw.label("20CR2c\n(members 1-10)",0.925,0.97,1.0)

# Signature
draw.label("philip.brohan@metoffice.gov.uk",0.04,0.01,0.7)
