#!/usr/bin/env Rscript

# Just make the streamlines for later rendering.

library(GSDF.ERAI)
library(GSDF.WeatherMap)

year<-1987
month<-10
day<-16
hour<-0

Imagedir<-'.'
if(!file.exists(Imagedir)) dir.create(Imagedir,recursive=TRUE)

Options<-WeatherMap.set.option(NULL)
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
Options$ice.points<-100000


    s<-NULL
    sf.name<-sprintf("%s/streamlines.ERAI.rd",
                           Imagedir,year,month,day,hour)

    uwnd<-ERAI.get.slice.at.hour('uwnd.10m',year,month,day,hour)
    vwnd<-ERAI.get.slice.at.hour('vwnd.10m',year,month,day,hour)
    t.actual<-ERAI.get.slice.at.hour('air.2m',year,month,day,hour)
    t.normal<-ERAI.get.slice.at.hour('air.2m',year,month,day,hour,type='normal')
    #t.normal<-t.actual
    #t.normal$data[]<-rep(286,length(t.normal$data))
    s<-WeatherMap.make.streamlines(s,uwnd,vwnd,t.actual,t.normal,Options)
    s<-WeatherMap.make.streamlines(s,uwnd,vwnd,t.actual,t.normal,Options)
    Options$bridson.subsample<-1
    s<-WeatherMap.make.streamlines(s,uwnd,vwnd,t.actual,t.normal,Options)
    s$status<-s$status*0+5
    saveRDS(s,file=sf.name)

