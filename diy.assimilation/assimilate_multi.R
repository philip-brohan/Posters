
# observation is a list with lat, lon, value
# constraint is a GSDF with lat, lon and ensemble dimensions
#  - the same variable as the observation
# target is a GSDF with lat lon and ensemble dimensions
EnKF.field.assimilate<-function(target,constraint,observation) {
  # Make the constraint data frame - ensemble values at observed lcvations
  dim.ens<-GSDF.find.dimension(constraint,'ensemble')
  no.ens<-length(constraint$dimensions[[dim.ens]]$values)
  constraint.frame<-data.frame(array(dim=c(no.ens,
                                           length(observation$Latitude))))
  names(constraint.frame)<-sprintf("x%d",
                                    seq(1,length(observation$Latitude)))
  for(m in seq(1,no.ens)) {
    ens.m<-GSDF.select.from.1d(constraint,'ensemble',m)
    member.vector<-GSDF.interpolate.ll(ens.m,
                                      observation$Latitude,
                                      observation$Longitude)
    constraint.frame[m,]<-member.vector
  }
  # Make the observation data frame
  observation.frame<-data.frame(array(data=observation$value,
                                      dim=c(1,
                                      length(observation$Latitude))))
  names(observation.frame)<-names(constraint.frame)
  
 # do the assimilation at each grid cell in target
  result<-target
  dim.lat<-GSDF.find.dimension(target,'lat')
  if(dim.lat !=1 && dim.lat !=2) stop('Unsupported target structure')
  dim.lon<-GSDF.find.dimension(target,'lon')
  if(dim.lon !=1 && dim.lon !=2) stop('Unsupported target structure')
  for(i in seq(1,length(constraint$dimensions[[1]]$values))) {
    for(j in seq(1,length(constraint$dimensions[[2]]$values))) {
       target.frame<-data.frame(y=array(data=target$data[i,j,,1],
                                        dim=c(no.ens,1)))
       result$data[i,j,,1]<-EnKF.assimilate(target.frame,
                                            constraint.frame,
                                            observation.frame)
     }
  }
  return(result)
}
 
# observation is a data.frame of values (1 for each station)
# constraint is a data.frame with values at target location in first column (y)
#  and values at each station location in other columns - 1 row for each
#  ensemble member.
# target is a vector of first guesses - to be constrained by linear
#   model on constraint.
# result is target post-assimilation
EnKF.assimilate<-function(target,constraint,observation) {
  m<-lm(cbind(target,constraint))
  result<-fitted(m,observation)
  return(result)
}
