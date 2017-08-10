#!/usr/bin/env Rscript

# The weather of December 2010 - in the 20CR2c reanalyis
# Print quality - A0 format

library(GSDF.TWCR)
library(GSDF.WeatherMap)
library(grid)

opt = list(
  year = 2010,
  month = 9,
  day = 16,
  hour = 12
  )

Imagedir<-sprintf("%s/Posters/2010_multi_r",Sys.getenv('SCRATCH'))

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'land.colour',rgb(200,200,200,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'sea.colour',rgb(255,255,255,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'ice.colour',rgb(255,255,255,255,
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
Options<-WeatherMap.set.option(Options,'wind.vector.points',3)

Options$ice.points<-1000000

Options$mslp.base=101325                    # Base value for anomalies
Options$mslp.range=50000                    # Anomaly for max contour
Options$mslp.step=500                       # Smaller -> more contours
Options$mslp.tpscale=5                      # Smaller -> contours less transparent
Options$mslp.lwd=2
Options$precip.colour=c(0,0.2,0)
contour.levels<-seq(Options$mslp.base-Options$mslp.range,
                    Options$mslp.base+Options$mslp.range,
                    Options$mslp.step)

# Load the 0.25 degree orography
orog<-GSDF.ncdf.load(sprintf("%s/orography/elev.0.25-deg.nc",Sys.getenv('SCRATCH')),'data',
                             lat.range=c(-90,90),lon.range=c(-180,360))
orog$data[orog$data<0]<-0 # sea-surface, not sea-bottom
is.na(orog$data[orog$data==0])<-TRUE
# 1-km orography (slow, needs lots of ram)
if(TRUE) {
    orog<-GSDF.ncdf.load(sprintf("%s/orography/ETOPO2v2c_ud.nc",Sys.getenv('SCRATCH')),'z',
    lat.range=c(-90,90),lon.range=c(-180,360))
    orog$data[orog$data<0]<-0 # sea-surface, not sea-bottom
    is.na(orog$data[orog$data==0])<-TRUE
}

# Get the ERA Interim grid data
gi<-readRDS('ERA_grids/ERAI_grid.Rdata')

# And the CERA20C grid data (same as ERA40
gc<-readRDS('ERA_grids/ERA40_grid.Rdata')

# And the 20CR grid data
gt<-readRDS('ERA_grids/TWCR_grid.Rdata')

# And the ERA5 grid 
g5<-readRDS('ERA_grids/ERA5_grid.Rdata')

gp<-g5
gp$min.lon<-gp$min.lon+(gp$centre.lon-gp$min.lon)*0.05
gp$min.lat<-gp$min.lat+(gp$centre.lat-gp$min.lat)*0.05
gp$max.lon<-gp$max.lon+(gp$centre.lon-gp$max.lon)*0.05
gp$max.lat<-gp$max.lat+(gp$centre.lat-gp$max.lat)*0.05

TWCR.get.member.at.hour<-function(variable,year,month,day,hour,member=1,version='3.5.1') {

       t<-TWCR.get.members.slice.at.hour(variable,year,month,day,
                                  hour,version=version)
       t<-GSDF.select.from.1d(t,'ensemble',member)
       gc()
       return(t)
}

# Plot the orography - raster background, fast
draw.land.flat<-function(Options) {
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

# Boxes that straddle the date line need to be rationalised and duplicated
polish.longitudes<-function(lats,lons) {
   w<-which(abs(lons[1,]-lons[2,])>200 |
            abs(lons[2,]-lons[3,])>200 |
            abs(lons[3,]-lons[4,])>200 |
            abs(lons[4,]-lons[1,])>200)
   lat.extras<-array(dim=c(4,length(w)))
   lon.extras<-array(dim=c(4,length(w)))
   for(i in seq_along(w)) {
       w2<-which(lons[,w[i]]>0)
       lons[w2,w[i]]<-lons[w2,w[i]]-360
       lon.extras[,i]<-lons[,w[i]]+360
       lat.extras[,i]<-lats[,w[i]]
   }
   return(list(lat=cbind(lats,lat.extras),
               lon=cbind(lons,lon.extras)))
}
                         
Draw.temperature<-function(temperature,Options,Trange=1) {

  Options.local<-Options
  Options.local$fog.min.transparency<-0.8
  Options.local$fog.resolution<-0.25
  tplus<-temperature
  tplus$data[]<-pmax(0,pmin(Trange,tplus$data))
  tplus$data[]<-sqrt(tplus$data[])/Trange
  Options.local$fog.colour<-c(1,0,0)
  WeatherMap.draw.fog(tplus,Options.local)
  tminus<-temperature
  tminus$data[]<-tminus$data*-1
  tminus$data[]<-pmax(0,pmin(Trange,tminus$data))
  tminus$data[]<-sqrt(tminus$data[])/Trange
  Options.local$fog.colour<-c(0,0,1)
  WeatherMap.draw.fog(tminus,Options.local)
}
# Colour function for t2m

set.t2m.colour<-function(temperature,Trange=8) {

  result<-rep(NA,length(temperature))
  w<-which(temperature>0)
  if(length(w)>0) {
     temperature[w]<-sqrt(temperature[w])
     temperature[w]<-pmax(0,pmin(Trange,temperature[w]))
     temperature[w]<-temperature[w]/Trange
     temperature[w]<-round(temperature[w],2)
     result[w]<-rgb(1,0,0,temperature[w]*Options$fog.min.transparency)
  }
  w<-which(temperature<0)
  if(length(w)>0) {
     temperature[w]<-temperature[w]*-1
     temperature[w]<-sqrt(temperature[w])
     temperature[w]<-pmax(0,pmin(Trange,temperature[w]))
     temperature[w]<-temperature[w]/Trange
     temperature[w]<-round(temperature[w],2)
     result[w]<-rgb(0,0,1,temperature[w]*Options$fog.min.transparency)
 }
 return(result)
}

# Draw the grid reduced gaussian grid
draw.grid<-function(field,grid,colour.function,Options,
                      grid.lwd=0.01,grid.lty='blank') {

    field<-GSDF:::GSDF.pad.longitude(field) # Extras for periodic boundary conditions
    value.points<-GSDF.interpolate.2d(field,grid$centre.lon,grid$centre.lat)
    col<-colour.function(value.points)
    for(group in unique(na.omit(col))) {        
        w<-which(col==group)
        vert.lon<-array(dim=c(4,length(w)))
        vert.lon[1,]<-grid$min.lon[w]
        vert.lon[2,]<-grid$max.lon[w]
        vert.lon[3,]<-grid$max.lon[w]
        vert.lon[4,]<-grid$min.lon[w]
        vert.lat<-array(dim=c(4,length(w)))
        vert.lat[1,]<-grid$min.lat[w]
        vert.lat[2,]<-grid$min.lat[w]
        vert.lat[3,]<-grid$max.lat[w]
        vert.lat[4,]<-grid$max.lat[w]
        w<-which(vert.lon-Options$pole.lon==180)
        if(length(w)>0) vert.lon[w]<-vert.lon[w]+0.0001
        for(v in seq(1,4)) {
            p.r<-GSDF.ll.to.rg(vert.lat[v,],vert.lon[v,],Options$pole.lat,Options$pole.lon)
            vert.lat[v,]<-p.r$lat
            vert.lon[v,]<-p.r$lon
        }
        w<-which(vert.lon>Options$vp.lon.max)
        if(length(w)>0) vert.lon[w]<-vert.lon[w]-360
        w<-which(vert.lon<Options$vp.lon.min)
        if(length(w)>0) vert.lon[w]<-vert.lon[w]+360
        pl<-polish.longitudes(vert.lat,vert.lon)
        vert.lat<-pl$lat
        vert.lon<-pl$lon
        gp<-gpar(col=group,fill=rgb(1,1,1,0),lwd=grid.lwd,lty=grid.lty)
        grid.polygon(x=unit(as.vector(vert.lon),'native'),
                     y=unit(as.vector(vert.lat),'native'),
                     id.lengths=rep(4,dim(vert.lat)[2]),
                     gp=gp)
    }
}

draw.pressure<-function(mslp,Options,colour=c(0,0,0)) {

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

draw.streamlines<-function(s,Options) {

    gp<-set.streamline.GC(Options)
    grid.xspline(x=unit(as.vector(t(s[['x']])),'native'),
                 y=unit(as.vector(t(s[['y']])),'native'),
                 id.lengths=rep(Options$wind.vector.points,length(s[['x']][,1])),
                 shape=s[['shape']],
                 arrow=Options$wind.vector.arrow,
                 gp=gp)
 }



# Intensity function for precipitation
set.precip.value<-function(rate) {
  min.threshold<-0.0025
  max.threshold<-0.03
  rate<-sqrt(pmax(0,rate))
  result<-rep(NA,length(rate))
  value<-pmax(0,pmin(1,rate/max.threshold))
  w<-which(runif(length(rate),0,1)<value & rate>min.threshold)
  if(length(w)>0) result[w]<-value[w]
  return(result)
}
# Colour function for precipitation
set.precip.colour<-function(rate) {
  min.threshold<-0.0025
  max.threshold<-0.03
  rate<-sqrt(pmax(0,rate,na.rm=TRUE))
  result<-rep(NA,length(rate))
  value<-pmax(0,pmin(0.9,rate/max.threshold,na.rm=TRUE),na.rm=TRUE)
  w<-which(is.na(value))
  if(length(w)>0) value[w]<-0
  result<-rgb(0,0.2,0,value)
  w<-which(rate<min.threshold)
  is.na(result[w])<-TRUE
  return(result)
}



# Colour function for streamlines
set.streamline.GC<-function(Options) {

   alpha<-155
   return(gpar(col=rgb(125,125,125,alpha,maxColorValue=255),
               fill=rgb(125,125,125,alpha,maxColorValue=255),lwd=1.5))
}

draw.label<-function(Options,label) {
    label.gp<-gpar(family='Helvetica',font=1,col='black')
    xp<-unit(0.99,'npc')
    yp<-unit(0.01*16/9,'npc')    
    tg<-textGrob(label,x=xp,y=yp,
                              hjust=1,vjust=0,
                              gp=label.gp)
   bg.gp<-gpar(col=rgb(1,1,1,0),fill=rgb(0.75,0.75,0.75,0.35))
   h<-heightDetails(tg)
   w<-widthDetails(tg)
   b<-unit(0.2,'char') # border
   grid.polygon(x=unit.c(xp+b,xp-w-b,xp-w-b,xp+b),
                y=unit.c(yp+h+b,yp+h+b,yp-b,yp-b),
                gp=bg.gp)
   grid.draw(tg)
}

# Make the actual plot

image.name<-"20CR2c.pdf"
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

  draw.land.flat(Options)

  t2m<-TWCR.get.member.at.hour('air.2m',opt$year,opt$month,opt$day,opt$hour,member=1,version='3.5.1')
  t2n<-TWCR.get.slice.at.hour('air.2m',opt$year,opt$month,opt$day,opt$hour,version='3.4.1',type='normal')
  t2n<-GSDF.regrid.2d(t2n,t2m)
  t2m$data[]<-as.vector(t2m$data)-as.vector(t2n$data)
  Draw.temperature(t2m,Options,Trange=7)
  draw.grid(t2m,gt,set.t2m.colour,Options,grid.lwd=0.5,grid.lty=1)

  mslp<-TWCR.get.member.at.hour('prmsl',opt$year,opt$month,opt$day,opt$hour,member=1,version='3.5.1')
  draw.pressure(mslp,Options)

  streamlines<-readRDS(sprintf("%s/20CR2c.streamlines.rd",Imagedir))
  draw.streamlines(streamlines,Options)
 
  prate<-TWCR.get.member.at.hour('prate',opt$year,opt$month,opt$day,opt$hour,member=1,version='3.5.1')
  WeatherMap.draw.precipitation(prate,Options)
  draw.grid(prate,gt,set.precip.colour,Options,grid.lwd=0.5,grid.lty=1)

  # Add the label
   draw.label(Options,sprintf("%04d-%02d-%02d:%02d",opt$year,opt$month,
                              opt$day,opt$hour))

 dev.off()

