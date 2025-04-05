ML as a superpower for climate modelling
========================================

.. figure:: Comics_style_poster.jpg
   :width: 95%
   :align: center
   :figwidth: 95%


I did my training in statistics quite a few years ago, but I still remember the first time I encountered the `Generalized Linear Model (GLM) <https://en.wikipedia.org/wiki/Generalized_linear_model>`_. It seemed awesome - a way to use the power of linear regression to model more or less anything. I remember thinking "this is amazing, I can use this to model *anything* - all I need is enough link functions and parameters". But it turns out it doesn't actually work in practice - except in a few special cases, it's just not possible to fit a GLM to a complex process - and practical science restricts itself, almost entirely, to simple linear models.

So when, about 25 years later, I had my first experience of modern `Machine Learning (ML) <https://en.wikipedia.org/wiki/Machine_learning>`_ (I was playing with `pix2pix <https://phillipi.github.io/pix2pix/>`_), I felt as if I had been handed a superpower. This was a technology that really *could* model more or less anything! And it really worked! And it wasn't even difficult! The limitations I had grown used to in half a lifetime of data-science work were just gone.

The ML revolution has not slowed since then, and, like so many people, I have particularly enjoyed `ChatGPT's new fluency with images <https://openai.com/index/introducing-4o-image-generation/>`_ (new as of March 2025). It's now possible to control generated images much more precisely, to make sets and sequences of images with common content and themes, and to make images containing text (ChatGPT has finally learned to spell). And I realized I could use this ability to make a scientific poster (which of course should describe my ML climate modelling work).

So the theme is "ML as a superpower", which made me think of the old superhero comics, so I made the poster in the style of a comic-book page by `Jack Kirby <https://en.wikipedia.org/wiki/Jack_Kirby>`_. I mocked-up a page layout in PowerPoint, dreamed up a draft script, and then `got ChatGPT to do pretty-much everything else <https://chatgpt.com/share/67f15251-4a48-8013-90f7-4e25e58c2f1d>`_.

Here's the `final PowerPoint file (48Mb) <../../_static/Comics_style_poster.pptx>`_.

A few points of detail
----------------------

* The poster is designed to be printed at A0 size (841mm x 1189mm). GPT will only make images in three aspect ratios: portrait (2x3), landscape (3x2) and square (1x1), and this inflexibility makes laying out the panels a bit tricky. I tried to get GPT to design the layout for me, but I couldn't get it to stick to only using the aspect ratios it could provide art for. And also the layout is dependent on the script. So I ended up pushing shapes around in PPT.

* GPT's images are not as consistent as I'd like. The characters are not visually consistent panel to panel (but it's close enough), and while I specified the text panel colours as 'lime green and black' it's not consistent in what it uses for lime green. I did a little bit of colour adjustment on GPT's images to correct for this.

* A good scientific poster should be visually striking from a distance, communicate the main message effectively and quickly, include some solid and serious scientific detail, and stand alone (i.e. be understandable without anyone around to explain it). I've no idea how to achieve all of these things simultaneously - on this occasion I left the solid and serious detail to external links (QR codes in the poster). I made the QR codes with `Adobe Express <https://new.express.adobe.com/tools/generate-qr-code>`_.



This document is licensed under `CC BY 4.0 <https://creativecommons.org/licenses/by/4.0/?ref=chooser-v1>`_. All code included is licensed under the terms of the `BSD licence <https://opensource.org/license/bsd-3-clause>`_. I'm not sure of the copyright status of the ChatGPT-generated material, but insofar as I have any rights in it, I license it under the same terms as this document.
