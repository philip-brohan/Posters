library(lubridate)

 base.date<-lubridate::ymd_hms("1862-01-22:06:00:00")
 count<-0
 for(j in seq(1,5)) {
    for(i in seq(1,4)) {
       date<-base.date+years(8*count)+hours(400*count)
       system(sprintf("/Users/philip/Projects/weather.case.studies/get_data_from_NERSC/20CR_fetch_year.R --year=%d --version='3.5.1' --ensemble --observations",lubridate::year(date)))
       count<-count+1
   }
}
