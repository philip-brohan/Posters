Observations coverage (ISPD4.7)
===============================

.. figure:: ../../../ISPD4.7/ISPD.png
   :target: https://s3-eu-west-1.amazonaws.com/philip.brohan.org.big-files/Posters/ISPD4.7/ISPD.pdf
   :width: 95%
   :align: center
   :figwidth: 95%

This is a static, poster version of `this video <https://oldweather.github.io/20CRv3-diagnostics/obs_video/obs_video.html>`_. The idea is to show the change in observations coverage with time.

The vertical axis is latitude (90S to 90N at 1 degree resolution), the horizontal axis is time (Jan 1836 to Dec 2015, at 1 month resolution), each vertical line is at a randomly sampled 1-degree of longitude. The points are bright yellow if the corresponding lat:lon:month contains more observations than analysis periods (more than one observation/6 hours), pale yellow if it has some observations but fewer than one per analysis period, and dark grey if it contains no observations.

* `Full resolution PDF (12Mb, printable) <https://s3-eu-west-1.amazonaws.com/philip.brohan.org.big-files/Posters/ISPD4.7/ISPD.pdf>`_

Code to make the poster
-----------------------

Script to download the observations:

.. literalinclude:: ../../../ISPD4.7/get_data.py

Script to extract the observations at each sampled degree of lon:month. This is very slow to run, and should be parallelised, but I don't expect to run it again anytime soon so I haven't bothered.

.. literalinclude:: ../../../ISPD4.7/extract_data_to_plot.py

Script to plot the poster:

.. literalinclude:: ../../../ISPD4.7/plot_poster.py



