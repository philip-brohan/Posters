Propagate streamlines
=====================

If we have a set of points (x,y), and a field of wind vectors (iris cubes u,v) we can propagate streamlines by integrating the wind field. This is a simple process - we just move each point along the wind vector iteratively (move by epsilon*wind_speed at each step and repeat for iterations steps).

.. literalinclude:: ../../../wind_words/streamlines.py


