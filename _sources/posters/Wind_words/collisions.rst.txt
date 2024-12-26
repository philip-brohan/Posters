Track text overlaps
===================

We need to test that the words don't overlap before plotting them. To do this we create a grid covering the plot area and zero it everywhere. Then, whenever we plot anything, we set this coverage grid to one everywhere we have plotted. We can then test if a new phrase overlaps with an existing one by checking if the coverage grid is non-zero at any point along the path of the new phrase.

.. literalinclude:: ../../../wind_words/collisions.py


