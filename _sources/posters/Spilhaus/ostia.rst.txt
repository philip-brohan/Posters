Ostia data in the Spilhaus projection
=====================================

.. figure:: ../../../Spilhaus/spilhaus_ostia_meto.png
   :target: https://s3-eu-west-1.amazonaws.com/philip.brohan.org.big-files/Posters/Spilhaus/spilhaus_ostia_meto.pdf
   :width: 65%
   :align: center
   :figwidth: 65%

The `Spilhaus projection <https://storymaps.arcgis.com/stories/756bcae18d304a1eac140f19f4d5cb3d>`_ is an ocean-centred map projection which would work nicely for displaying global marine data such as sea-surface temperatures (SST). I try, however, not to use custom projections - as far as possible I just use the `equirectangular projection <https://en.wikipedia.org/wiki/Equirectangular_projection>`_: It's easy to use with the software I already have, and by suitable choice of pole location, central meridan, and scale, it's flexible in its output.

So, can we find an equirectangular approximation to the Spilhaus projection? I picked:

*   pole_longitude=113.0 
*   pole_latitude=32.0 
*   central_rotated_longitude=193.0
*   an extended longitude range of -202 W to 180E

Combining this with selective masking of some bits of ocean shown twice (because of the extended longitude), gave the result above. The plot is of SST from the Met Office operational model (effectively of `OSTIA <http://ghrsst-pp.metoffice.com/ostia/>`_).

* `Full resolution PDF (10Mb, printable) <https://s3-eu-west-1.amazonaws.com/philip.brohan.org.big-files/Posters/Spilhaus/spilhaus_ostia_meto.pdf>`_

Code to make the poster
-----------------------

Script to download the selected data from the operational MASS archive at the Met Office:

.. literalinclude:: ../../../Spilhaus/get_data_for_day.py

Script to download the fixed land mask and orography fields:

.. literalinclude:: ../../../Spilhaus/retrieve_fixed-fields.py

Script to plot the poster:

.. literalinclude:: ../../../Spilhaus/spilhaus_ostia_meto.py



