#!/usr/bin/Rscript --no-save

# Calculate the Fog of ignorance for each image
#  This script shouls parallel the main plot script, except it
#  plots only fog.

library(GSDF.TWCR)
library(GSDF.WeatherMap)
library(grid)
library(lubridate)
library(jpeg)

Imagedir<-sprintf("%s/Posters/data.rescue",Sys.getenv('SCRATCH'))

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'land.colour',rgb(100,100,100,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'sea.colour',rgb(200,200,200,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'ice.colour',rgb(250,250,250,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'pole.lon',160)
Options<-WeatherMap.set.option(Options,'pole.lat',45)

Options<-WeatherMap.set.option(Options,'lat.min',-90)
Options<-WeatherMap.set.option(Options,'lat.max',90)
Options<-WeatherMap.set.option(Options,'lon.min',-190+50)
Options<-WeatherMap.set.option(Options,'lon.max',190+50)
Options$vp.lon.min<- -180+50
Options$vp.lon.max<-  180+50
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
Options$fog.colour<-c(1,0,0)
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

  
    prmsl<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.5.1')
    prmsl.spread<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.5.1',
                                              type='spread')
    prmsl.sd<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                                         version='3.4.1',type='standard.deviation')
    prmsl.normal<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.4.1',
                                             type='normal')
    fog<-TWCR.relative.entropy(prmsl.normal,prmsl.sd,prmsl,prmsl.spread)
    fog$data[]<-1-pmin(fog.threshold,pmax(0,fog$data))/fog.threshold
    WeatherMap.draw.fog(fog,Options)

  popViewport()
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

  
    prmsl<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.5.1')
    prmsl.spread<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.5.1',
                                              type='spread')
    prmsl.sd<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                                         version='3.4.1',type='standard.deviation')
    prmsl.normal<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.4.1',
                                             type='normal')
    fog<-TWCR.relative.entropy(prmsl.normal,prmsl.sd,prmsl,prmsl.spread)
    fog$data[]<-1-pmin(fog.threshold,pmax(0,fog$data))/fog.threshold
    fog$data[]<-fog$data/2
    WeatherMap.draw.fog(fog,Options)

  popViewport()
}


# Make the full plot

image.name<-sprintf("fog.overlay.pdf",year,month,day,hour)
ifile.name<-sprintf("%s/%s",Imagedir,image.name)

 pdf(ifile.name,
         width=46.8,
         height=33.1,
         bg=rgb(1,0.15,0.15),
         family='Helvetica',
         pointsize=12)

  base.gp<-gpar(fontfamily='Helvetica',fontface='bold',col='black')

 base.date<-lubridate::ymd_hms("1860-01-22:06:00:00")
 count<-0
 for(j in seq(1,5)) {
    for(i in seq(1,4)) {
       date<-base.date+years(8*count)+hours(400*count)
       pushViewport(viewport(x=unit((i-0.5)/4,'npc'),
                             y=unit((5.5-j)/5,'npc'),
                             width=unit((1/5)*1.2,'npc'),
                             height=unit((1/5)/sqrt(2)*1.31,'npc'),
                             clip='on'))
          grid.polygon(x=unit(c(0.01,0.99,0.99,0.01),'npc'),
                       y=unit(c(0.01,0.01,0.99,0.99),'npc'),
                       gp=gpar(col='white',fill='white'))
          sub.plot(lubridate::year(date),
                   lubridate::month(date),
                   lubridate::day(date),
                   lubridate::hour(date),
                   Options)
       popViewport()
       count<-count+1
     }
  }
  dev.off()

