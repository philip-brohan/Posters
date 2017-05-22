ex.grid<-data.frame(centre.lat=rep(NA,180*91),
                        centre.lon=rep(NA,180*91),
                        min.lat=rep(NA,180*91),
                        min.lon=rep(NA,180*91),
                        max.lat=rep(NA,180*91),
                        max.lon=rep(NA,180*91))
d.lat<-2
lon<-seq(0,358,2)
d.lon<-2                     
idx<-1
for(lat.i in seq(1,91)) {
  lat<-90-(lat.i-1)*d.lat
  ex.grid$centre.lat[idx:(idx+180-1)]<-lat
  ex.grid$max.lat[idx:(idx+180-1)]<-lat+d.lat/2
  ex.grid$min.lat[idx:(idx+180-1)]<-lat-d.lat/2
  ex.grid$centre.lon[idx:(idx+180-1)]<-lon
  ex.grid$max.lon[idx:(idx+180-1)]<-lon+d.lon/2
  ex.grid$min.lon[idx:(idx+180-1)]<-lon-d.lon/2
  idx<-idx+180
}
w<-which(ex.grid$max.lat>90)
ex.grid$max.lat[w]<-90
w<-which(ex.grid$min.lat< -90)
ex.grid$min.lat[w]<- -90

saveRDS(ex.grid,'TWCR_grid.Rdata')
