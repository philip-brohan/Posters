#!/usr/bin/Rscript --no-save

# Poster comparing ERA5 with ERA Interim
# Print quality - A0 format

library(GSDF.ERA5)
library(GSDF.ERAI)
library(GSDF.TWCR)
library(GSDF.WeatherMap)
library(grid)
#library(RColorBrewer)
#library(colorspace)
library(extrafont)
#loadfonts()

opt = list(
  year = 2016,
  month = 1,
  day = 30,
  hour = 12
  )

Imagedir<-sprintf(".",Sys.getenv('SCRATCH'))

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'land.colour',rgb(100,100,100,255,
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

# Draw a field, point by point
draw.by.grid<-function(field,colour.function,selection.function,Options) {

  for(lon in seq(1,length(field$dimensions[[1]]$values))) {
    for(lat in seq(1,length(field$dimensions[[2]]$values))) {
      if(is.na(field$data[lon,lat,1])) next
      col<-colour.function(field$data[lon,lat,1])
      if(is.null(col)) next 
      gp<-gpar(col=rgb(0.8,0.8,0.8,1),fill=col,lwd=0.2)
      x<-field$dimensions[[1]]$values[lon]
      dx<-abs(field$dimensions[[1]]$values[2]-field$dimensions[[1]]$values[1])*1
      if(x<Options$vp.lon.min-dx/2) x<-x+360
      if(x>Options$vp.lon.max+dx/2) x<-x-360
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
         lt<-2
         lwd<-2
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


# Choose ERA5 points to plot
select.ERA5<-function(lat,lon) {
  if(min(lon)<Options$vp.lon.min+180) return(FALSE)
  return(TRUE)
}
# Choose ERAI points to plot
select.ERAI<-function(lat,lon) {
  if(max(lon)>Options$vp.lon.min+180) return(FALSE)
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
  col[4]<-value
  return(rgb(col[1],col[2],col[3],col[4]))
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

  draw.land(Options,n.levels=100)

  mslp<-ERAI.get.slice.at.hour('prmsl',opt$year,opt$month,opt$day,opt$hour)
  draw.pressure(mslp,select.ERAI,Options)
  mslp<-ERA5.get.slice.at.hour('prmsl',opt$year,opt$month,opt$day,opt$hour)
  draw.pressure(mslp,select.ERA5,Options)

  prate<-ERAI.get.slice.at.hour('prate',opt$year,opt$month,opt$day,opt$hour)
  prate$data[]<-prate$data/3
  draw.by.grid(prate,set.precip.colour,select.ERAI,Options)
  prate<-ERA5.get.slice.at.hour('prate',opt$year,opt$month,opt$day,opt$hour)
  prate$data[]<-prate$data/3
  draw.by.grid(prate,set.precip.colour,select.ERA5,Options)

  dev.off()

#embed_fonts(ifile.name)
