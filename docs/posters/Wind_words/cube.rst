Define geometry
===============

My laptop measures 31x21 cm so the picture must be this size. So the associated weather map could be 31x21 degrees (lat-lon), but the geographic projection is substantially distorted at the latitude of the UK (~55N) so I divide the longitude range by Cos(55) - about 0.6 - to adjust for this.

We'll need several grids on this geometry, with various different resolutions. I'm using `Iris <https://scitools-iris.readthedocs.io/en/stable/>`_ to handle the grids.

.. literalinclude:: ../../../wind_words/cube.py


