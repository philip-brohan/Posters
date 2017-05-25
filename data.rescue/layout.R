#!/usr/bin/Rscript --no-save

# Test layout of sub-plots

library(grid)

Imagedir<-sprintf(".",Sys.getenv('SCRATCH'))

image.name<-"layout.pdf"
ifile.name<-sprintf("%s/%s",Imagedir,image.name)

 pdf(ifile.name,
         width=46.8,
         height=33.1,
         bg=rgb(220,220,220,255,maxColorValue=255),
         family='Helvetica',
         pointsize=12)

  base.gp<-gpar(fontfamily='Helvetica',fontface='bold',col='black')
  sub.colour<-rgb(0.3,0.3,0.3,1)

 count<-0
 for(j in seq(1,5)) {
    for(i in seq(1,4)) {
       pushViewport(viewport(x=unit((i-0.5)/4,'npc'),
                             y=unit((5.5-j)/5,'npc'),
                             width=unit((1/5)*1.2,'npc'),
                             height=unit((1/5)/sqrt(2)*1.31,'npc'),
                             clip='on'))
          grid.polygon(x=unit(c(0,1,1,0),'npc'),
                       y=unit(c(0,0,1,1),'npc'),
                       gp=gpar(col=sub.colour,fill=sub.colour))
       popViewport()
       count<-count+1
     }
  }
  dev.off()

