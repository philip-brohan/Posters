#!/usr/bin/env Rscript

# Calculate the Fog of ignorance for each image
#  This script should parallel the main plot script, except it
#  plots only fog.

library(GSDF.TWCR)
library(GSDF.WeatherMap)
library(grid)
library(lubridate)

dates<-c("1872-11-01:12:00:00",
         "1880-01-30:18:00:00",
         "1887-02-16:12:00:00",
         "1894-10-10:00:00:00",
         "1902-12-28:06:00:00",
         "1909-02-03:06:00:00",
         "1917-10-05:18:00:00",
         "1924-01-24:06:00:00",
         "1931-09-23:06:00:00",
         "1939-01-04:18:00:00",
         "1946-07-04:18:00:00",
         "1953-10-21:12:00:00",
         "1961-08-06:06:00:00",
         "1968-11-17:18:00:00",
         "1975-05-31:12:00:00",
         "1983-08-02:06:00:00",
         "1990-12-23:18:00:00",
         "1997-07-31:18:00:00",
         "2005-02-03:00:00:00",
         "2012-04-18:06:00:00")

Imagedir<-sprintf("%s/Posters/data.rescue",Sys.getenv('SCRATCH'))

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'land.colour',rgb(100,100,100,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'sea.colour',rgb(200,200,200,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'ice.colour',rgb(250,250,250,255,
                                                       maxColorValue=255))
#Options<-WeatherMap.set.option(Options,'pole.lon',160)
#Options<-WeatherMap.set.option(Options,'pole.lat',45)
Options<-WeatherMap.set.option(Options,'pole.lon',180)
Options<-WeatherMap.set.option(Options,'pole.lat',90)

Options<-WeatherMap.set.option(Options,'lat.min',-90)
Options<-WeatherMap.set.option(Options,'lat.max',90)
#Options<-WeatherMap.set.option(Options,'lon.min',-190+50)
#Options<-WeatherMap.set.option(Options,'lon.max',190+50)
#Options$vp.lon.min<- -180+50
#Options$vp.lon.max<-  180+50
Options<-WeatherMap.set.option(Options,'lon.min',-190)
Options<-WeatherMap.set.option(Options,'lon.max',190)
Options$vp.lon.min<- -180
Options$vp.lon.max<-  180
Options<-WeatherMap.set.option(Options,'wrap.spherical',F)
Options$precip.colour=c(0,0.2,0)
Options$label.xp=0.995
Options<-WeatherMap.set.option(Options,'obs.size',1.0)
Options<-WeatherMap.set.option(Options,'obs.colour',rgb(255,215,0,255,
                                                       maxColorValue=255))

Options$ice.points<-1000000

Options$mslp.base=101325                    # Base value for anomalies
Options$mslp.range=50000                    # Anomaly for max contour
Options$mslp.step=500                       # Smaller -> more contours
Options$mslp.tpscale=5                      # Smaller -> contours less transparent
Options$mslp.lwd=1
Options$precip.colour=c(0,0.2,0)
# Overrides mslp options
contour.levels<-seq(-300,300,30)
contour.levels<-abs(contour.levels)**1.5*sign(contour.levels)
contour.levels<-contour.levels+Options$mslp.base

fog.threshold<-exp(2)
Options$fog.colour<-c(0,0,0)
Options$fog.min.transparency<-1
get.member.at.hour<-function(variable,year,month,day,hour,member,version='3.5.1') {

       t<-TWCR.get.members.slice.at.hour(variable,year,month,day,
                                  hour,version=version)
       t<-GSDF.select.from.1d(t,'ensemble',member)
       gc()
       return(t)
  }



# Rotate the pole
set.pole<-function(step,Options) {
  lon<-160+(step*20)
  if(lon>360) lon<-lon%%360
  lat<-35+sin(step)*20
  Options<-WeatherMap.set.option(Options,'pole.lon',lon)
  Options<-WeatherMap.set.option(Options,'pole.lat',lat)
  min.lon<-(step*20)%%360-180
  Options<-WeatherMap.set.option(Options,'lon.min',min.lon-10)
  Options<-WeatherMap.set.option(Options,'lon.max',min.lon+380)
  Options<-WeatherMap.set.option(Options,'vp.lon.min',min.lon   )
  Options<-WeatherMap.set.option(Options,'vp.lon.max',min.lon+360)
  return(Options)
}

  
# Make a sub plot
sub.plot<-function(year,month,day,hour,Options) {
  
  lon.min<-Options$lon.min
  if(!is.null(Options$vp.lon.min)) lon.min<-Options$vp.lon.min
  lon.max<-Options$lon.max
  if(!is.null(Options$vp.lon.max)) lon.max<-Options$vp.lon.max
  lat.min<-Options$lat.min
  if(!is.null(Options$vp.lat.min)) lat.min<-Options$vp.lat.min
  lat.max<-Options$lat.max
  if(!is.null(Options$vp.lat.max)) lat.max<-Options$vp.lat.max

  pushViewport(dataViewport(c(lon.min,lon.max),c(lat.min,lat.max),
                            extension=0,gp=base.gp))

  
    prmsl.sd<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                                         version='3.4.1',type='standard.deviation')
    prmsl.e<-TWCR.get.members.slice.at.hour('prmsl',year,month,day,hour,version='3.5.1')
    prmsl.spread<-GSDF.reduce.1d(prmsl.e,'ensemble',sd)
    prmsl.sd<-GSDF.regrid.2d(prmsl.sd,prmsl.spread)
    fog<-prmsl.sd
    fog$data[]<-prmsl.spread$data/prmsl.sd$data
    fog$data[]<-1-pmax(0,pmin(1,(1-fog$data)*2))
    ex.lon<-GSDF.roll.dimensions(fog,1,2)
    ex.lat<-GSDF.roll.dimensions(fog,2,1)
    w<-which(ex.lat< -85 & ex.lat> -90 & ex.lon>135 & ex.lon< 180)
    fog$data[w]<-pmin(fog$data[w],0.25)
    WeatherMap.draw.fog(fog,Options)

  popViewport()
  f2<-fog
  f2$dimensions[[1]]$values<-seq(-180,178,2)
  fog<-GSDF.regrid.2d(fog,f2)
  return(fog)
}

# Make a background plot - half density fog
background.plot<-function(year,month,day,hour,Options) {
  
  lon.min<-Options$lon.min
  if(!is.null(Options$vp.lon.min)) lon.min<-Options$vp.lon.min
  lon.max<-Options$lon.max
  if(!is.null(Options$vp.lon.max)) lon.max<-Options$vp.lon.max
  lat.min<-Options$lat.min
  if(!is.null(Options$vp.lat.min)) lat.min<-Options$vp.lat.min
  lat.max<-Options$lat.max
  if(!is.null(Options$vp.lat.max)) lat.max<-Options$vp.lat.max

  pushViewport(dataViewport(c(lon.min,lon.max),c(lat.min,lat.max),
                            extension=0,gp=base.gp))

  
    prmsl.sd<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                                         version='3.4.1',type='standard.deviation')
    prmsl.e<-TWCR.get.members.slice.at.hour('prmsl',year,month,day,hour,version='3.5.1')
    prmsl.spread<-GSDF.reduce.1d(prmsl.e,'ensemble',sd)
    prmsl.sd<-GSDF.regrid.2d(prmsl.sd,prmsl.spread)
    fog<-prmsl.sd
    fog$data[]<-prmsl.spread$data/prmsl.sd$data
    fog$data[]<-1-pmax(0,pmin(1,(1-fog$data)*2))
    fog$data[]<-fog$data/2
    WeatherMap.draw.fog(fog,Options)

  popViewport()
  return(fog)
}


# Make the full plot

image.name<-sprintf("fog.overlay.pdf",year,month,day,hour)
ifile.name<-sprintf("%s/%s",Imagedir,image.name)

 pdf(ifile.name,
         width=46.8,
         height=33.1,
         bg='white',
         family='Helvetica',
         pointsize=12)

  base.gp<-gpar(fontfamily='Helvetica',fontface='bold',col='black')

 base.date<-lubridate::ymd_hms("1862-01-22:06:00:00")
 count<-0
 fogs<-list()
 for(j in seq(1,5)) {
    fogs[[j]]<-list()
    for(i in seq(1,4)) {
       date<-lubridate::ymd_hms(dates[count+1])
       pushViewport(viewport(x=unit((i-0.5)/4,'npc'),
                             y=unit((5.5-j)/5,'npc'),
                             width=unit((1/5)*1.2,'npc'),
                             height=unit((1/5)/sqrt(2)*1.31,'npc'),
                             clip='on'))
          grid.polygon(x=unit(c(0,1,1,0),'npc'),
                       y=unit(c(0,0,1,1),'npc'),
                       gp=gpar(col='white',fill='white'))
          fogs[[j]][[i]]<-sub.plot(lubridate::year(date),
                                   lubridate::month(date),
                                   lubridate::day(date),
                                   lubridate::hour(date),
                                   Options)
       popViewport()
       count<-count+1
     }
  }

  # Fill in the gaps between plots
 for(j in seq(1,5)) {
    for(i in seq(1,4)) {
      #print(sprintf("%d %d",j,i))
      dms<-dim(fogs[[j]][[i]]$data)
      # above
      pushViewport(viewport(x=unit((i-0.5)/4,'npc'),
                            y=unit((5-(j-1))/5,'npc'),
                            width=unit((1/5)*1.2,'npc'),
                            height=unit((1/5-(1/5)/sqrt(2)*1.31)/2,'npc'),
                            just=c('center','top'),
                            clip='on'))

          if(j==1) { # Top row
            data<-fogs[[j]][[i]]$data[,1,1]
          } else {
            data<-fogs[[j]][[i]]$data[,1,1]*2/3+fogs[[j-1]][[i]]$data[,dms[2],1]*1/3
          }
          for(p in seq_along(data)) {
            gp<-gpar(col=rgb(0,0,0,data[p]),fill=rgb(0,0,0,data[p]),lwd=0)
            nd<-length(data)
            grid.polygon(x=unit(c((p-1)/nd,p/nd,p/nd,(p-1)/nd),'npc'),
                         y=unit(c(0,0,1,1),'npc'),
                         gp=gp)
          }
                
      popViewport()

      # left upper corner
      pushViewport(viewport(x=unit(((i)-0.5)/4-((1/5)*1.2)/2-(1/4-(1/5)*1.2)/2,'npc'),
                            y=unit((5-(j-1))/5,'npc'),
                            width=unit((1/4-(1/5)*1.2)/2,'npc'),
                            height=unit((1/5-(1/5)/sqrt(2)*1.31)/2,'npc'),
                            just=c('left','top'),
                            clip='on'))
            gp<-gpar(col=rgb(0,0,0,data[1]),fill=rgb(0,0,0,data[1]),lwd=0)
            grid.polygon(x=unit(c(0,1,1,0),'npc'),
                         y=unit(c(0,0,1,1),'npc'),
                         gp=gp)
      popViewport()
      # right upper corner
      pushViewport(viewport(x=unit(((i)-0.5)/4+((1/5)*1.2)/2,'npc'),
                            y=unit((5-(j-1))/5,'npc'),
                            width=unit((1/4-(1/5)*1.2)/2,'npc'),
                            height=unit((1/5-(1/5)/sqrt(2)*1.31)/2,'npc'),
                            just=c('left','top'),
                            clip='on'))
            gp<-gpar(col=rgb(0,0,0,data[length(data)]),fill=rgb(0,0,0,data[length(data)]),lwd=0)
            grid.polygon(x=unit(c(0,1,1,0),'npc'),
                         y=unit(c(0,0,1,1),'npc'),
                         gp=gp)
      popViewport()
      
      # below
      pushViewport(viewport(x=unit((i-0.5)/4,'npc'),
                            y=unit((5.5-j)/5-(1/5)/sqrt(2)*1.31/2,'npc'),
                            width=unit((1/5)*1.2,'npc'),
                            height=unit((1/5-(1/5)/sqrt(2)*1.31)/2,'npc'),
                            just=c('center','top'),
                            clip='on'))
      
          if(j==5) { # bottom row
            data<-fogs[[j]][[i]]$data[,dms[2],1]*0 # set bottom all to 0
          } else {
            data<-fogs[[j]][[i]]$data[,dms[2],1]*2/3+fogs[[j+1]][[i]]$data[,1,1]*1/3
          }
          for(p in seq_along(data)) {
            gp<-gpar(col=rgb(0,0,0,data[p]),fill=rgb(0,0,0,data[p]),lwd=0)
            nd<-length(data)
            grid.polygon(x=unit(c((p-1)/nd,p/nd,p/nd,(p-1)/nd),'npc'),
                         y=unit(c(0,0,1,1),'npc'),
                         gp=gp)
          }
       popViewport()
      # left lower corner
      pushViewport(viewport(x=unit(((i)-0.5)/4-((1/5)*1.2)/2-(1/4-(1/5)*1.2)/2,'npc'),
                            y=unit((5.5-j)/5-(1/5)/sqrt(2)*1.31/2,'npc'),
                            width=unit((1/4-(1/5)*1.2)/2,'npc'),
                            height=unit((1/5-(1/5)/sqrt(2)*1.31)/2,'npc'),
                            just=c('left','top'),
                            clip='on'))
            gp<-gpar(col=rgb(0,0,0,data[1]),fill=rgb(0,0,0,data[1]),lwd=0)
            grid.polygon(x=unit(c(0,1,1,0),'npc'),
                         y=unit(c(0,0,1,1),'npc'),
                         gp=gp)
      popViewport()
      # right lower corner
      pushViewport(viewport(x=unit(((i)-0.5)/4+((1/5)*1.2)/2,'npc'),
                            y=unit((5.5-j)/5-(1/5)/sqrt(2)*1.31/2,'npc'),
                            width=unit((1/4-(1/5)*1.2)/2,'npc'),
                            height=unit((1/5-(1/5)/sqrt(2)*1.31)/2,'npc'),
                            just=c('left','top'),
                            clip='on'))
            gp<-gpar(col=rgb(0,0,0,data[length(data)]),fill=rgb(0,0,0,data[length(data)]),lwd=0)
            grid.polygon(x=unit(c(0,1,1,0),'npc'),
                         y=unit(c(0,0,1,1),'npc'),
                         gp=gp)
      popViewport()
      
      # right
      pushViewport(viewport(x=unit(((i)-0.5)/4+((1/5)*1.2)/2,'npc'),
                            y=unit((5.5-j)/5,'npc'),
                            width=unit((1/4-(1/5)*1.2)/2,'npc'),
                            height=unit((1/5)/sqrt(2)*1.31,'npc'),
                            just=c('left','center'),
                            clip='on'))
      
          if(i==4) { # right hand side
            data<-rev(fogs[[j]][[i]]$data[dms[1],,1])
          } else {
            data<-rev(fogs[[j]][[i]]$data[dms[1],,1]*2/3+fogs[[j]][[i+1]]$data[1,,1]*1/3)
          }
          for(p in seq_along(data)) {
            gp<-gpar(col=rgb(0,0,0,data[p]),fill=rgb(0,0,0,data[p]),lwd=0)
            nd<-length(data)
            grid.polygon(y=unit(c((p-1)/nd,p/nd,p/nd,(p-1)/nd),'npc'),
                         x=unit(c(0,0,1,1),'npc'),
                         gp=gp)
          }
       popViewport()
      # left
      pushViewport(viewport(x=unit(((i)-0.5)/4-((1/5)*1.2)/2-(1/4-(1/5)*1.2)/2,'npc'),
                            y=unit((5.5-j)/5,'npc'),
                            width=unit((1/4-(1/5)*1.2)/2,'npc'),
                            height=unit((1/5)/sqrt(2)*1.31,'npc'),
                            just=c('left','center'),
                            clip='on'))
      
          if(i==1) { # left hand side
            data<-rev(fogs[[j]][[i]]$data[1,,1])
          } else {
            data<-rev(fogs[[j]][[i]]$data[1,,1]*2/3+fogs[[j]][[i-1]]$data[dms[1],,1]*1/3)
          }
          for(p in seq_along(data)) {
            gp<-gpar(col=rgb(0,0,0,data[p]),fill=rgb(0,0,0,data[p]),lwd=0)
            nd<-length(data)
            grid.polygon(y=unit(c((p-1)/nd,p/nd,p/nd,(p-1)/nd),'npc'),
                         x=unit(c(0,0,1,1),'npc'),
                         gp=gp)
          }
      popViewport()
    }
  }

dev.off()

