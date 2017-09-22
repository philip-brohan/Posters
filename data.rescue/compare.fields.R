# Collect data from 20CR for comparison between two versions

library(GSDF.TWCR)

year<-1894
month<-7
day<-31
hour<-0

get.data<-function(version) {
  result<-list()
  result$ens<-TWCR.get.members.slice.at.hour('prmsl',year,month,day,hour,
                                      version=version)
  result$mean<-GSDF.reduce.1d(result$ens,'ensemble',mean)
  result$spread<-GSDF.reduce.1d(result$ens,'ensemble',sd)
  result$normal<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                                         version='3.4.1',type='normal')
  result$normal<-GSDF.regrid.2d(result$normal,result$mean)
  result$sd<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                                         version='3.4.1',
                                         type='standard.deviation')
  result$sd<-GSDF.regrid.2d(result$sd,result$mean)
  result$fg.mean<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                                         version=version,
                                         type='first.guess.mean')
  result$fg.mean<-GSDF.regrid.2d(result$fg.mean,result$mean)
  result$fg.spread<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                                         version=version,
                                         type='first.guess.spread')
  result$fg.spread<-GSDF.regrid.2d(result$fg.spread,result$mean)
  result$re<-TWCR.relative.entropy(result$normal,result$sd,
                                    result$mean,result$spread)
  result$dmean<-result$mean
  result$dmean$data[]<-result$mean$data-result$fg.mean$data
  result$dspread<-result$spread
  result$dspread$data[]<-result$spread$data-result$fg.spread$data
  result$rmean<-result$mean
  result$rmean$data[]<-result$mean$data/result$fg.mean$data
  result$rspread<-result$spread
  result$rspread$data[]<-result$spread$data/result$fg.spread$data
  return(result)
}
  
