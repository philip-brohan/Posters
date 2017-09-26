#!/usr/bin/env Rscript

# Add the key to the data rescue poster

library(grid)
library(Cairo)
library(png)

Imagedir<-sprintf("%s/Posters/data.rescue",Sys.getenv('SCRATCH'))


CairoPNG(sprintf("%s/overlay.png",Imagedir),
    width=14038,
    height=9929,
    bg='transparent',
    pointsize=96)

draw.label<-function(label,xp,yp,scale=1) {
    label.gp<-gpar(family='Helvetica',font=1,col='black',cex=scale)
    xp<-unit(xp,'npc')
    yp<-unit(yp,'npc')    
    tg<-textGrob(label,x=xp,y=yp,
                              just='center',
                              gp=label.gp)
   bg.gp<-gpar(col=rgb(1,1,1,0),fill=rgb(1,1,1,0.85))
   h<-heightDetails(tg)*(scale/2)
   w<-widthDetails(tg)*(scale/2)
   b<-unit(0.3,'char') # border
   grid.polygon(x=unit.c(xp+w+b,xp-w-b,xp-w-b,xp+w+b),
                y=unit.c(yp+h+b,yp+h+b,yp-h-b,yp-h-b),
                gp=bg.gp)
   grid.draw(tg)
}

# Signature
draw.label("philip.brohan@metoffice.gov.uk",0.0375,0.0075,0.7)

# Draw the key



# White partially-transparent background rectangle
 key.gp<-gpar(col=rgb(0,0,0,1),fill=rgb(1,1,1,0.75),
              cex=0.75)
 h<-0.17
 w<-0.15
 x.o<-0.007
 y.o<-0.017
 t.o<-0.01
 grid.polygon(x=unit(c(x.o,x.o+w,x.o+w,x.o),'npc'),
                y=unit(c(y.o,y.o,y.o+h,y.o+h),'npc'),
                gp=key.gp)
 
 g.w<-w/3
 g.h<-g.w*sqrt(2)/4
 grid.text('Weather from 20CRv2c\nensemble member 1',x=unit(x.o+t.o,'npc'),
                     y=unit(y.o+h*5/6,'npc'),
                     just=c('left','centre'),
                     gp=key.gp)
 w.img<-readPNG('weather.sample.png')
 grid.raster(w.img,x=unit(x.o+w-t.o,'npc'),
                     y=unit(y.o+h*5/6,'npc'),
                     width=unit(g.w,'npc'),
                     height=unit(g.h,'npc'),
                     just=c('right','centre'),
                     gp=key.gp)
 
 grid.text('Where 20CRv2c has\nlittle skill',x=unit(x.o+t.o,'npc'),
                     y=unit(y.o+h*4/6,'npc'),
                     just=c('left','centre'),
                     gp=key.gp)
 w.img<-readPNG('fog.sample.png')
 grid.raster(w.img,x=unit(x.o+w-t.o,'npc'),
                     y=unit(y.o+h*4/6,'npc'),
                     width=unit(g.w,'npc'),
                     height=unit(g.h,'npc'),
                     just=c('right','centre'),
                     gp=key.gp)
 
 grid.text('Where v2c is markedly\nbetter than v2',x=unit(x.o+t.o,'npc'),
                     y=unit(y.o+h*3/6,'npc'),
                     just=c('left','centre'),
                     gp=key.gp)
 glow.gp<-gpar(col=rgb(0,0,0,0),fill=rgb(255,215,0,255,
                                         maxColorValue=255))
 grid.polygon(x=unit(c(x.o+w-t.o-g.w,x.o+w-t.o,
                       x.o+w-t.o,x.o+w-t.o-g.w),'npc'),
              y=unit(c(y.o-g.h/2+h*3/6,y.o-g.h/2+h*3/6,
                       y.o+g.h/2+h*3/6,y.o+g.h/2+h*3/6),'npc'),
              gp=glow.gp)
 
 grid.text('Where there are observations\nin both v2 and v2c.',x=unit(x.o+t.o,'npc'),
                     y=unit(y.o+h*2/6,'npc'),
                     just=c('left','centre'),
                     gp=key.gp)
 p.x<-x.o+w-t.o-runif(10)*g.w
 p.y<-y.o+h*2/6+g.h/2-(runif(10)*g.h)
 old.gp<-gpar(col=rgb(0,0,0,1),fill=rgb(0.4,0.4,0.4,1))
 grid.points(x=unit(p.x,'npc'),
             y=unit(p.y,'npc'),
             size=unit(0.003,'npc'),
             pch=21,
             gp=old.gp)
 
 grid.text('Where there are additional\nobservations only in v2c',x=unit(x.o+t.o,'npc'),
                     y=unit(y.o+h*1/6,'npc'),
                     just=c('left','centre'),
                     gp=key.gp)
 p.x<-x.o+w-t.o-runif(10)*g.w
 p.y<-y.o+h*1/6+g.h/2-(runif(10)*g.h)
 new.gp<-gpar(col=rgb(0,0,0,1),fill=rgb(255,215,0,255,
                                         maxColorValue=255))
 grid.points(x=unit(p.x,'npc'),
             y=unit(p.y,'npc'),
             size=unit(0.003,'npc'),
             pch=21,
             gp=new.gp)
