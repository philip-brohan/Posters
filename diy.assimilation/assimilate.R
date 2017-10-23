
# observation is a list with lat, lon, value
# constraint is a GSDF with lat, lon and ensemble dimensions
#  - the same variable as the observation
# target is a GSDF with lat lon and ensemble dimensions
EnKF.field.assimilate<-function(target,constraint,observation) {
  # Get the constraint vector at the location of the observation
  dim.ens<-GSDF.find.dimension(constraint,'ensemble')
  no.ens<-length(constraint$dimensions[[dim.ens]]$values)
  constraint.vector<-rep(NA,no.ens)
  for(m in seq(1,no.ens)) {
    ens.m<-GSDF.select.from.1d(constraint,'ensemble',m)
    constraint.vector[m]<-GSDF.interpolate.ll(ens.m,
                                      observation$Latitude,
                                      observation$Longitude)
  }
  # Convenience for hypothetical observations
  if(is.null(observation$value)) observation$value<-constraint.vector[1]
  # do the assimilation at each grid cell in target
  result<-target
  dim.lat<-GSDF.find.dimension(target,'lat')
  if(dim.lat !=1 && dim.lat !=2) stop('Unsupported target structure')
  dim.lon<-GSDF.find.dimension(target,'lon')
  if(dim.lon !=1 && dim.lon !=2) stop('Unsupported target structure')
  for(i in seq(1,length(constraint$dimensions[[1]]$values))) {
    for(j in seq(1,length(constraint$dimensions[[2]]$values))) {
       result$data[i,j,,1]<-EnKF.assimilate(target$data[i,j,,1],
                                          constraint.vector,
                                          observation$value)
     }
  }
  return(result)
}
 
# observation is a value
# constraint is a vector of first guesses - to be constrained by observation
# target is a vector of first guesses - to be constrained by linear
#   model on constraint.
# result is target post-assimilation
EnKF.assimilate<-function(target,constraint,observation) {
  m<-lm(target~constraint)
  result<-m$coefficients[1]+
          m$coefficients[2]*observation+
          m$residuals
  return(result)
}
