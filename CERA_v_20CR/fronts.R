#!/usr/bin/Rscript --no-save

# Compare the CERA20C and 20CR2c ensembles
# Print quality - A0 format

library(GSDF.TWCR)
library(GSDF.CERA20C)
library(GSDF.WeatherMap)
library(GSDF.Front)
library(grid)

opt = list(
  year = 1987,
  month = 10,
  day = 16,
  hour = 0
  )

Imagedir<-"."

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'land.colour',rgb(150,150,150,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'sea.colour',rgb(200,200,200,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'ice.colour',rgb(230,230,230,255,
                                                       maxColorValue=255))
range<-75
Options<-WeatherMap.set.option(Options,'lat.min',range*-1)
Options<-WeatherMap.set.option(Options,'lat.max',range)
Options<-WeatherMap.set.option(Options,'lon.min',range*-1/sqrt(2))
Options<-WeatherMap.set.option(Options,'lon.max',range/sqrt(2))
Options<-WeatherMap.set.option(Options,'pole.lon',180)
Options<-WeatherMap.set.option(Options,'pole.lat',181)
Options$vp.lon.min<-Options$lon.min
Options$vp.lon.max<-Options$lon.max
Options<-WeatherMap.set.option(Options,'wrap.spherical',F)
Options<-WeatherMap.set.option(Options,'obs.size',1)
Options<-WeatherMap.set.option(Options,'obs.colour',rgb(255,215,0,255,
                                                       maxColorValue=255))

Options$ice.points<-1000000

Options$mslp.base=101325                    # Base value for anomalies
Options$mslp.range=50000                    # Anomaly for max contour
Options$mslp.step=1000                       # Smaller -> more contours
Options$mslp.tpscale=5                      # Smaller -> contours less transparent
Options$mslp.lwd=10.0
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
if(FALSE) {
    orog<-GSDF.ncdf.load(sprintf("%s/orography/ETOPO2v2c_ud.nc",Sys.getenv('SCRATCH')),'z',
                                 lat.range=c(-90,90),lon.range=c(-180,360))
    orog$data[orog$data<0]<-0 # sea-surface, not sea-bottom
    is.na(orog$data[orog$data==0])<-TRUE
}

TWCR.get.member.at.hour<-function(variable,year,month,day,hour,member=1,version='3.5.1') {

       t<-TWCR.get.members.slice.at.hour(variable,year,month,day,
                                  hour,version=version)
       t<-GSDF.select.from.1d(t,'ensemble',member)
       gc()
       return(t)
}

# Get the CERA20C grid data (same as ERA40)
gc<-readRDS('ERA_grids/ERA40_grid.Rdata')
w<-which(gc$centre.lat<0)
gc<-gc[w,]

# And the 20CR grid data
gt<-readRDS('ERA_grids/TWCR_grid.Rdata')
w<-which(gt$centre.lat<0)
gt<-gt[w,]

# And the ERA5 grid - use for precip
g5<-readRDS('ERA_grids/ERA5_grid.Rdata')
w<-which(g5$centre.lat<0)
g5<-g5[w,]

gp<-g5
gp$min.lon<-gp$min.lon+(gp$centre.lon-gp$min.lon)*0.05
gp$min.lat<-gp$min.lat+(gp$centre.lat-gp$min.lat)*0.05
gp$max.lon<-gp$max.lon+(gp$centre.lon-gp$max.lon)*0.05
gp$max.lat<-gp$max.lat+(gp$centre.lat-gp$max.lat)*0.05

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
    

# Sub-divide the grid for regions where higher resolution is necessary
double.resolution<-function(lats,lons) {
  if(!is.array(lons)) lons<-array(data=lons,dim=c(4,length(lons)/4))
  if(!is.array(lats)) lats<-array(data=lats,dim=c(4,length(lats)/4))
  sub.lons<-array(dim=c(4,length(lons)))
  sub.lats<-array(dim=c(4,length(lats)))
  sub.idx<-seq(1,length(lons),4)
  # bottom left
  sub.lons[1,sub.idx]<-lons[1,]
  sub.lons[2,sub.idx]<-(lons[1,]+lons[2,])/2
  sub.lons[3,sub.idx]<-(lons[1,]+lons[2,]+
                        lons[3,]+lons[4,])/4
  sub.lons[4,sub.idx]<-(lons[1,]+lons[4,])/2
  sub.lats[1,sub.idx]<-lats[1,]
  sub.lats[2,sub.idx]<-(lats[1,]+lats[2,])/2
  sub.lats[3,sub.idx]<-(lats[1,]+lats[2,]+
                        lats[3,]+lats[4,])/4
  sub.lats[4,sub.idx]<-(lats[1,]+lats[4,])/2
  # bottom right
  sub.lons[1,sub.idx+1]<-sub.lons[2,sub.idx]
  sub.lons[2,sub.idx+1]<-lons[2,]
  sub.lons[3,sub.idx+1]<-(lons[2,]+lons[3,])/2
  sub.lons[4,sub.idx+1]<-sub.lons[3,sub.idx]
  sub.lats[1,sub.idx+1]<-sub.lats[2,sub.idx]
  sub.lats[2,sub.idx+1]<-lats[2,]
  sub.lats[3,sub.idx+1]<-(lats[2,]+lats[3,])/2
  sub.lats[4,sub.idx+1]<-sub.lats[3,sub.idx]
  # Top right
  sub.lons[1,sub.idx+2]<-sub.lons[3,sub.idx]
  sub.lons[2,sub.idx+2]<-sub.lons[3,sub.idx+1]
  sub.lons[3,sub.idx+2]<-lons[3,]
  sub.lons[4,sub.idx+2]<-(lons[3,]+lons[4,])/2
  sub.lats[1,sub.idx+2]<-sub.lats[3,sub.idx]
  sub.lats[2,sub.idx+2]<-sub.lats[3,sub.idx+1]
  sub.lats[3,sub.idx+2]<-lats[3,]
  sub.lats[4,sub.idx+2]<-(lats[3,]+lats[4,])/2
  # Top left
  sub.lons[1,sub.idx+3]<-sub.lons[4,sub.idx]
  sub.lons[2,sub.idx+3]<-sub.lons[3,sub.idx]
  sub.lons[3,sub.idx+3]<-sub.lons[4,sub.idx+2]
  sub.lons[4,sub.idx+3]<-lons[4,]
  sub.lats[1,sub.idx+3]<-sub.lats[4,sub.idx]
  sub.lats[2,sub.idx+3]<-sub.lats[3,sub.idx]
  sub.lats[3,sub.idx+3]<-sub.lats[4,sub.idx+2]
  sub.lats[4,sub.idx+3]<-lats[4,]

  return(list(lats=sub.lats,lons=sub.lons))
}

# Draw a background grid
draw.grid<-function(Options) {
    for(lat in seq(-90,0,2.5)) {
        gp<-gpar(col=rgb(0,0.5,0,0.2),lwd=0.1)
        x<-seq(-180,180)
        y=rep(lat,length(x))
        rot<-GSDF.ll.to.rg(y,x,Options$pole.lat,Options$pole.lon)
        grid.lines(x=unit(rot$lon,'native'),
                   y=unit(rot$lat,'native'),
                   gp=gp)
    }
    for(lat in seq(-90,0,10)) {
        gp<-gpar(col=rgb(0,0.5,0,0.2),lwd=1)
        x<-seq(-180,180)
        y=rep(lat,length(x))
        rot<-GSDF.ll.to.rg(y,x,Options$pole.lat,Options$pole.lon)
        grid.lines(x=unit(rot$lon,'native'),
                   y=unit(rot$lat,'native'),
                   gp=gp)
    }
    for(lon in seq(0,360,2.5)) {
        gp<-gpar(col=rgb(0,0.5,0,0.2),lwd=0.1)
        y<-seq(-89,-1,1)
        x=rep(lon,length(y))
        rot<-GSDF.ll.to.rg(y,x,Options$pole.lat,Options$pole.lon)
        grid.lines(x=unit(rot$lon,'native'),
                   y=unit(rot$lat,'native'),
                   gp=gp)
    }
    for(lon in seq(0,360,10)) {
        gp<-gpar(col=rgb(0,0.5,0,0.2),lwd=1)
        y<-seq(-89,-1,1)
        x=rep(lon,length(y))
        rot<-GSDF.ll.to.rg(y,x,Options$pole.lat,Options$pole.lon)
        grid.lines(x=unit(rot$lon,'native'),
                   y=unit(rot$lat,'native'),
                   gp=gp)
    }
}
                        
# Draw a field, point by point - using a reduced gaussian grid
draw.by.rgg<-function(field,grid,colour.function,selection.function,Options,
                      grid.colour=rgb(0.8,0.8,0.8,0),grid.lwd=0,grid.lty=1) {

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
        inside<-array(data=selection.function(vert.lat,vert.lon),
                      dim=c(4,length(vert.lat[1,])))
        # Fill in the fiddly area near the boundary
        w<-which((inside[1,] | inside[2,] | inside[3,] | inside[4,]) &
                 !(inside[1,] & inside[2,] & inside[3,] & inside[4,]))
        boundary.lat<-vert.lat[,w]
        boundary.lon<-vert.lon[,w]
        while(length(boundary.lon)>0) {
           bp<-double.resolution(boundary.lat,boundary.lon)
           boundary.lat<-bp$lats
           boundary.lon<-bp$lons
           gp<-gpar(col=rgb(0.8,0.8,0.8,0),fill=group,lwd=0)
           inside<-array(data=selection.function(boundary.lat,boundary.lon),
                         dim=c(4,length(boundary.lat[1,])))
           w<-which(inside[1,] & inside[2,] & inside[3,] & inside[4,])
           if(length(w)>0) {
              grid.polygon(x=unit(as.vector(boundary.lon[,w]),'native'),
                           y=unit(as.vector(boundary.lat[,w]),'native'),
                           id.lengths=rep(4,length(w)),
                           gp=gp)
           }
           w<-which((inside[1,] | inside[2,] | inside[3,] | inside[4,]) &
                    !(inside[1,] & inside[2,] & inside[3,] & inside[4,]))
           if(length(w)==0) break
           boundary.lat<-boundary.lat[,w]
           boundary.lon<-boundary.lon[,w]
           if(!is.array(boundary.lon)) boundary.lon<-array(data=boundary.lon,
                                                           dim=c(4,length(boundary.lon)/4))
           if(!is.array(boundary.lat)) boundary.lat<-array(data=boundary.lat,
                                                           dim=c(4,length(boundary.lat)/4))
           d.lat<-abs(boundary.lat[2,]-boundary.lat[1,])+
                  abs(boundary.lat[3,]-boundary.lat[2,])+
                  abs(boundary.lat[4,]-boundary.lat[3,])+
                  abs(boundary.lat[4,]-boundary.lat[1,])
           d.lon<-abs(boundary.lon[2,]-boundary.lon[1,])+
                  abs(boundary.lon[3,]-boundary.lon[2,])+
                  abs(boundary.lon[4,]-boundary.lon[3,])+
                  abs(boundary.lon[4,]-boundary.lon[1,])
           w<-which(d.lat>0.1 | d.lon>0.1)
           if(length(w)==0) break
           boundary.lat<-boundary.lat[,w]
           boundary.lon<-boundary.lon[,w]           
        }
        # add all the normal points inside the boundaries
        inside<-array(data=selection.function(vert.lat,vert.lon),
                      dim=c(4,length(vert.lat[1,])))
        w<-which(inside[1,] & inside[2,] & inside[3,] & inside[4,])
        if(length(w)==0) next
        vert.lat<-vert.lat[,w]
        vert.lon<-vert.lon[,w]
        if(!is.array(vert.lat)) vert.lat<-array(data=vert.lat,dim=c(4,length(vert.lat)/4))
        if(!is.array(vert.lon)) vert.lon<-array(data=vert.lon,dim=c(4,length(vert.lon)/4))
        gp<-gpar(col=grid.colour,fill=group,lwd=grid.lwd,lty=grid.lty)
        #gp<-gpar(col=rgb(0.8,0.8,0.8,0),fill=group,lwd=0)
        grid.polygon(x=unit(as.vector(vert.lon),'native'),
                     y=unit(as.vector(vert.lat),'native'),
                     id.lengths=rep(4,dim(vert.lat)[2]),
                     gp=gp)
    }
}

# Subdivide a segmented line into shorter segments
upline<-function(line) {
    nseg<-length(line$x)
    result<-list(x=rep(NA,nseg*2-1),
                 x=rep(NA,nseg*2-1))
    sq<-seq(1,nseg*2-1,2)
    result$x[sq]<-line$x
    result$y[sq]<-line$y
    sq<-seq(2,nseg*2-2,2)
    result$x[sq]<-(result$x[sq-1]+result$x[sq+1])/2
    result$y[sq]<-(result$y[sq-1]+result$y[sq+1])/2
    result$level<-line$level
    return(result)
}

draw.pressure<-function(mslp,selection.function,Options,colour=c(0,0,0,1)) {

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
         #lines[[i]]<-upline(upline(lines[[i]]))
         tp<-min(1,(abs(lines[[i]]$level-Options$mslp.base)/
                    Options$mslp.tpscale))
         lt<-5
         lwd<-1
         if(lines[[i]]$level<=Options$mslp.base) {
             lt<-1
             lwd<-1
         }
         gp<-gpar(col=rgb(colour[1],colour[2],colour[3],colour[4]),
                             lwd=Options$mslp.lwd*lwd,lty=lt)
         res<-tryCatch({
             for(p in seq_along(lines[[i]]$x)) {
               if(!selection.function(lines[[i]]$y[p],lines[[i]]$x[p])) {
                 is.na(lines[[i]]$y[p])<-TRUE
                 is.na(lines[[i]]$x[p])<-TRUE
               }
              }
            grid.xspline(x=unit(lines[[i]]$x,'native'),
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

draw.precipitation<-function(prate,value.function,selection.function,Options) {
    prate<-GSDF.WeatherMap:::WeatherMap.rotate.pole(prate,Options)

    res<-0.2
    lon.points<-seq(-180,180,res)+Options$vp.lon.min+180
    lat.points<-seq(-90,90,res)
    lon.ex<-sort(rep(lon.points,length(lat.points)))
    lat.ex<-rep(lat.points,length(lon.points))
    value.points<-GSDF.interpolate.2d(prate,lon.ex,lat.ex)
    value<-value.function(value.points)
    w<-which(is.na(value))
    if(length(w)>0) {
        lon.ex<-lon.ex[-w]
        lat.ex<-lat.ex[-w]
        value<-value[-w]
    }
    scale<-runif(length(lon.ex),min=0.03,max=0.07)*4*value
    lat.jitter<-runif(length(lon.ex),min=res*-1/2,max=res/2)
    lon.jitter<-runif(length(lon.ex),min=res*-1/2,max=res/2)
    vert.lat<-array(dim=c(2,length(lat.ex)))
    vert.lat[1,]<-lat.ex+lat.jitter+scale
    vert.lat[2,]<-lat.ex+lat.jitter-scale
    vert.lon<-array(dim=c(2,length(lon.ex)))
    vert.lon[1,]<-lon.ex+lon.jitter+scale/2
    vert.lon[2,]<-lon.ex+lon.jitter-scale/2
    inside<-array(data=selection.function(vert.lat,vert.lon),
                  dim=c(2,length(vert.lat[1,])))
    w<-which(inside[1,] & inside[2,])
    vert.lat<-vert.lat[,w]
    vert.lon<-vert.lon[,w]
    gp<-gpar(col=rgb(0,0.2,0,1,1),fill=rgb(0,0.2,0,1,1),lwd=0.5)
    grid.polyline(x=unit(as.vector(vert.lon),'native'),
                  y=unit(as.vector(vert.lat),'native'),
                  id.lengths=rep(2,dim(vert.lat)[2]),
                  gp=gp)
    
}

draw.streamlines<-function(s,selection.function,Options) {

    gp<-set.streamline.GC(Options)
    inside<-array(data=selection.function(s[['y']],s[['x']]),
                  dim=c(length(s[['x']][,1]),3))
    w<-which(inside[,1] & inside[,2] & inside[,3])
    s[['x']]<-s[['x']][w,]
    s[['y']]<-s[['y']][w,]
    grid.xspline(x=unit(as.vector(t(s[['x']])),'native'),
                 y=unit(as.vector(t(s[['y']])),'native'),
                 id.lengths=rep(Options$wind.vector.points,length(s[['x']][,1])),
                 shape=s[['shape']],
                 arrow=Options$wind.vector.arrow,
                 gp=gp)
 }

# Choose TWCR points to plot
select.TWCR<-function(lat,lon) {
  lat.boundary<-centre.lat+(lon-centre.lon)*0.1
  lon.boundary<-centre.lon+(lat-centre.lat)*2
  result<-rep(FALSE,length(lat))
  w<-which((lon<centre.lon & lat>lat.boundary) |
           (lat>centre.lat & lon<lon.boundary)) 
  if(length(w)>0) result[w]<-TRUE
  return(result)
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

# Colour function for t2m
set.t2m.colour<-function(temperature,Trange=5) {

  result<-rep(NA,length(temperature))
  w<-which(temperature>=0)
  if(length(w)>0) {
     temperature[w]<-sqrt(temperature[w])
     temperature[w]<-pmax(0,pmin(Trange,temperature[w]))
     temperature[w]<-temperature[w]/Trange
     temperature[w]<-round(temperature[w],2)
     result[w]<-rgb(1,0,0,temperature[w]*0.5)
  }
  w<-which(temperature<0)
  if(length(w)>0) {
     temperature[w]<-sqrt(temperature[w]*-1)
     temperature[w]<-pmax(0,pmin(Trange,temperature[w]))
     temperature[w]<-temperature[w]/Trange
     temperature[w]<-round(temperature[w],2)
     result[w]<-rgb(0,0,1,temperature[w]*0.5)
 }
 return(result)
}

#Colour function for ice
set.ice.colour<-function(ice) {
    result<-rep(NA,length(ice))
    w<-which(ice>0) 
    ice[w]<-round(ice[w],2)
    result[w]<-rgb(1,1,1,ice[w]*1)
    return(result)
}
# Want to plot obs coverage rather than observations - make pseudo
#  observations indicating coverage.
plot.obs.coverage<-function(obs,Options) {
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
  # Filter to .5/degree lat and lon
  idx<-sprintf("%4d%4d",as.integer(obs$Latitude*1),as.integer(obs$Longitude*1))
  w<-which(duplicated(idx))
  if(length(w)>0) obs<-obs[-w,]
  gp<-gpar(col=Options$obs.colour,fill=Options$obs.colour)
  grid.points(x=unit(obs$Longitude,'native'),
              y=unit(obs$Latitude,'native'),
              size=unit(Options$obs.size,'native'),
              pch=21,gp=gp)
}  


# Colour function for streamlines
set.streamline.GC<-function(Options) {

   alpha<-255
   return(gpar(col=rgb(125,125,125,alpha,maxColorValue=255),
               fill=rgb(125,125,125,alpha,maxColorValue=255),lwd=1.5))
}



# Make the actual plot

image.name<-sprintf("CERA_20CR.pdf",year,month,day,hour)
ifile.name<-sprintf("%s/%s",Imagedir,image.name)

 pdf(ifile.name,
         width=46.8,
         height=33.1,
         bg='white',
         family='Helvetica',
     pointsize=24)

# CERA half

pushViewport(viewport(x=unit(1/4,'npc'),y=unit(1/2,'npc'),
                      width=unit(0.5-0.01,'npc'),
                      height=unit(1.0-0.01,'npc')))

  base.gp<-gpar(fontfamily='Helvetica',fontface='bold',col='black')
  lon.min<-Options$lon.min
  if(!is.null(Options$vp.lon.min)) lon.min<-Options$vp.lon.min
  lon.max<-Options$lon.max
  if(!is.null(Options$vp.lon.max)) lon.max<-Options$vp.lon.max
  lat.min<-Options$lat.min
  if(!is.null(Options$vp.lat.min)) lat.min<-Options$vp.lat.min
  lat.max<-Options$lat.max
  if(!is.null(Options$vp.lat.max)) lat.max<-Options$vp.lat.max

  grid.polygon(x=c(0,1,1,0),y=c(0,0,1,1),gp=gpar(col=Options$sea.colour,
                                                 fill=Options$sea.colour))
  pushViewport(dataViewport(c(lon.min,lon.max),c(lat.min,lat.max),
                            extension=0,gp=base.gp,clip='on'))


  draw.grid(Options)
  warnings()
  icec<-CERA20C.get.slice.at.hour('icec',opt$year,opt$month,opt$day,opt$hour)
  draw.by.rgg(icec,g5,set.ice.colour,function(lat,lon) return(rep(TRUE,length(lat))),Options)
  draw.land.flat(Options)

  for(member in seq(0,9)) {

     #if(member==1) {
         u<-CERA20C.get.slice.at.hour('uwnd.10m',opt$year,opt$month,opt$day,opt$hour,member=member)
         v<-CERA20C.get.slice.at.hour('vwnd.10m',opt$year,opt$month,opt$day,opt$hour,member=member)
         ct<-lubridate::ymd_hms(sprintf("%04d-%02d-%02d:%02d:%02d:00",
                               opt$year,opt$month,opt$day,
                               as.integer(opt$hour),
                                        as.integer((opt$hour%%1)*60)))-lubridate::hours(6)
         u.old<-CERA20C.get.slice.at.hour('uwnd.10m',lubridate::year(ct),
                                                  lubridate::month(ct),
                                                  lubridate::day(ct),
                                                  lubridate::hour(ct)+
                                                  lubridate::minute(ct)/60,member=member)
         v.old<-CERA20C.get.slice.at.hour('vwnd.10m',lubridate::year(ct),
                                                  lubridate::month(ct),
                                                  lubridate::day(ct),
                                                  lubridate::hour(ct)+
                                                  lubridate::minute(ct)/60,member=member)

         fronts<-Front.find(u,v,u.old,v.old)
         rfgp<-gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1),lwd=0.5)
         if(member==1) rfgp<-gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1),lwd=4)
         for(i in seq_along(fronts)) {
            Front.plot(fronts[[i]],rfgp,Options)
         }
     #}
     
     select.CERA20C<-function(lat,lon) {
        result<-rep(TRUE,length(lat))
        return(result)
     }
     mslp<-CERA20C.get.slice.at.hour('prmsl',opt$year,opt$month,opt$day,opt$hour,member=member)
     draw.pressure(mslp,select.CERA20C,Options,colour=c(0,0,1,0.1))

  }
popViewport()
popViewport() # End of CERA half

# 20CR half

pushViewport(viewport(x=unit(3/4,'npc'),y=unit(1/2,'npc'),
                      width=unit(0.5-0.01,'npc'),
                      height=unit(1.0-0.01,'npc')))

  base.gp<-gpar(fontfamily='Helvetica',fontface='bold',col='black')
  lon.min<-Options$lon.min
  if(!is.null(Options$vp.lon.min)) lon.min<-Options$vp.lon.min
  lon.max<-Options$lon.max
  if(!is.null(Options$vp.lon.max)) lon.max<-Options$vp.lon.max
  lat.min<-Options$lat.min
  if(!is.null(Options$vp.lat.min)) lat.min<-Options$vp.lat.min
  lat.max<-Options$lat.max
  if(!is.null(Options$vp.lat.max)) lat.max<-Options$vp.lat.max


  grid.polygon(x=c(0,1,1,0),y=c(0,0,1,1),gp=gpar(col=Options$sea.colour,
                                                 fill=Options$sea.colour))
  pushViewport(dataViewport(c(lon.min,lon.max),c(lat.min,lat.max),
                            extension=0,gp=base.gp,clip='on'))

  draw.grid(Options)
  icec<-TWCR.get.slice.at.hour('icec',opt$year,opt$month,opt$day,opt$hour,version='3.5.1')
  draw.by.rgg(icec,g5,set.ice.colour,function(lat,lon) return(rep(TRUE,length(lat))),Options)
  draw.land.flat(Options)

  for(member in seq(1,56)) {
                 
     select.TWCR<-function(lat,lon) {
        result<-rep(TRUE,length(lat))
        return(result)
     }
     mslp<-TWCR.get.member.at.hour('prmsl',opt$year,opt$month,opt$day,opt$hour,member=member,version='3.5.1')
     draw.pressure(mslp,select.TWCR,Options,colour=c(0,0,1,0.01))

 }
  obs<-TWCR.get.obs(opt$year,opt$month,opt$day,opt$hour,version='3.5.1')
  plot.obs.coverage(obs,Options)

popViewport()
popViewport() # End of 20CR half

dev.off()

