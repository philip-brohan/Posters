Draw text
=========

Matplotlib's `TextPath <https://matplotlib.org/stable/gallery/text_labels_and_annotations/demo_text_path.html>`_ turns a text string into a `path <https://matplotlib.org/stable/api/path_api.html>`_ - a series of line and curve segments: a representation of the text as graphics components. That path can then be manipulated and scaled, like any other shape - so we can use it to draw text along a streamline.


.. literalinclude:: ../../../wind_words/textPath.py


