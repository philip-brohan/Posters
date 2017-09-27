#!/usr/bin/env Rscript

# Poster comparing 20CRv2 with 20CRv2c.
# Print quality - A0 format

library(GSDF.TWCR)
library(GSDF.WeatherMap)
library(grid)
library(lubridate)
library(png)

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
Options<-WeatherMap.set.option(Options,'land.colour',rgb(150,150,150,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'sea.colour',rgb(255,255,255,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'ice.colour',rgb(255,255,255,255,
                                                       maxColorValue=255))

Options<-WeatherMap.set.option(Options,'lat.min',-90)
Options<-WeatherMap.set.option(Options,'lat.max',90)
Options<-WeatherMap.set.option(Options,'lon.min',-190)
Options<-WeatherMap.set.option(Options,'lon.max',190)
Options$vp.lon.min<- -180
Options$vp.lon.max<-  180

Options<-WeatherMap.set.option(Options,'wrap.spherical',F)
Options$precip.colour=c(0,0.2,0)
Options$label.xp=0.995
Options<-WeatherMap.set.option(Options,'obs.size',1.5)
Options<-WeatherMap.set.option(Options,'obs.colour',rgb(255,215,0,255,
                                                       maxColorValue=255))
Options$ice.points<-1000000
Options$fog.resolution<-0.25

Options$mslp.base=101325                    # Base value for anomalies
Options$mslp.range=50000                    # Anomaly for max contour
Options$mslp.step=500                       # Smaller -> more contours
Options$mslp.tpscale=5                      # Smaller -> contours less transparent
Options$mslp.lwd=3
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

get.member.at.hour<-function(variable,year,month,day,hour,member,version='3.5.1') {

       t<-TWCR.get.members.slice.at.hour(variable,year,month,day,
                                  hour,version=version)
       t<-GSDF.select.from.1d(t,'ensemble',member)
       gc()
       return(t)
  }
get.mean.at.hour<-function(variable,year,month,day,hour,member,version='3.5.1') {

       t<-TWCR.get.members.slice.at.hour(variable,year,month,day,
                                  hour,version=version)
       t<-GSDF.reduce.1d(t,'ensemble',mean)
       gc()
       return(t)
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

Draw.temperature<-function(temperature,Options,Trange=1) {

  Options.local<-Options
  Options.local$fog.min.transparency<-0.5
  tplus<-temperature
  tplus$data[]<-pmax(0,pmin(Trange,tplus$data))/Trange
  Options.local$fog.colour<-c(1,0,0)
  WeatherMap.draw.fog(tplus,Options.local)
  tminus<-temperature
  tminus$data[]<-tminus$data*-1
  tminus$data[]<-pmax(0,pmin(Trange,tminus$data))/Trange
  Options.local$fog.colour<-c(0,0,1)
  WeatherMap.draw.fog(tminus,Options.local)
}
draw.temperature<-function(temperature,Options,Trange=1) {

  temperature$data<-temperature$data+0.7 # Shift climatology
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


# Intensity function for precipitation
set.precip.value<-function(rate) {
  min.threshold<-0.0025
  max.threshold<-0.03
  rate<-sqrt(rate)
  result<-rep(NA,length(rate))
  value<-pmax(0,pmin(1,rate/max.threshold))
  w<-which(runif(length(rate),0,1)<value & rate>min.threshold)
  if(length(w)>0) result[w]<-value[w]
  return(result)
}

# Colour function for t2m
set.t2m.colour<-function(temperature,Trange=3) {

  result<-rep(NA,length(temperature))
  w<-which(temperature>0)
  if(length(w)>0) {
     temperature[w]<-sqrt(temperature[w])
     temperature[w]<-pmax(0,pmin(Trange,temperature[w]))
     temperature[w]<-temperature[w]/Trange
     temperature[w]<-round(temperature[w],1)
     result[w]<-rgb(1,0,0,temperature[w]*0.6)
  }
  w<-which(temperature<0)
  if(length(w)>0) {
     temperature[w]<-sqrt(temperature[w]*-1)
     temperature[w]<-pmax(0,pmin(Trange,temperature[w]))
     temperature[w]<-temperature[w]/Trange
     temperature[w]<-round(temperature[w],1)
     result[w]<-rgb(0,0,1,temperature[w]*0.6)
 }
 return(result)
}


# Colour function for streamlines
set.streamline.GC<-function(Options) {

   alpha<-255
   return(gpar(col=rgb(125,125,125,alpha,maxColorValue=255),
               fill=rgb(125,125,125,alpha,maxColorValue=255),lwd=1.5))
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

recentre.obs<-function(obs) {
  if(length(obs$Latitude)<1) return()
  lon.m<-Options$lon.min
  if(!is.null(Options$vp.lon.min)) lon.m<-Options$vp.lon.min
  w<-which(obs$Longitude<lon.m)
  if(length(w)>0) obs$Longitude[w]<-obs$Longitude[w]+360
  lon.m<-Options$lon.max
  if(!is.null(Options$vp.lon.max)) lon.m<-Options$vp.lon.max
  w<-which(obs$Longitude>lon.m)
  if(length(w)>0) obs$Longitude[w]<-obs$Longitude[w]-360
  return(obs)
}

# Want to plot obs coverage rather than observations - make pseudo
#  observations indicating coverage.
plot.obs.coverage<-function(obs.new,obs.old,Options) {
  obs.old<-recentre.obs(obs.old)
  idx.old<-as.integer(obs.old$Latitude*0.5)*1000+
                            as.integer(obs.old$Longitude*0.5)
  obs.new<-recentre.obs(obs.new)
  idx.new<-as.integer(obs.new$Latitude*0.5)*1000+
                            as.integer(obs.new$Longitude*0.5)

  idx.old<-idx.old-min(c(idx.old,idx.new),na.rm=TRUE)+1
  idx.new<-idx.new-min(c(idx.old,idx.new),na.rm=TRUE)+1
  
  obs.old<-obs.old[order(idx.old),]
  idx.old<-idx.old[order(idx.old)]
  t.old<-tabulate(idx.old)
  t.old<-t.old[t.old!=0]
  d<-which(duplicated(idx.old))
  idx.old<-idx.old[-d]
  obs.old<-obs.old[-d,]

  obs.new<-obs.new[order(idx.new),]
  idx.new<-idx.new[order(idx.new)]
  t.new<-tabulate(idx.new)
  t.new<-t.new[t.new!=0]
  d<-which(duplicated(idx.new))
  idx.new<-idx.new[-d]
  obs.new<-obs.new[-d,]
  
  # indices (regions) with no more obs in new than old
  w.o<-sort(which(idx.old %in% intersect(idx.old,idx.new)))
  w.n<-sort(which(idx.new %in% intersect(idx.old,idx.new)))
  if(length(w.o)>0) {
     w.old<-which(t.old[w.o]>=t.new[w.n])
     if(length(w.old>0)) {
        w.old<-w.o[w.old]
        obs.plt<-obs.old[w.old,]
        gp<-gpar(col='black',fill=rgb(0.4,0.4,0.4,1),lwd=2.5)
        grid.points(x=unit(obs.plt$Longitude,'native'),
                    y=unit(obs.plt$Latitude,'native'),
                    size=unit(Options$obs.size*1.2,'native'),
                    pch=21,gp=gp)
      }
   }

  # indices in both but more in new than old
  if(length(w.n)>0) {
     w.new<-which(t.new[w.n]>t.old[w.o])
     if(length(w.new>0)) {
        w.new<-w.n[w.new]
        obs.plt<-obs.new[w.new,]
        gp<-gpar(col='black',fill=Options$obs.colour,lwd=2.5)
        grid.points(x=unit(obs.plt$Longitude,'native'),
                    y=unit(obs.plt$Latitude,'native'),
                    size=unit(Options$obs.size*1.5,'native'),
                    pch=21,gp=gp)
      }
   }
     
   # indices only in new
   if(length(w.n)<length(idx.new)) {
        obs.plt<-obs.new[-w.n,]
        gp<-gpar(col='black',fill=Options$obs.colour,lwd=2.5)
        grid.points(x=unit(obs.plt$Longitude,'native'),
                    y=unit(obs.plt$Latitude,'native'),
                    size=unit(Options$obs.size*1.5,'native'),
                    pch=21,gp=gp)
   }
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

  draw.land.flat(Options)
  
  t2m<-get.mean.at.hour('air.2m',year,month,day,hour,1,version='3.5.1')
  t2n<-TWCR.get.slice.at.hour('air.2m',year,month,day,hour,type='normal',version='3.4.1')
  t2n<-GSDF.regrid.2d(t2n,t2m)
  t2m$data[]<-t2m$data-t2n$data
  draw.temperature(t2m,Options,Trange=7)
  
  prmsl<-get.mean.at.hour('prmsl',year,month,day,hour,1,version='3.5.1')
  draw.pressure(prmsl,Options)
  
  prate<-get.mean.at.hour('prate',year,month,day,hour,1,version='3.5.1')
  WeatherMap.draw.precipitation(prate,Options)
  
  # Mark regions where new obs have made things better
  m.o<-TWCR.get.members.slice.at.hour('prmsl',year,month,day,hour,version='3.2.1')
  m.o<-GSDF.reduce.1d(m.o,'ensemble',sd)
  fg.o<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.2.1',
                                type='first.guess.spread')
  fg.o<-GSDF.regrid.2d(fg.o,m.o)
  m.n<-TWCR.get.members.slice.at.hour('prmsl',year,month,day,hour,version='3.5.1')
  m.n<-GSDF.reduce.1d(m.n,'ensemble',sd)
  fg.n<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.5.1',
                                type='first.guess.spread')
  fg.n<-GSDF.regrid.2d(fg.n,m.n)

  sf<-m.n
  sf$data[]<-m.o$data/m.n$data-fg.o$data/fg.n$data
  threshold<-quantile(sf$data[sf$data<0],0.05)*-1
  sf$data[]<-1/(1+exp((sf$data-threshold)*-20))
  Options$fog.colour<-c(1,0.8,0)
  Options$fog.resolution<-0.25
  Options$fog.min.transparency<-0.7
  WeatherMap.draw.fog(sf,Options)
  
  # Show new obs, since v2 in yellow, old ones in black
  obs.new<-TWCR.get.obs.1file(year,month,day,hour,version='3.5.1')
  obs.old<-TWCR.get.obs.1file(year,month,day,hour,version='3.2.1')
  Options<-WeatherMap.set.option(Options,'obs.colour',rgb(255,204,0,255,
                                                          maxColorValue=255))
  plot.obs.coverage(obs.new,obs.old,Options)
  
  # Add the conventional fog
  prmsl.sd<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                                         version='3.4.1',type='standard.deviation')
  prmsl.sd<-GSDF.regrid.2d(prmsl.sd,m.n)
  fog<-m.n
  fog$data[]<-m.n$data/prmsl.sd$data
  fog$data[]<-1/(1+exp((fog$data-0.6)*-20))
  Options$fog.colour<-c(0.3,0.3,0.3)
  Options$fog.min.transparency<-0.8
  WeatherMap.draw.fog(fog,Options)

  draw.label(sprintf("%04d-%02d-%02d:%02d",year,month,day,as.integer(hour)),
             0.925,0.05,scale=1,tp=0.65)
  
  popViewport()
}

draw.label<-function(label,xp,yp,scale=1,tp=0.85) {
    label.gp<-gpar(family='Helvetica',font=1,col='black',cex=scale)
    xp<-unit(xp,'npc')
    yp<-unit(yp,'npc')    
    tg<-textGrob(label,x=xp,y=yp,
                              just='center',
                              gp=label.gp)
   bg.gp<-gpar(col=rgb(1,1,1,0),fill=rgb(1,1,1,tp))
   h<-heightDetails(tg)*(scale/2)
   w<-widthDetails(tg)*(scale/2)
   b<-unit(0.3,'char') # border
   grid.polygon(x=unit.c(xp+w+b,xp-w-b,xp-w-b,xp+w+b),
                y=unit.c(yp+h+b,yp+h+b,yp-h-b,yp-h-b),
                gp=bg.gp)
   grid.draw(tg)
}


# Make the full plot

image.name<-sprintf("data.rescue.png",year,month,day,hour)
ifile.name<-sprintf("%s/%s",Imagedir,image.name)

png(ifile.name,
    width=14038,
    height=9929,
    type='cairo-png',
    pointsize=48)

  base.gp<-gpar(fontfamily='Helvetica',fontface='bold',col='black')

 count<-0
 for(j in seq(1,5)) {
     for(i in seq(1,4)) {
      print(sprintf("%d %d",j,i))
       date<-lubridate::ymd_hms(dates[count+1])
       #Options<-set.pole(count,Options)
       pushViewport(viewport(x=unit((i-.5)/4,'npc'),
                             y=unit(1-(j-.5)/5,'npc'),
                             width=unit((1/4),'npc'),
                             height=unit((1/5),'npc'),
                             clip='on'))
          grid.polygon(x=unit(c(0,1,1,0),'npc'),
                       y=unit(c(0,0,1,1),'npc'),
                       gp=gpar(col=Options$sea.colour,fill=Options$sea.colour))
      #if(count==0 || count==19) {
          tryCatch(sub.plot(lubridate::year(date),
                   lubridate::month(date),
                   lubridate::day(date),
                   lubridate::hour(date),
                            Options),
                    error = function(c) {popViewport()}
                   )
      #}
       popViewport()
       count<-count+1
       gc(verbose=FALSE)
     }
  }

# Key - White partially-transparent background rectangle
 key.gp<-gpar(col=rgb(0,0,0,1),fill=rgb(1,1,1,0.75),
              cex=1.5)
 h<-0.15
 w<-0.10
 x.o<-0.007
 y.o<-0.027
 t.o<-0.003
 grid.polygon(x=unit(c(x.o,x.o+w,x.o+w,x.o),'npc'),
                y=unit(c(y.o,y.o,y.o+h,y.o+h),'npc'),
                gp=key.gp)
 
 g.w<-w/6
 g.h<-g.w*sqrt(2)/2
 grid.text('Weather from 20CRv2c\nensemble mean',x=unit(x.o+t.o,'npc'),
                     y=unit(y.o+h*4.5/5,'npc'),
                     just=c('left','centre'),
                     gp=key.gp)
 w.img<-readPNG('weather.sample.png')
 grid.raster(w.img,x=unit(x.o+w-t.o,'npc'),
                     y=unit(y.o+h*4.5/5,'npc'),
                     width=unit(g.w,'npc'),
                     height=unit(g.h,'npc'),
                     just=c('right','centre'),
                     gp=key.gp)
 
 grid.text('Where 20CRv2c has\nlittle skill',x=unit(x.o+t.o,'npc'),
                     y=unit(y.o+h*3.5/5,'npc'),
                     just=c('left','centre'),
                     gp=key.gp)
 fog.gp<-gpar(col=rgb(0,0,0,0),fill=rgb(0.35,0.35,0.35,0.95))
 grid.polygon(x=unit(c(x.o+w-t.o-g.w,x.o+w-t.o,
                       x.o+w-t.o,x.o+w-t.o-g.w),'npc'),
              y=unit(c(y.o-g.h/2+h*3.5/5,y.o-g.h/2+h*3.5/5,
                       y.o+g.h/2+h*3.5/5,y.o+g.h/2+h*3.5/5),'npc'),
              gp=fog.gp)
 
 grid.text('Where v2c is markedly\nbetter than v2',x=unit(x.o+t.o,'npc'),
                     y=unit(y.o+h*2.5/5,'npc'),
                     just=c('left','centre'),
                     gp=key.gp)
 glow.gp<-gpar(col=rgb(0,0,0,0),fill=rgb(255,215,0,255,
                                         maxColorValue=255))
 grid.polygon(x=unit(c(x.o+w-t.o-g.w,x.o+w-t.o,
                       x.o+w-t.o,x.o+w-t.o-g.w),'npc'),
              y=unit(c(y.o-g.h/2+h*2.5/5,y.o-g.h/2+h*2.5/5,
                       y.o+g.h/2+h*2.5/5,y.o+g.h/2+h*2.5/5),'npc'),
              gp=glow.gp)
 
 grid.text('Where there are observations\nin both v2 and v2c.',x=unit(x.o+t.o,'npc'),
                     y=unit(y.o+h*1.5/5,'npc'),
                     just=c('left','centre'),
                     gp=key.gp)
 p.x<-x.o+w-t.o-runif(5)*g.w
 p.y<-y.o+h*1.5/5+g.h/2-(runif(5)*g.h)
 old.gp<-gpar(col=rgb(0,0,0,1),fill=rgb(0.4,0.4,0.4,1),lwd=5)
 grid.points(x=unit(p.x,'npc'),
             y=unit(p.y,'npc'),
             size=unit(0.004,'npc'),
             pch=21,
             gp=old.gp)
 
 grid.text('Where there are additional\nobservations only in v2c',x=unit(x.o+t.o,'npc'),
                     y=unit(y.o+h*0.5/5,'npc'),
                     just=c('left','centre'),
                     gp=key.gp)
 p.x<-x.o+w-t.o-runif(5)*g.w
 p.y<-y.o+h*0.5/5+g.h/2-(runif(5)*g.h)
 new.gp<-gpar(col=rgb(0,0,0,1),fill=rgb(255,215,0,255,
                                         maxColorValue=255),lwd=5)
 grid.points(x=unit(p.x,'npc'),
             y=unit(p.y,'npc'),
             size=unit(0.004,'npc'),
             pch=21,
             gp=new.gp)

# Dividing lines
new.gp<-gpar(col=rgb(255,215,0,255,maxColorValue=255),lwd=10)

for(i in seq(1,3)) {
  grid.lines(x=unit(rep(0.25*i,2),'npc'),
             y=unit(c(0,1),'npc'),
             gp=new.gp)
}
for(i in seq(1,4)) {
  grid.lines(x=unit(c(0,1),'npc'),
             y=unit(rep(0.2*i,2),'npc'),
             gp=new.gp)
}

# Signature
draw.label("philip.brohan@metoffice.gov.uk",0.0375,0.0075,1.4,0.65)

dev.off()

