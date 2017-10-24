#!/usr/bin/env Rscript

# Compare the validation obs from the DWR to the reanalysis
# Ensemble

library(grid)
library(GSDF.TWCR)

opt<-list(year=1903,
          month=2,
          day=7,
          hour=18)

members=seq(1,56)

Imagedir<-sprintf("%s/Posters/EnKF_Fort_William",Sys.getenv('SCRATCH'))
if(!file.exists(Imagedir)) dir.create(Imagedir,recursive=TRUE)

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
source('./assimilate_multi.R')
source('validation_data.R')

# Filter and order the obs
included<-c(1,2,3,4,6,7,8,9,10,11,12,14,15,16,17,19,20,
            21,22,24,25,26,27)
stations<-stations[included,]
mslp<-data.frame(X1903020718=mslp$X1903020718[included])

order<-order(mslp$X1903020718)
mslp<-data.frame(X1903020718=mslp$X1903020718[order]*3386.39) # Inches -> Pa
stations<-stations[order,]

# Get the reanalysis data
e<-TWCR.get.members.slice.at.hour('prmsl',opt$year,opt$month,
                                          opt$day,opt$hour,
                                          version='3.5.1')

# Assimilate the Fort William ob.
#asm<-EnKF.field.assimilate(e,e,list(Latitude=station.lat,
#                                    Longitude=station.lon,
#                                    value=get.new.data(opt$day,opt$hour)))

# Assimilate some of the validation obs
assimilated<-c(2,3,4,8,11,14,16,18,20,21)
asm<-EnKF.field.assimilate(e,e,list(Latitude=stations$latitude[assimilated],
                                        Longitude=stations$longitude[assimilated],
                                        value=mslp$X1903020718[assimilated]))

# Make the plot
pdf(file=sprintf("%s/validation.pdf",Imagedir),
    width=8,height=11,family='Helvetica',
    paper='special',pointsize=10,bg='white')

    pushViewport(viewport(width=1.0,height=1.0,x=0.0,y=0.0,
                          just=c("left","bottom"),name="Page",clip='off'))
       pushViewport(plotViewport(margins=c(0,0,3,10)))
          pushViewport(dataViewport(c(97500,102700),c(1,27),clip='off'))
             grid.xaxis(main=F,at=seq(98000,102500,500))
             grid.text('MSLP',y=unit(-3,'lines'))
             grid.yaxis(at=seq(1,length(stations$latitude)),
                        label=stations$name,
                        main=F)

 
            # Add the 20CR Pressures
            gp<-gpar(col='blue',fill='blue')
            for(vn in seq_along(members)) {
               ens.m<-GSDF.select.from.1d(e,'ensemble',vn)
               at.stations<-GSDF.interpolate.ll(ens.m,
                                                stations$latitude,
                                                stations$longitude)
               grid.points(x=unit(at.stations,'native'),
                           y=unit(jitter(seq(1,length(at.stations)),
                                         amount=0.1)+0.15,'native'),
                           pch=21,gp=gp,size=unit(0.003,'snpc'))
            }
               
            # Add the post-assimilation Pressures
            gp<-gpar(col='red',fill='red')
            for(vn in seq_along(members)) {
               ens.m<-GSDF.select.from.1d(asm,'ensemble',vn)
               at.stations<-GSDF.interpolate.ll(ens.m,
                                                stations$latitude,
                                                stations$longitude)
               grid.points(x=unit(at.stations,'native'),
                           y=unit(jitter(seq(1,length(at.stations)),
                                         amount=0.1)-0.15,'native'),
                           pch=21,gp=gp,size=unit(0.003,'snpc'))
               
            }

           # Plot the observed pressures
            gp<-gpar(col='black',fill='black',lwd=2)
            for(s in seq(1,length(mslp$X1903020718))) {
              grid.lines(x=unit(mslp$X1903020718[s],'native'),
                        y=unit(c(s-0.3,s+0.3),'native'),
                        gp=gp)
            }
         popViewport()
       popViewport()
    popViewport()

dev.off()
