
expand_grid<-function(file.name) {
    txt.grid<-read.table(file.name)
    ex.grid<-data.frame(centre.lat=rep(NA,1000000),
                        centre.lon=rep(NA,1000000),
                        min.lat=rep(NA,1000000),
                        min.lon=rep(NA,1000000),
                        max.lat=rep(NA,1000000),
                        max.lon=rep(NA,1000000))
    d.lat<-txt.grid$V5[1]-txt.grid$V5[2]
    idx<-1
    for(lat.i in seq_along(txt.grid$V5)) {
        lat<-txt.grid$V5[lat.i]
        ex.grid$centre.lat[idx:(idx+txt.grid$V2[lat.i]-1)]<-lat
        ex.grid$max.lat[idx:(idx+txt.grid$V2[lat.i]-1)]<-lat+d.lat/2
        ex.grid$min.lat[idx:(idx+txt.grid$V2[lat.i]-1)]<-lat-d.lat/2
        d.lon<-360/txt.grid$V2[lat.i]
        lon.i<-seq(1,txt.grid$V2[lat.i])
        lon<-(lon.i-0.5)*d.lon
        ex.grid$centre.lon[idx:(idx+txt.grid$V2[lat.i]-1)]<-lon
        ex.grid$max.lon[idx:(idx+txt.grid$V2[lat.i]-1)]<-lon+d.lon/2
        ex.grid$min.lon[idx:(idx+txt.grid$V2[lat.i]-1)]<-lon-d.lon/2
        idx<-idx+txt.grid$V2[lat.i]
    }
    w<-which(!is.na(ex.grid$centre.lat))
    ex.grid<-ex.grid[w,]
    return(ex.grid)
}

e40<-expand_grid('ERA40_grid.txt')
saveRDS(e40,'ERA40_grid.Rdata')

eI<-expand_grid('ERAI_grid.txt')
saveRDS(eI,'ERAI_grid.Rdata')

e5<-expand_grid('ERA5_grid.txt')
saveRDS(e5,'ERA5_grid.Rdata')
