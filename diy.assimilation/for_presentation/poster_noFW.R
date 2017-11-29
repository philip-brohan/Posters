#!/usr/bin/env Rscript

# Show the effect of assimilating additional observations

library(GSDF.TWCR)
library(GSDF.WeatherMap)
#library(extrafont)

opt<-list(year=1897,
          month=11,
          day=28,
          hour=18)

members=seq(1,56)

Imagedir<-sprintf("%s/Posters/EnKF_Fort_William/for_presentation",Sys.getenv('SCRATCH'))
if(!file.exists(Imagedir)) dir.create(Imagedir,recursive=TRUE)

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'land.colour',rgb(150,150,150,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'sea.colour',rgb(200,200,200,255,
                                                       maxColorValue=255))

range<-8
aspect<-16/9
Options<-WeatherMap.set.option(Options,'lat.min',range*-1+2)
Options<-WeatherMap.set.option(Options,'lat.max',range+2)
Options<-WeatherMap.set.option(Options,'lon.min',range*aspect*-1-1.5)
Options<-WeatherMap.set.option(Options,'lon.max',range*aspect-1.5)
Options<-WeatherMap.set.option(Options,'pole.lon',177.5)
Options<-WeatherMap.set.option(Options,'pole.lat',37.5)

Options$obs.size<- 0.15

land<-WeatherMap.get.land(Options)

Options$mslp.lwd<-1.5
Options$mslp.base=101325                    # Base value for anomalies
Options$mslp.range=50000                    # Anomaly for max contour
Options$mslp.step=750                       # Smaller -more contours
Options$mslp.tpscale=350                    # Smaller -contours less transparent

station.lat<-56.82
station.lon<- -5.1
FW.data<-97809
source('../assimilate_multi.R')

stations<-read.csv('DWR.csv',header=TRUE,stringsAsFactors=FALSE)

# Filter and order the obs
included<-c(1,2,3,4,5,6,7,8,9,
            10,11,12,13,14,15,16,17,19,20,
            21,22,24,25,26,27,28,29,30)
stations<-stations[included,]

order<-order(stations$X1897112818)
stations$X1897112818<-stations$X1897112818*3386.39 # Inches -> Pa
stations<-stations[order,]

contour.levels<-seq(93000,103000,800)

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
    lines<-contourLines(longs,lats,z,
                         levels=contour.levels)
    if(!is.na(lines) && length(lines)>0) {
               lt<-1
               lwd<-1
               gp<-gpar(col=rgb(colour[1],colour[2],
                                colour[3],colour[4]),
                               lwd=Options$mslp.lwd*lwd,lty=lt)
        for(i in seq(1,length(lines))) {
           res<-tryCatch({
              grid.xspline(x=unit(lines[[i]]$x,'native'),
                           y=unit(lines[[i]]$y,'native'),
                           shape=1,
                           gp=gp)
             }, warning = function(w) {
                 print(w)
             }, error = function(e) {
                # Hit MAXNUMPTS error - use straight lines instead
                grid.lines(x=unit(lines[[i]]$x,'native'),
                           y=unit(lines[[i]]$y,'native'),
                           gp=gp)
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


draw.obs<-function(obs,Options,pch=21) {

  if(Options$pole.lon!=0 || Options$pole.lat!=90) {
	   l2<-GSDF.ll.to.rg(obs$Latitude,obs$Longitude,Options$pole.lat,Options$pole.lon)
	   obs$Longitude<-l2$lon
	   obs$Latitude<-l2$lat
  }
  if(length(obs$Latitude)<1) return()
  lon.m<-Options$lon.min
  if(!is.null(Options$vp.lon.min)) lon.m<-Options$vp.lon.min
  w<-which(obs$Longitude<lon.m)
  if(length(w)>0) obs$Longitude[w]<-obs$Longitude[w]+360
  lon.m<-Options$lon.max
  if(!is.null(Options$vp.lon.max)) lon.m<-Options$vp.lon.max
  w<-which(obs$Longitude>lon.m)
  if(length(w)>0) obs$Longitude[w]<-obs$Longitude[w]-360
  gp<-gpar(col=Options$obs.colour,fill=Options$obs.colour,lwd=10)
  grid.points(x=unit(obs$Longitude,'native'),
              y=unit(obs$Latitude,'native'),
              size=unit(Options$obs.size,'native'),
              pch=pch,gp=gp)
  
}

draw.label<-function(label,xp,yp,scale=1,tp=0.85,unit='npc') {
    label.gp<-gpar(family='Helvetica',font=1,col='black',cex=scale)
    xp<-unit(xp,unit)
    yp<-unit(yp,unit)    
    tg<-textGrob(label,x=xp,y=yp,
                              just='center',
                              gp=label.gp)
   bg.gp<-gpar(col=rgb(1,1,1,0),fill=rgb(1,1,1,tp))
   h<-heightDetails(tg)*(scale/2)
   w<-widthDetails(tg)*(scale/2)
   b<-unit(5*scale,'mm') # border
   grid.polygon(x=unit.c(xp+w+b,xp-w-b,xp-w-b,xp+w+b),
                y=unit.c(yp+h+b,yp+h+b,yp-h-b,yp-h-b),
                gp=bg.gp)
   grid.draw(tg)
}

label.contours<-function(e,Options) {
    e<-GSDF.reduce.1d(e,'ensemble',mean)
    lat<-seq(50,58,0.01)
    lon<-rep(seq(-12,0,0.015))
    f<-GSDF.interpolate.ll(e,lat,lon)
    for(p in seq(97000,100900,800)) {
        i<-which.min(abs(f-p))
    	l2<-GSDF.ll.to.rg(lat[i],lon[i]+0.3,Options$pole.lat,Options$pole.lon)
        draw.label(sprintf("%d",p/100),l2$lon,l2$lat,0.75,0.5,unit='native')
    }
}
               


plot.hour<-function(year,month,day,hour) {    

    version<-'3.5.1'
       e<-TWCR.get.members.slice.at.hour('prmsl',year,month,day,
                                  hour,version=version)
      m<-GSDF.select.from.1d(e,'ensemble',1)
    image.name<-sprintf("nFW_%04d-%02d-%02d:%02d:%02d.png",year,month,day,as.integer(hour),
                                                         as.integer(hour%%1*60))
    ifile.name<-sprintf("%s/%s",Imagedir,image.name)

     png(ifile.name,
             width=33.1*aspect*300/2,
             height=33.1*300/2,
             bg=Options$sea.colour,
             pointsize=96,
             type='cairo')
    Options$label<-sprintf("%04d-%02d-%02d:%02d",year,month,day,as.integer(hour))

  
  	   pushViewport(dataViewport(c(Options$lon.min,Options$lon.max),
  				     c(Options$lat.min,Options$lat.max),
  				      extension=0))
      draw.grid(Options)
      WeatherMap.draw.land(land,Options)
    
      for(vn in seq_along(members)) {
            m<-GSDF.select.from.1d(e,'ensemble',vn)
  	    Draw.pressure(m,Options,colour=c(0,0,1,1.0))
      }
      obs<-TWCR.get.obs.1file(year,month,day,hour,version=version)
      w<-which(obs$Longitude>180)
      obs$Longitude[w]<-obs$Longitude[w]-360
      l2<-GSDF.ll.to.rg(obs$Latitude,obs$Longitude,Options$pole.lat,Options$pole.lon)
      w<-which(l2$lon> Options$lon.min & l2$lon< Options$lon.max &
               l2$lat>Options$lat.min & l2$lat< Options$lat.max)
      obs<-obs[w,]
      w<-which(obs$Assimilation.indicator==1)
      obs<-obs[w,]
      w<-which(!(duplicated(obs$Longitude) & duplicated(obs$Latitude)))
      obs<-obs[w,]
      obs$Label=trimws(obs$Name)
      obs$Value=obs$SLP
      Options$obs.colour<-rgb(0,0,1,1)
      draw.obs(obs,Options)

    
    upViewport()
    
    
    
}
plot.hour(opt$year,opt$month,opt$day,opt$hour)


draw.label(sprintf("%04d-%02d-%02d:%02d",opt$year,opt$month,opt$day,as.integer(opt$hour)),
                   0.85,0.975,1.25,0.7)


dev.off()
