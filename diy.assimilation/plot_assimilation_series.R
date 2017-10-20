#!/usr/bin/env Rscript

# Show the effect of assimilating additional observations
#  from Fort William on the 7-Feb 1903 weather.

library(GSDF.TWCR)
library(GSDF.WeatherMap)
library(parallel)
library(getopt)

members=seq(1,56)

Options<-WeatherMap.set.option(NULL)

range<-15
aspect<-4/3
Options<-WeatherMap.set.option(Options,'lat.min',range*-1)
Options<-WeatherMap.set.option(Options,'lat.max',range)
Options<-WeatherMap.set.option(Options,'lon.min',range*aspect/2*-1)
Options<-WeatherMap.set.option(Options,'lon.max',range*aspect/2)
Options<-WeatherMap.set.option(Options,'pole.lon',173)
Options<-WeatherMap.set.option(Options,'pole.lat',36)

Options$obs.size<- 0.15

land<-WeatherMap.get.land(Options)

Options$mslp.lwd<-0.5
Options$mslp.base=0                    # Base value for anomalies
Options$mslp.range=50000                    # Anomaly for max contour
Options$mslp.step=750                       # Smaller -more contours
Options$mslp.tpscale=3500                    # Smaller -contours less transparent

station.lat<-56.82
station.lon<- -5.1
new.data<-read.table('FW_pressure_Feb_1903.dat')
get.new.data<-function(day,hour){
  if(hour==0) {
    day=day-1
    hour=24
  }
  return(new.data[day,hour+3]*100)
}
source('../assimilate.R')

Draw.pressure<-function(mslp,Options,colour=c(0,0,0,1)) {
  
    M<-GSDF.WeatherMap:::WeatherMap.rotate.pole(mslp,Options)
    lats<-M$dimensions[[GSDF.find.dimension(M,'lat')]]$values
    longs<-M$dimensions[[GSDF.find.dimension(M,'lon')]]$values
      # Need particular data format for contourLines
    if(lats[2]<lats[1] || longs[2]<longs[1] || max(longs)> 180 ) {
      if(lats[2]<lats[1]) lats<-rev(lats)
      if(longs[2]<longs[1]) longs<-rev(longs)
      longs[longs>180]<-longs[longs>180]-360
      longs<-sort(longs)
      M2<-M
      M2$dimensions[[GSDF.find.dimension(M,'lat')]]$values<-lats
      M2$dimensions[[GSDF.find.dimension(M,'lon')]]$values<-longs
      M<-GSDF.regrid.2d(M,M2)
    }
    z<-matrix(data=M$data,nrow=length(longs),ncol=length(lats))
    contour.levels<-seq(Options$mslp.base-Options$mslp.range,
                        Options$mslp.base+Options$mslp.range,
                        Options$mslp.step)
    lines<-contourLines(longs,lats,z,
                         levels=contour.levels)
    if(!is.na(lines) && length(lines)>0) {
       for(i in seq(1,length(lines))) {
           tp<-min(1,(abs(lines[[i]]$level-Options$mslp.base)/
                      Options$mslp.tpscale))
           lt<-1
           lwd<-1
           gp<-gpar(col=rgb(0.5,0,0,tp*colour[4]),
                               lwd=Options$mslp.lwd*lwd,lty=lt)
           if(lines[[i]]$level<=Options$mslp.base) {
               lt<-1
               lwd<-1
               gp<-gpar(col=rgb(0,0,0.5,tp*colour[4]),
                               lwd=Options$mslp.lwd*lwd,lty=lt)
           }
           res<-tryCatch({
              grid.xspline(x=unit(lines[[i]]$x,'native'),
                           y=unit(lines[[i]]$y,'native'),
                           shape=1,
                           gp=gp)
             }, warning = function(w) {
                 print(w)
             }, error = function(e) {
                print(e)
             }, finally = {
                # Do nothing
             })
             
       }
    }
  }

plot.hour<-function(year,month,day,hour) {    

  # Load the data for this timepoint
  version<-'3.5.1'
  prmsl.normal<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.4.1',
                                               type='normal')
  e<-TWCR.get.members.slice.at.hour('prmsl',year,month,day,
                                    hour,version=version)
  m<-GSDF.select.from.1d(e,'ensemble',1)
  prmsl.normal<-GSDF.regrid.2d(prmsl.normal,m)
  obs<-TWCR.get.obs(year,month,day,hour,version=version)
  w<-which(obs$Longitude>180)
  obs$Longitude[w]<-obs$Longitude[w]-360

  # Assimilate the Fort William ob.
  asm<-EnKF.field.assimilate(e,e,list(Latitude=station.lat,
                                      Longitude=station.lon,
                                      value=get.new.data(day,hour)))
  print 

  Options$label<-sprintf("%04d-%02d-%02d:%02d",year,month,day,as.integer(hour))

  rll<-GSDF.ll.to.rg(station.lat,station.lon,Options$pole.lat,Options$pole.lon)

  # Plot the pressures without the new ob
  pushViewport(viewport(0.0125,0.045,.475,.95,clip='on',just=c('left','bottom')))
  
      grid.polygon(x=unit(c(0,1,1,0),'npc'),
                   y=unit(c(0,0,1,1),'npc'),
                   gp=gpar(fill=Options$sea.colour))

      pushViewport(dataViewport(c(Options$lon.min,Options$lon.max),
  				c(Options$lat.min,Options$lat.max),
  				extension=0))
          if(TRUE) {
          WeatherMap.draw.land(land,Options)
          WeatherMap.draw.obs(obs,Options)
          for(vn in seq_along(members)) {
              m<-GSDF.select.from.1d(e,'ensemble',vn)
  	      m$data[]<-as.vector(m$data)-as.vector(prmsl.normal$data)
  	      Draw.pressure(m,Options,colour=c(0,0,0,0.5))
          }
          }
      popViewport()
  popViewport()

  # Plot the pressures after assimilating the new ob
  pushViewport(viewport(0.5125,0.045,.475,.95,clip='on',just=c('left','bottom')))

      grid.polygon(x=unit(c(0,1,1,0),'npc'),
                   y=unit(c(0,0,1,1),'npc'),
                   gp=gpar(fill=Options$sea.colour))
  
      pushViewport(dataViewport(c(Options$lon.min,Options$lon.max),
  				c(Options$lat.min,Options$lat.max),
  				extension=0))
          if(TRUE) {
          WeatherMap.draw.land(land,Options)
          WeatherMap.draw.obs(obs,Options)
          for(vn in seq_along(members)) {
              m<-GSDF.select.from.1d(asm,'ensemble',vn)
  	      m$data[]<-as.vector(m$data)-as.vector(prmsl.normal$data)
  	      Draw.pressure(m,Options,colour=c(0,0,0,0.5))
            }

          # Mark the new ob
          grid.points(x=unit(rll$lon,'native'),
                      y=unit(rll$lat,'native'),
                      size=unit(Options$obs.size*1.5,'native'),
                      pch=21,
                      gp=gpar(col='red',fill='red'))
    
          # Lable the plot with the tims
          Options$label<-sprintf("%04d-%02d-%02d:%02d",year,month,day,as.integer(hour))
          WeatherMap.draw.label(Options)
          }
    
      popViewport()
  popViewport()

}

image.name<-"1903_Feb_UK.png"
ifile.name<-image.name

 png(ifile.name,
         width=1000,
         height=3000,
         bg='white',
         pointsize=24,
         type='cairo')

# Five panels 6-hours apart showing development of the storm
pushViewport(viewport(0.0,0.8,1.0,0.2,clip='on',just=c('left','bottom')))
  plot.hour(1903,2,6,18)
popViewport()

pushViewport(viewport(0.0,0.6,1.0,0.2,clip='on',just=c('left','bottom')))
  plot.hour(1903,2,7,0)
upViewport()

pushViewport(viewport(0.0,0.4,1.0,0.2,clip='on',just=c('left','bottom')))
  plot.hour(1903,2,7,6)
upViewport()

pushViewport(viewport(0.0,0.2,1.0,0.2,clip='on',just=c('left','bottom')))
  plot.hour(1903,2,7,12)
upViewport()

pushViewport(viewport(0.0,0.0,1.0,0.2,clip='on',just=c('left','bottom')))
  plot.hour(1903,2,7,18)
upViewport()

