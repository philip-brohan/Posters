#!/usr/bin/Rscript --no-save

# The weather of the great storm of 1987 - in three reanalyses
# Print quality - A0 format

library(GSDF.TWCR)
library(GSDF.CERA20C)
library(GSDF.ERAI)
library(GSDF.WeatherMap)
library(grid)

opt = list(
  year = 1987,
  month = 10,
  day = 16,
  hour = 0
  )

Imagedir<-"."

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

TWCR.get.member.at.hour<-function(variable,year,month,day,hour,member=1,version='3.5.1') {

       t<-TWCR.get.members.slice.at.hour(variable,year,month,day,
                                  hour,version=version)
       t<-GSDF.select.from.1d(t,'ensemble',member)
       gc()
       return(t)
}

# Get the ERA Interim grid data
gi<-readRDS('ERA_grids/ERAI_grid.Rdata')

# And the CERA20C grid data (same as ERA40
gc<-readRDS('ERA_grids/ERA40_grid.Rdata')

# And the 20CR grid data
gt<-readRDS('ERA_grids/TWCR_grid.Rdata')

# And the ERA5 grid - use for precip
g5<-readRDS('ERA_grids/ERA5_grid.Rdata')

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
                        
  

# Draw a field, point by point - using a reduced gaussian grid
draw.by.rgg<-function(field,grid,colour.function,selection.function,Options,
                      grid.colour=rgb(1,1,1,0.25),grid.lwd=0.01,grid.lty=1) {

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
        if(length(w)<2) next
        vert.lat<-vert.lat[,w]
        vert.lon<-vert.lon[,w]
        gp<-gpar(col=grid.colour,fill=group,lwd=grid.lwd,lty=grid.lty)
        #gp<-gpar(col=rgb(0.8,0.8,0.8,0),fill=group,lwd=0)
        grid.polygon(x=unit(as.vector(vert.lon),'native'),
                     y=unit(as.vector(vert.lat),'native'),
                     id.lengths=rep(4,dim(vert.lat)[2]),
                     gp=gp)
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


# Centre point for boundary functions
centre.lat<-7.36-0.5
centre.lon<-50-38.8-1

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
# Choose ERAI points to plot
select.ERAI<-function(lat,lon) {
  upper.boundary<-centre.lon+(lat-centre.lat)*2
  lower.boundary<-centre.lon+(centre.lat-lat)*1.5
  result<-rep(FALSE,length(lat))
  w<-which((lat>centre.lat & lon>upper.boundary) |
           (lat<centre.lat & lon>lower.boundary)) 
  result[w]<-TRUE
  return(result)
}
# Choose CERA points to plot
select.CERA20C<-function(lat,lon) {
  result<-rep(TRUE,length(lat))
  w<-which(select.TWCR(lat,lon) | select.ERAI(lat,lon))
  result[w]<-FALSE
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
  w<-which(temperature>0)
  if(length(w)>0) {
     temperature[w]<-sqrt(temperature[w])
     temperature[w]<-pmax(0,pmin(Trange,temperature[w]))
     temperature[w]<-temperature[w]/Trange
     temperature[w]<-round(temperature[w],2)
     result[w]<-rgb(1,0,0,temperature[w]*0.8)
  }
  w<-which(temperature<0)
  if(length(w)>0) {
     temperature[w]<-sqrt(temperature[w]*-1)
     temperature[w]<-pmax(0,pmin(Trange,temperature[w]))
     temperature[w]<-temperature[w]/Trange
     temperature[w]<-round(temperature[w],2)
     result[w]<-rgb(0,0,1,temperature[w]*0.8)
 }
 return(result)
}


# Colour function for streamlines
set.streamline.GC<-function(Options) {

   alpha<-255
   return(gpar(col=rgb(125,125,125,alpha,maxColorValue=255),
               fill=rgb(125,125,125,alpha,maxColorValue=255),lwd=1.5))
}



# Make the actual plot

image.name<-sprintf("1987_storm.pdf",year,month,day,hour)
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

  icec<-ERAI.get.slice.at.hour('icec',opt$year,opt$month,opt$day,opt$hour)
  ip<-WeatherMap.rectpoints(Options$ice.points,Options)
  WeatherMap.draw.ice(ip$lat,ip$lon,icec,Options)
  draw.land.flat(Options)

  t2m<-ERAI.get.slice.at.hour('air.2m',opt$year,opt$month,opt$day,opt$hour)
  t2n<-ERAI.get.slice.at.hour('air.2m',opt$year,opt$month,opt$day,opt$hour,type='normal')
  t2m$data[]<-t2m$data-t2n$data
  draw.by.rgg(t2m,gi,set.t2m.colour,select.ERAI,Options)

  t2m<-TWCR.get.member.at.hour('air.2m',opt$year,opt$month,opt$day,opt$hour,version='3.5.1')
  t2n<-TWCR.get.slice.at.hour('air.2m',opt$year,opt$month,opt$day,opt$hour,version='3.4.1',type='normal')
  t2n<-GSDF.regrid.2d(t2n,t2m)
  t2m$data[]<-t2m$data-t2n$data
  draw.by.rgg(t2m,gt,set.t2m.colour,select.TWCR,Options)

  t2m<-CERA20C.get.slice.at.hour('air.2m',opt$year,opt$month,opt$day,opt$hour)
  t2n<-CERA20C.get.slice.at.hour('air.2m',opt$year,opt$month,opt$day,opt$hour,type='normal')
  t2m$data[]<-as.vector(t2m$data)-as.vector(t2n$data)
  draw.by.rgg(t2m,gc,set.t2m.colour,select.CERA20C,Options)

  mslp<-ERAI.get.slice.at.hour('prmsl',opt$year,opt$month,opt$day,opt$hour)
  draw.pressure(mslp,select.ERAI,Options)
  mslp<-TWCR.get.member.at.hour('prmsl',opt$year,opt$month,opt$day,opt$hour,version='3.5.1')
  draw.pressure(mslp,select.TWCR,Options)
  mslp<-CERA20C.get.slice.at.hour('prmsl',opt$year,opt$month,opt$day,opt$hour)
  draw.pressure(mslp,select.CERA20C,Options)

  streamlines<-readRDS('streamlines.ERAI.rd')
  draw.streamlines(streamlines,select.ERAI,Options)
  streamlines<-readRDS('streamlines.TWCR.rd')
  draw.streamlines(streamlines,select.TWCR,Options)
  streamlines<-readRDS('streamlines.CERA20C.rd')
  draw.streamlines(streamlines,select.CERA20C,Options)
 
  prate<-ERAI.get.slice.at.hour('prate',opt$year,opt$month,opt$day,opt$hour)
  prate$data[]<-prate$data/3.6 # Convert to Kg/m/s
  draw.by.rgg(prate,g5,set.precip.colour,select.ERAI,Options,grid.colour=rgb(0,0.2,0,0),grid.lwd=1)

  prate<-TWCR.get.member.at.hour('prate',opt$year,opt$month,opt$day,opt$hour,version='3.5.1')
  draw.by.rgg(prate,g5,set.precip.colour,select.TWCR,Options,grid.colour=rgb(1,1,1,0),grid.lwd=1)

  prate<-CERA20C.get.slice.at.hour('prate',opt$year,opt$month,opt$day,opt$hour)
  prate$data[]<-prate$data/3.6 # Convert to Kg/m/s
  draw.by.rgg(prate,g5,set.precip.colour,select.CERA20C,Options,grid.colour=rgb(0,0.2,0,0),grid.lwd=1)

  # Mark the boundary
  gp<-gpar(col=rgb(1,1,0.5),fill=rgb(1,1,0.5),lwd=2)
  grid.lines(x=unit(c(centre.lon,centre.lon+(90-centre.lat)*2),'native'),
             y=unit(c(centre.lat,90),'native'),
             gp=gp)
  grid.lines(x=unit(c(centre.lon,centre.lon+(centre.lat+90)*1.5),'native'),
             y=unit(c(centre.lat,-90),'native'),
             gp=gp)
  grid.lines(x=unit(c(Options$vp.lon.min,centre.lon),'native'),
             y=unit(c(centre.lat-(centre.lon-Options$vp.lon.min)*0.1,centre.lat),'native'),
             gp=gp)

  dev.off()

