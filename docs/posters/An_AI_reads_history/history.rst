An AI reads history
===================

.. figure:: ../../../An_AI_reads_history/AI_reads_history.png
   :width: 95%
   :align: center
   :figwidth: 95%


I was struck, years ago, by `Sixty men from Ur <https://www.dailykos.com/stories/2007/03/09/310038/-Science-Friday-Sixty-Men-from-Ur>`_ - which points out that human recorded history is short, when measured in human lifetimes. I wanted to extend the point - by using not lifetimes in the abstract, but actual lifetimes of real people. Until recently, however, this would be a pain to do, because it's difficult to find a set of famous people who's lifetimes match up appropriately. But now we have `ChatGPT <https://chat.openai.com>`_, and we can just ask it for what we want.

So I chose the first two people: `Taylor Swift <https://en.wikipedia.org/wiki/Taylor_Swift>`_, possibly the most famous person currently alive, and `Queen Elizabeth II <https://en.wikipedia.org/wiki/Elizabeth_II>`_, a recent famous person who's been alive for a long time. And then I asked ChatGPT for the most famous person who had died just after Elizabeth II was born, and it nominated `Thomas Hardy <https://en.wikipedia.org/wiki/Thomas_Hardy>`_. So I addded him to the list and proceeded by induction. I checked that everyone nominated was famous enough to have a Wikipedia page, and took birth and death dates from that page. Just for kicks, I also asked ChatGPT to draw a `picture of everyone it nominated <pictures.html>`_.

I bent the rules a bit:

* In the recent period, when there are lots of candidates to choose from, I often rejected the first sugestion if they were a monarch. I didn't want just a list of 'names of kings'.

* In the early period, where it is hard to find candidates, I allowed candidates whos date of birth was not known (to Wikipedia) - deciding that monarchs all ascend the throne at age 20 unless there is information to the contrary. 

* Sometimes ChatGPT offered no good candidates. In this case I left a gap and restarted with someone earlier.

* I forced `Iry-Hor <https://en.wikipedia.org/wiki/Iry-Hor>`_ to be the earliest person, because he's the obvious end point: possibly the first person who's name we know. I made up his dates (choosing plausible values within the Wikipedia range).

* I forced `Ea-nāṣir <https://en.wikipedia.org/wiki/Complaint_tablet_to_Ea-n%C4%81%E1%B9%A3ir>`_ into the list (no suggestions from ChatGPT for his period, and he's not a king). I made up his dates (choosing plausible values within the Wikipedia range).

* A couple of people were suggested by `GitHub Copilot <https://github.com/features/copilot>`_, not ChatGPT. I edited the list of selected people (see below) as a csv file, using a Copilot-enabled editor. And Copilot rapidly worked out the format of that file, so I generally only had to type the first few characters of each new person's name, and Copilot would suggest the rest (always with the right dates and URL, in the correct format). Copilot would also suggest the next line (next person in the series), but it never quite worked out what algorithm I was using to choose the next person, so the suggestions were generally tempting, but had the wrong death date. On a couple of occasions it did suggest the perfect person, however, and in those cases I just hit ESC and took the suggestion.

List of selected people
-----------------------

.. literalinclude:: ../../../An_AI_reads_history/people.csv

Code to make the poster
-----------------------

Written with much assistance from the awesome `GitHub Copilot <https://github.com/features/copilot>`_. (This whole project was a test of the value of AI assistance, and I'm completely sold on it.)

.. literalinclude:: ../../../An_AI_reads_history/plot.py



