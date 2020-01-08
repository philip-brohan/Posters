#!/bin/bash

./sync.py --bucket=philip.brohan.org.big-files --prefix=Posters/Stripes --name=20CR.pdf

convert -geometry 2160x140 20CR.pdf 20CR.png
