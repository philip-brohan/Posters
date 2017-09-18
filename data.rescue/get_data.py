# Get the reanalysis data needed by the data rescue poster

import twcr
import datetime

def retrieve_for_year(year,version,source=None):
   twcr.fetch_data_for_year('prmsl',year,version,
                            type='ensemble',source='released')
   twcr.fetch_data_for_year('air.2m',year,version,
                            type='ensemble',source='released')
   twcr.fetch_data_for_year('prate',year,version,
                            type='ensemble',source='released')
   twcr.fetch_data_for_year('prmsl',year,version,
                            type='first.guess.mean',source='scratch')
   twcr.fetch_data_for_year('prmsl',year,version,
                            type='first.guess.spread',source='scratch')
   twcr.fetch_data_for_year('observations',year,
                            version,source=source)


base_date=datetime.datetime.strptime("1872-12-02:12:00:00",
                                     "%Y-%m-%d:%H:%M:%S")
date_step=datetime.timedelta(days=7*365+130,hours=6)
count=0
for i in range(1,5):
    for j in range(1,6):
        t_date=base_date+date_step*count
        print(t_date.year)
        try:
           retrieve_for_year(t_date.year,'3.2.1',source='scratch')
        except:
           print "Failed 3.2.1 retrieval for %d" % t_date.year
        count=count+1
