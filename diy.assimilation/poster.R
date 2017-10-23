#!/usr/bin/env Rscript

# Show the effect of assimilating additional observations
#  from Fort William

library(GSDF.TWCR)
library(GSDF.WeatherMap)
library(parallel)

opt<-list(year=1903,
          month=2,
          day=7,
          hour=18)

members=seq(1,56)

Imagedir<-sprintf("%s/Posters/EnKF_Fort_William",Sys.getenv('SCRATCH'))
if(!file.exists(Imagedir)) dir.create(Imagedir,recursive=TRUE)

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'land.colour',rgb(150,150,150,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'sea.colour',rgb(200,200,200,255,
                                                       maxColorValue=255))

range<-8
aspect<-1/sqrt(2)
Options<-WeatherMap.set.option(Options,'lat.min',range*-1+3)
Options<-WeatherMap.set.option(Options,'lat.max',range+3)
Options<-WeatherMap.set.option(Options,'lon.min',range*aspect*-1-1)
Options<-WeatherMap.set.option(Options,'lon.max',range*aspect-1)
Options<-WeatherMap.set.option(Options,'pole.lon',177.5)
Options<-WeatherMap.set.option(Options,'pole.lat',37.5)

Options$obs.size<- 0.2

land<-WeatherMap.get.land(Options)

Options$mslp.lwd<-5
Options$mslp.base=0                    # Base value for anomalies
Options$mslp.range=50000                    # Anomaly for max contour
Options$mslp.step=750                       # Smaller -more contours
Options$mslp.tpscale=350                    # Smaller -contours less transparent

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
source('./assimilate.R')

Draw.pressure<-function(mslp,Options,colour=c(0,0,0,1)) {
  
    M<-GSDF.WeatherMap:::WeatherMap.rotate.pole(mslp,Options)
    lats<-M$dimensions[[GSDF.find.dimension(M,'lat')]]$values
    longs<-M$dimensions[[GSDF.find.dimension(M,'lon')]]$values+360
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
                           shape=0.5,
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
# Draw a background grid
draw.grid<-function(Options) {
    for(lat in seq(0,90,0.5)) {
        gp<-gpar(col=rgb(0,0.5,0,0.3),lwd=5)
        x<-seq(-180,360)
        y=rep(lat,length(x))
        rot<-GSDF.ll.to.rg(y,x,Options$pole.lat,Options$pole.lon)
        grid.lines(x=unit(rot$lon,'native'),
                   y=unit(rot$lat,'native'),
                   gp=gp)
    }
    for(lat in seq(0,90,5)) {
        gp<-gpar(col=rgb(0,0.5,0,0.3),lwd=10)
        x<-seq(-180,180)
        y=rep(lat,length(x))
        rot<-GSDF.ll.to.rg(y,x,Options$pole.lat,Options$pole.lon)
        grid.lines(x=unit(rot$lon,'native'),
                   y=unit(rot$lat,'native'),
                   gp=gp)
    }
    for(lon in seq(0,360,0.5)) {
        gp<-gpar(col=rgb(0,0.5,0,0.3),lwd=5)
        y<-seq(1,89,1)
        x=rep(lon,length(y))
        rot<-GSDF.ll.to.rg(y,x,Options$pole.lat,Options$pole.lon)
        grid.lines(x=unit(rot$lon,'native'),
                   y=unit(rot$lat,'native'),
                   gp=gp)
    }
    for(lon in seq(0,360,5)) {
        gp<-gpar(col=rgb(0,0.5,0,0.3),lwd=10)
        y<-seq(1,89,1)
        x=rep(lon,length(y))
        rot<-GSDF.ll.to.rg(y,x,Options$pole.lat,Options$pole.lon)
        grid.lines(x=unit(rot$lon,'native'),
                   y=unit(rot$lat,'native'),
                   gp=gp)
    }
}

plot.hour<-function(year,month,day,hour) {    

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
    image.name<-sprintf("%04d-%02d-%02d:%02d:%02d.png",year,month,day,as.integer(hour),
                                                         as.integer(hour%%1*60))
    ifile.name<-sprintf("%s/%s",Imagedir,image.name)
    #if(file.exists(ifile.name) && file.info(ifile.name)$size>0) return()

     png(ifile.name,
             width=33.1*300/2,
             height=46.8*300/2,
             bg=Options$sea.colour,
             pointsize=96,
             type='cairo')
    Options$label<-sprintf("%04d-%02d-%02d:%02d",year,month,day,as.integer(hour))

  
  	   pushViewport(dataViewport(c(Options$lon.min,Options$lon.max),
  				     c(Options$lat.min,Options$lat.max),
  				      extension=0))
      draw.grid(Options)
      WeatherMap.draw.land(land,Options)
      obs<-TWCR.get.obs(year,month,day,hour,version=version)
      w<-which(obs$Longitude>180)
      obs$Longitude[w]<-obs$Longitude[w]-360
      WeatherMap.draw.obs(obs,Options)

      # Assimilate the Fort William ob.
      rll<-GSDF.ll.to.rg(station.lat,station.lon,Options$pole.lat,Options$pole.lon)
      asm<-EnKF.field.assimilate(e,e,list(Latitude=station.lat,
                                          Longitude=station.lon,
                                          value=get.new.data(day,hour)))
      for(vn in seq_along(members)) {
            m<-GSDF.select.from.1d(e,'ensemble',vn)
  	    m$data[]<-as.vector(m$data)-as.vector(prmsl.normal$data)
  	    Draw.pressure(m,Options,colour=c(0,0,0,0.5))
          }

    # Mark the new ob
    grid.points(x=unit(rll$lon,'native'),
                y=unit(rll$lat,'native'),
                size=unit(Options$obs.size*1.5,'native'),
                pch=21,
                gp=gpar(col='red',fill='red'))
    
      Options$label<-sprintf("%04d-%02d-%02d:%02d",year,month,day,as.integer(hour))
      WeatherMap.draw.label(Options)
    
    upViewport()
    
    dev.off()
}

plot.hour(opt$year,opt$month,opt$day,opt$hour)
