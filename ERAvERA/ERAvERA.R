#!/usr/bin/Rscript --no-save

# Poster comparing ERA5 with ERA Interim
# Print quality - A0 format

library(GSDF.ERA5)
library(GSDF.ERAI)
library(GSDF.TWCR)
library(GSDF.WeatherMap)
library(grid)

opt = list(
  year = 2016,
  month = 1,
  day = 30,
  hour = 12
  )

Imagedir<-sprintf(".",Sys.getenv('SCRATCH'))

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'land.colour',rgb(150,150,150,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'sea.colour',rgb(200,200,200,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'ice.colour',rgb(250,250,250,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'background.resolution','high')
Options<-WeatherMap.set.option(Options,'pole.lon',160)
Options<-WeatherMap.set.option(Options,'pole.lat',45)

Options<-WeatherMap.set.option(Options,'lat.min',-90)
Options<-WeatherMap.set.option(Options,'lat.max',90)
Options<-WeatherMap.set.option(Options,'lon.min',-190+50)
Options<-WeatherMap.set.option(Options,'lon.max',190+50)
Options$vp.lon.min<- -180+50
Options$vp.lon.max<-  180+50
Options<-WeatherMap.set.option(Options,'wrap.spherical',F)

Options<-WeatherMap.set.option(Options,'wind.vector.points',3)
Options<-WeatherMap.set.option(Options,'wind.vector.scale',0.2)
Options<-WeatherMap.set.option(Options,'wind.vector.move.scale',1)
Options<-WeatherMap.set.option(Options,'wind.vector.density',0.5)
Options<-WeatherMap.set.option(Options,'wind.vector.lwd',1.5)
Options$ice.points<-1000000
Options<-WeatherMap.set.option(Options,'precip.min.transparency',0.9)
Options<-WeatherMap.set.option(Options,'fog.min.transparency',0.0)

Options$mslp.base=101325                    # Base value for anomalies
Options$mslp.range=50000                    # Anomaly for max contour
Options$mslp.step=500                       # Smaller -> more contours
Options$mslp.tpscale=5                      # Smaller -> contours less transparent
Options$mslp.lwd=2
Options$precip.colour=c(0,0.2,0)
# Overrides mslp options
contour.levels<-seq(-300,300,30)
contour.levels<-abs(contour.levels)**1.5*sign(contour.levels)
contour.levels<-contour.levels+Options$mslp.base

# Load the 0.25 degree orography
orog<-GSDF.ncdf.load(sprintf("%s/orography/elev.0.25-deg.nc",Sys.getenv('SCRATCH')),'data',
                             lat.range=c(-90,90),lon.range=c(-180,360))
orog$data[orog$data<0]<-0 # sea-surface, not sea-bottom
is.na(orog$data[orog$data==0])<-TRUE
# 1-km orography (slow, needs lots of ram)
if(FALSE) {
    orog<-GSDF.ncdf.load(sprintf("%s/orography/ETOPO2v2c_f4.nc",Sys.getenv('SCRATCH')),'z',
                                 lat.name='y',lon.name='x',
                                 lat.range=c(-90,90),lon.range=c(-180,360))
    orog$data[orog$data<0]<-0 # sea-surface, not sea-bottom
    is.na(orog$data[orog$data==0])<-TRUE
}

# Get the ERA Interim grid data
gi<-read.table('ERA_grids/ERAI_grid.txt')
g5<-read.table('ERA_grids/ERA5_grid.txt')

# Plot the orography - raster background, fast
draw.land<-function(Options,n.levels=20) {
   land<-GSDF.WeatherMap:::WeatherMap.rotate.pole(GSDF:::GSDF.pad.longitude(orog),Options)
   lons<-land$dimensions[[GSDF.find.dimension(land,'lon')]]$values
   qtls<-quantile(land$data,probs=seq(0,1,1/n.levels),na.rm=TRUE)
   base.colour<-col2rgb(Options$land.colour)/255
   peak.colour<-c(.8,.8,.8)
   plot.colours<-rep(rgb(0,0,0,0),length(land$data))
   for(level in seq_along(qtls)) {
      if(level==1) next
      fraction<-1-(level-1)/n.levels
      plot.colour<-base.colour*fraction+peak.colour*(1-fraction)
      plot.colour<-rgb(plot.colour[1],plot.colour[2],plot.colour[3])
      w<-which(land$data>=qtls[level-1] & land$data<=qtls[level])
      plot.colours[w]<-plot.colour
      }
      byrow<-TRUE
      if(GSDF.find.dimension(land,'lon')==2) byrow<-FALSE
      m<-matrix(plot.colours, ncol=length(lons), byrow=TRUE)
      r.w<-max(lons)-min(lons)+(lons[2]-lons[1])
      r.c<-(max(lons)+min(lons))/2
      grid.raster(m,,
                   x=unit(r.c,'native'),
                   y=unit(0,'native'),
                   width=unit(r.w,'native'),
                   height=unit(180,'native'))  
}
# Plot the orography - raster background, fast
draw.land.flat<-function(Options,n.levels=20) {
   land<-GSDF.WeatherMap:::WeatherMap.rotate.pole(GSDF:::GSDF.pad.longitude(orog),Options)
   lons<-land$dimensions[[GSDF.find.dimension(land,'lon')]]$values
   base.colour<-Options$land.colour
   plot.colours<-rep(rgb(0,0,0,0),length(land$data))
      w<-which(land$data>0)
      plot.colours[w]<-base.colour
      m<-matrix(plot.colours, ncol=length(lons), byrow=TRUE)
      r.w<-max(lons)-min(lons)+(lons[2]-lons[1])
      r.c<-(max(lons)+min(lons))/2
      grid.raster(m,,
                   x=unit(r.c,'native'),
                   y=unit(0,'native'),
                   width=unit(r.w,'native'),
                   height=unit(180,'native'))  
}

# Draw a field, point by point
draw.by.grid<-function(field,colour.function,selection.function,Options) {

  for(lat in seq(1,length(field$dimensions[[2]]$values))) {
    stride<-cos(lat*pi/180)  
    for(lon in seq(1,length(field$dimensions[[1]]$values))) {
      if(is.na(field$data[lon,lat,1])) next
      col<-colour.function(field$data[lon,lat,1])
      if(is.null(col)) next 
      gp<-gpar(col=rgb(0.8,0.8,0.8,1),fill=col,lwd=0.2)
      #gp<-gpar(col=rgb(0.7,1.0,0.7,1),fill=col,lwd=0.2)
      x<-field$dimensions[[1]]$values[lon]
      dx<-abs(field$dimensions[[1]]$values[2]-field$dimensions[[1]]$values[1])*1
      y<-field$dimensions[[2]]$values[lat]
      dy<-abs(field$dimensions[[2]]$values[2]-field$dimensions[[2]]$values[1])*1
      p.x<-c(x-dx/2,x+dx/2,x+dx/2,x-dx/2)
      p.y<-c(y-dy/2,y-dy/2,y+dy/2,y+dy/2)
      p.r<-GSDF.ll.to.rg(p.y,p.x,Options$pole.lat,Options$pole.lon,polygon=TRUE)
      if(max(p.r$lon)<Options$vp.lon.min) p.r$lon<-p.r$lon+360
      if(min(p.r$lon)>Options$vp.lon.max) p.r$lon<-p.r$lon-360
      if(!selection.function(p.r$lat,p.r$lon)) next
      grid.polygon(x=unit(p.r$lon,'native'),
                   y=unit(p.r$lat,'native'),
                   gp=gp)
      if(min(p.r$lon)<Options$vp.lon.min) {
        p.r$lon<-p.r$lon+360
        if(!selection.function(p.r$lat,p.r$lon)) next
        grid.polygon(x=unit(p.r$lon,'native'),
                     y=unit(p.r$lat,'native'),
                     gp=gp)
      }
      if(max(p.r$lon)>Options$vp.lon.max) {
         p.r$lon<-p.r$lon-360
         if(!selection.function(p.r$lat,p.r$lon)) next
         grid.polygon(x=unit(p.r$lon,'native'),
                      y=unit(p.r$lat,'native'),
                      gp=gp)
    
      }
    }
  }

}
# Draw a field, point by point - using a reduced gaussian grid
draw.by.rgg<-function(field,grid,colour.function,selection.function,Options) {

  field<-GSDF:::GSDF.pad.longitude(field) # Extras for periodic boundary conditions
  d.lat<-grid$V5[1]-grid$V5[2]
  for(lat.i in seq_along(grid$V5)) {
    lat<-grid$V5[lat.i]
    d.lon<-360/grid$V2[lat.i]
    for(lon.i in seq(1,grid$V2[lat.i])) {
      lon<-(lon.i-0.5)*d.lon
      value.point<-GSDF.interpolate.2d(field,lon,lat)
      if(is.na(value.point)) next
      col<-colour.function(value.point)
      if(is.null(col)) next 
      gp<-gpar(col=rgb(0.8,0.8,0.8,1),fill=col,lwd=0.1)
      #gp<-gpar(col=rgb(0.7,1.0,0.7,1),fill=col,lwd=0.1)
      x<-lon
      dx<-d.lon*1
      if(x<Options$vp.lon.min-dx/2) x<-x+360
      if(x>Options$vp.lon.max+dx/2) x<-x-360
      y<-lat
      dy<-d.lat*1
      p.x<-c(x-dx/2,x+dx/2,x+dx/2,x-dx/2)
      p.y<-c(y-dy/2,y-dy/2,y+dy/2,y+dy/2)
      p.r<-GSDF.ll.to.rg(p.y,p.x,Options$pole.lat,Options$pole.lon,polygon=TRUE)
      if(max(diff(p.r$lon))>45) next # Projection bug
      if(max(p.r$lon)<Options$vp.lon.min) p.r$lon<-p.r$lon+360
      if(min(p.r$lon)>Options$vp.lon.max) p.r$lon<-p.r$lon-360
      if(!selection.function(p.r$lat,p.r$lon)) next
      grid.polygon(x=unit(p.r$lon,'native'),
                   y=unit(p.r$lat,'native'),
                   gp=gp)
      if(min(p.r$lon)<Options$vp.lon.min) {
        p.r$lon<-p.r$lon+360
        if(!selection.function(p.r$lat,p.r$lon)) next
        grid.polygon(x=unit(p.r$lon,'native'),
                     y=unit(p.r$lat,'native'),
                     gp=gp)
      }
      if(max(p.r$lon)>Options$vp.lon.max) {
         p.r$lon<-p.r$lon-360
         if(!selection.function(p.r$lat,p.r$lon)) next
         grid.polygon(x=unit(p.r$lon,'native'),
                      y=unit(p.r$lat,'native'),
                      gp=gp)
    
      }
    }
  }

}

draw.pressure<-function(mslp,selection.function,Options,colour=c(0,0,0)) {

  M<-GSDF.WeatherMap:::WeatherMap.rotate.pole(mslp,Options)
  M<-GSDF:::GSDF.pad.longitude(M) # Extras for periodic boundary conditions
  lats<-M$dimensions[[GSDF.find.dimension(M,'lat')]]$values
  longs<-M$dimensions[[GSDF.find.dimension(M,'lon')]]$values
    # Need particular data format for contourLines
  maxl<-Options$vp.lon.max+2
  if(lats[2]<lats[1] || longs[2]<longs[1] || max(longs) > maxl ) {
    if(lats[2]<lats[1]) lats<-rev(lats)
    if(longs[2]<longs[1]) longs<-rev(longs)
    longs[longs>maxl]<-longs[longs>maxl]-(maxl*2)
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
     for(i in seq(1,length(lines))) {
         tp<-min(1,(abs(lines[[i]]$level-Options$mslp.base)/
                    Options$mslp.tpscale))
         lt<-5
         lwd<-1
         if(lines[[i]]$level<=Options$mslp.base) {
             lt<-1
             lwd<-1
         }
         gp<-gpar(col=rgb(colour[1],colour[2],colour[3],tp),
                             lwd=Options$mslp.lwd*lwd,lty=lt)
         res<-tryCatch({
             for(p in seq_along(lines[[i]]$x)) {
               if(!selection.function(lines[[i]]$y[p],lines[[i]]$x[p])) {
                 is.na(lines[[i]]$y[p])<-TRUE
                 is.na(lines[[i]]$x[p])<-TRUE
               }
              }
            grid.lines(x=unit(lines[[i]]$x,'native'),
			y=unit(lines[[i]]$y,'native'),
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

draw.precipitation<-function(prate,colour.function,selection.function,Options) {
    prate<-GSDF.WeatherMap:::WeatherMap.rotate.pole(prate,Options)
    for(lat in seq(-90,90,0.1)) {
        for(lon in seq(-180,180,0.1)) {
          jtr<-runif(4,min=-0.05,max=0.05)
          value.point<-GSDF.interpolate.2d(prate,lon,lat)
          if(is.na(value.point)) next
          col<-colour.function(value.point)
          if(is.null(col)) next 
          gp<-gpar(col=col,fill=col,lwd=0.3)
          pln<-c(lon+0.025+jtr[1],lon-0.025+jtr[1]+jtr[2]/5)
          plt<-c(lat+0.05+jtr[3],lat-0.05+jtr[3]+jtr[4]/5)
          if(!selection.function(plt,pln)) next
          grid.lines(x=unit(pln,'native'),
                     y=unit(plt,'native'),
                     gp=gp)
      }
    }
}

# Use a sigmoid as the boundary between the reanalyses
boundary<-function(lat) {
    return(Options$vp.lon.min+180+240*(0.5-(1/(1+exp(lat*-5/90)))))
}

# Choose ERA5 points to plot
select.ERA5<-function(lat,lon) {
  lat.boundary<-boundary(lat)
  if(any(lon<lat.boundary)) return(FALSE)
  return(TRUE)
}
# Choose ERAI points to plot
select.ERAI<-function(lat,lon) {
  lat.boundary<-boundary(lat)
  if(any(lon>lat.boundary)) return(FALSE)
  return(TRUE)
}

# Colour function for precipitation
set.precip.colour<-function(rate) {
  col<-c(0,0.2,0,1)
  min.threshold<-0.0025
  max.threshold<-0.03
  rate<-sqrt(rate)
  if(rate<min.threshold) return(NULL)
  value<-max(0,min(1,rate/max.threshold))
  if(runif(1,0,1)>value) return(NULL)
  return(rgb(col[1],col[2],col[3],1))
}

# Colour function for t2m
set.t2m.colour<-function(temperature,Trange=7) {

  if(temperature>0) {
     temperature<-max(0,min(Trange,temperature))
     temperature<-sqrt(temperature)/Trange
     return(rgb(1,0,0,min(temperature,0.8)))
  }
  temperature<-temperature*-1
  temperature<-max(0,min(Trange,temperature))
  temperature<-sqrt(temperature)/Trange
  return(rgb(0,0,1,min(temperature,0.8)))
}


# Make the actual plot

image.name<-sprintf("ERA5vERAI.pdf",year,month,day,hour)
ifile.name<-sprintf("%s/%s",Imagedir,image.name)

 pdf(ifile.name,
         width=46.8,
         height=33.1,
         bg=Options$sea.colour,
         family='Helvetica',
         pointsize=24)

  base.gp<-gpar(fontfamily='Helvetica',fontface='bold',col='black')
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

  icec<-ERA5.get.slice.at.hour('icec',opt$year,opt$month,opt$day,opt$hour)
  ip<-WeatherMap.rectpoints(Options$ice.points,Options)
  WeatherMap.draw.ice(ip$lat,ip$lon,icec,Options)
  draw.land.flat(Options,n.levels=100)

  t2m<-ERAI.get.slice.at.hour('air.2m',opt$year,opt$month,opt$day,opt$hour)
  t2n<-readRDS(sprintf("%s/ERA_Interim/climtologies.test/air.2m.%02d.Rdata",
                           Sys.getenv('SCRATCH'),opt$hour))
  t2m$data[]<-t2m$data-t2n$data
  draw.by.rgg(t2m,gi,set.t2m.colour,select.ERAI,Options)

  t2m<-ERA5.get.slice.at.hour('air.2m',opt$year,opt$month,opt$day,opt$hour)
  t2n<-readRDS(sprintf("%s/ERA5/oper/climtologies.test/air.2m.%02d.Rdata",
                           Sys.getenv('SCRATCH'),opt$hour))
  t2m$data[]<-t2m$data-t2n$data
  draw.by.rgg(t2m,g5,set.t2m.colour,select.ERA5,Options)

  mslp<-ERAI.get.slice.at.hour('prmsl',opt$year,opt$month,opt$day,opt$hour)
  #mn<-readRDS(sprintf("%s/ERA_Interim/climtologies.test/prmsl.%02d.Rdata",
  #                         Sys.getenv('SCRATCH'),opt$hour))
  #mslp$data[]<-mslp$data-mn$data
  draw.pressure(mslp,select.ERAI,Options)
  mslp<-ERA5.get.slice.at.hour('prmsl',opt$year,opt$month,opt$day,opt$hour)
  #mn<-readRDS(sprintf("%s/ERA5/oper/climtologies.test/prmsl.%02d.Rdata",
  #                         Sys.getenv('SCRATCH'),opt$hour))
  #mslp$data[]<-mslp$data-mn$data
  draw.pressure(mslp,select.ERA5,Options)

  prate<-ERAI.get.slice.at.hour('prate',opt$year,opt$month,opt$day,opt$hour)
  prate$data[]<-prate$data/3
  draw.precipitation(prate,set.precip.colour,select.ERAI,Options)

  prate<-ERA5.get.slice.at.hour('prate',opt$year,opt$month,opt$day,opt$hour)
  prate$data[]<-prate$data/3
  draw.precipitation(prate,set.precip.colour,select.ERA5,Options)

  #draw.by.rgg(prate,gi,set.precip.colour,select.ERAI,Options)
  #prate<-ERA5.get.slice.at.hour('prate',opt$year,opt$month,opt$day,opt$hour)
  #prate$data[]<-prate$data/3
  #draw.by.rgg(prate,g5,set.precip.colour,select.ERA5,Options)

  # Mark the boundary
  gp<-gpar(col=rgb(1,1,0),fill=rgb(1,1,0),lwd=4)
  grid.lines(x=unit(boundary(seq(-90,90)),'native'),
             y=unit(seq(-90,90),'native'),
             gp=gp)

  dev.off()

