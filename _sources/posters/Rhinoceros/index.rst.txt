A modern Rhinoceros
===================

.. figure:: ../../../Rhinoceros/modern_rhinoceros.webp
   :width: 95%
   :align: center
   :figwidth: 95%


One of my favourite artworks is Albrecht Dürer's Rhinoceros (`image <https://upload.wikimedia.org/wikipedia/commons/b/bc/The_Rhinoceros_%28NGA_1964.8.697%29_enhanced.png>`_, `wikipedia <https://en.wikipedia.org/wiki/D%C3%BCrer%27s_Rhinoceros>`_). It's a woodcut of a rhinoceros, made in 1515, based on a written description and a sketch of a rhinoceros that had been brought to Lisbon from India. Dürer never actually saw the rhinoceros, and his image is an early example of what we'd now call a `hallucination <https://en.wikipedia.org/wiki/Hallucination_(artificial_intelligence)>`_. But Dürer's genius is such that his image is better than the real thing - this is what a Rhinoceros *ought* to look like.

I also enjoyed `Nicholas Rougier's book "Scientific Visualization: Python + Matplotlib" <https://github.com/rougier/scientific-visualization-book>`_ which reminded me that we can do so much more with `matplotlib <https://matplotlib.org/>`_ than just plot graphs. I wanted to expand my repertoire of plotting techniques, so I decided to reimagine Dürer's Rhinoceros as a matplotlib plot.

The plan was to use as many as possible of matplotlib's built-in graph types, and to use each type only once. I didn't quite manage this, but it's close. As a single woodblock, Dürer's original is in one colour - modern technology allows removal of this restriction, but choosing colours is very difficult, so this version is in one colour palette: `viridis <https://cran.r-project.org/web/packages/viridis/vignettes/intro-to-viridis.html>`_ (along with a bit of grey and black).


Code to make the poster
-----------------------

Written with much assistance from the awesome `GitHub Copilot <https://github.com/features/copilot>`_. Copilot's encyclopaedic knowledge of matplotlib, and endless patience answering questions along the lines of "How do I do ... ?" made the project enormously easier.

The main script creates the `figure <https://matplotlib.org/stable/api/figure_api.html>`_, adds some `text <https://matplotlib.org/stable/api/_as_gen/matplotlib.axes.Axes.text.html>`_ to the top, and delegates the rest of the job to a `grid of subplots <https://matplotlib.org/stable/api/_as_gen/matplotlib.gridspec.GridSpec.html>`_.

.. literalinclude:: ../../../Rhinoceros/reimagine.py

Each subplot has its own drawing function:

+-------------------------------------+-------------------------------------------------+-------------------------------------------------+-------------------------------------+
| :doc:`Top Left panel <pTL>`         | :doc:`Top Centre-Left panel <pTCL>`             |  :doc:`Top Centre-Right & Right panel <pTCR_TR>`                                      |
+-------------------------------------+-------------------------------------------------+-------------------------------------------------+-------------------------------------+
| :doc:`2nd Left panel <p2L>`         | :doc:`2nd and 3rd Centre-Left panel <p2CL_3CL>` | :doc:`2nd Centre-Right panel <p2CR>`            |:doc:`2nd Right panel <p2R>`         |
+-------------------------------------+                                                 +-------------------------------------------------+-------------------------------------+
| :doc:`3rd Left panel <p3L>`         |                                                 | :doc:`3rd Centre-Right panel <p3CR>`            |:doc:`3rd & 4th Right panel <p3R_4R>`|
+-------------------------------------+-------------------------------------------------+-------------------------------------------------+                                     +
| :doc:`4th & 5th Left panel <p4L_5L>`| :doc:`4th Centre-Left panel <p4CL>`             | :doc:`4th & 5th Centre-Right panel <p4CR_5CR>`  |                                     |
+                                     +-------------------------------------------------+                                                 +-------------------------------------+
|                                     | :doc:`5th Centre-Left panel <p5CL>`             |                                                 |:doc:`5th Right panel <p5R>`         |
+-------------------------------------+-------------------------------------------------+-------------------------------------------------+-------------------------------------+

Or as a list:

.. toctree::
   :maxdepth: 1

   pTL
   pTCL
   pTCR_TR
   p2L
   p2CL_3CL
   p2CR
   p2R
   p3L
   p3CR
   p3R_4R
   p4L_5L
   p4CL
   p4CR_5CR
   p5CL
   p5R

And a few utility functions and definitions are split off into their own file

.. toctree::
   :maxdepth: 1

   utils

