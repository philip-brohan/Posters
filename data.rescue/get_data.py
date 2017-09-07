# Get the reanalysis data needed by the data rescue poster

import twcr
import datetime

def retrieve_for_year(year,version,source=None):
   twcr.fetch_data_for_year('observations',year,
                            version,source=source)
   twcr.fetch_data_for_year('prmsl',year,version,
                            type='mean',source=source)
   twcr.fetch_data_for_year('prmsl',year,version,
                            type='spread',source=source)
   twcr.fetch_data_for_year('prmsl',year,version,
                            type='first.guess.mean',source=source)
   twcr.fetch_data_for_year('prmsl',year,version,
                            type='first.guess.spread',source=source)
   twcr.fetch_data_for_year('prmsl',year,version,
                            type='ensemble',source=source)
   twcr.fetch_data_for_year('air.2m',year,version,
                            type='ensemble',source=source)
   twcr.fetch_data_for_year('prate',year,version,
                            type='ensemble',source=source)


base_date=datetime.datetime.strptime("1872-12-02:12:00:00",
                                     "%Y-%m-%d:%H:%M:%S")
date_step=datetime.timedelta(days=7*365+130,hours=6)
count=0
for i in range(1,5):
    for j in range(1,6):
        t_date=base_date+date_step*count
        print(t_date.year)
        #retrieve_for_year(t_date.year,'3.2.1')
        #retrieve_for_year(t_date.year,'3.5.1')
        count=count+1
