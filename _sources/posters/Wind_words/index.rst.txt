Storm Darragh drawn with the Shipping Forecast
==============================================

.. figure:: ../../../wind_words/wind_words.webp
   :width: 95%
   :align: center
   :figwidth: 95%


I'm no mariner, but - like so many people - I love the `Shipping Forecast <https://en.wikipedia.org/wiki/Shipping_Forecast>`_ (`read <https://www.metoffice.gov.uk/weather/specialist-forecasts/coast-and-sea/print/shipping-forecast>`_ or `listen to <https://www.bbc.co.uk/programmes/b006qfvv>`_ today's). It's justly famous for rhythm, cadence, and the poetry of its names, but it's really a picture of the weather around the British Isles. Can we make that picture - a weather map - from the words of the Shipping Forecast? It's a timely project, as the centenary of the first broadcast of the shipping forecast is Jan 1st 2025 (next week, as I write this) - also, I need a picture to decorate my new laptop.

Setup
-----

I'm going to make the map using python and `matplotlib <https://matplotlib.org/>`_. Step one is to set up a conda environment with the necessary packages:

.. literalinclude:: ../../../wind_words/ww.yml

Getting the forecast
--------------------

Generally, the worse the weather the better it looks when presented as a map - and the more dramatic the words of the forecast. So I chose :doc:`the forecast <forecast_raw>` for the recent `Storm Darragh <https://en.wikipedia.org/wiki/Storm_Darragh>`_ (7th December 2024) as my source. I :doc:`split it into short lines <forecast>` - partly to emphasise the phrasing, and partly because long lines won't fit on the plot. 

We also need a reconstruction of the weather at the time of the forecast. I used the `ERA5 reanalysis <https://www.ecmwf.int/en/forecasts/dataset/ecmwf-reanalysis-v5>`_ for this. I retrieved near-surface winds (and a land mask) from the `Copernicus Climate Data Store (CDS) <https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=download>`_.

.. literalinclude:: ../../../wind_words/get_fields_from_ERA5.py

The CDS is awesome - but its current version does terrible things to the netCDF files it makes. So we need to hack them a bit to make them useable:

.. literalinclude:: ../../../wind_words/clean_ERA5.sh

Making the image
-----------------

So we have the words of the shipping forecast, and the wind fields for the time of the forecast. We now want to draw a picture of the wind fields, using the words. The basic process is:

* Identify a set of points (lat,lon) evenly spaced over the region of the plot. (I used the `scipy PoissonDisk function <https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.qmc.PoissonDisk.html>`_)
* For each point, use the wind fields to advect a line along the path of the wind.
* For each such line, pick a phrase from the forecast, and render it along the advected path. (I used `matplotlib's TextPath <https://matplotlib.org/stable/gallery/text_labels_and_annotations/demo_text_path.html>`_)

We need to make sure that the phrases are legible, and that they don't overlap. To do this I chose way too many starting points, and then used each in turn - discarding any that would overlap with existing phrases. 

.. toctree::
   :maxdepth: 1

   Main Script <main_script>
   Define_geometry <cube>
   Propagate Streamlines <streamlines>
   Draw Text <draw_text>
   Track Overlaps <collisions>

And then of course, there's the difficult bit - what colours should we use to draw the phrases? 
I took an idea from the excellent `MetBrewer <https://github.com/BlakeRMills/MetBrewer>`_ and pinched a set of blue shades from `Katsushika Hokusai <https://www.metmuseum.org/art/collection/search/56240>`_. To which I added red as a highlight colour.


This document is licensed under `CC BY 4.0 <https://creativecommons.org/licenses/by/4.0/?ref=chooser-v1>`_. All code included is licensed under the terms of the `BSD licence <https://opensource.org/license/bsd-3-clause>`_.

Note that the forecast text is `Crown Copyright <https://www.metoffice.gov.uk/policies/legal#licences>`_, and the ERA5 data used is licensed by `Copernicus <https://www.copernicus.eu/en/access-data/copyright-and-licences>`_
