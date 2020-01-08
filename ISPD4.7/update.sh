#!/bin/bash

./sync.py --bucket=philip.brohan.org.big-files --prefix=Posters/ISPD4.7 --name=ISPD.pdf

convert -geometry 2160x70 ISPD.pdf ISPD.png
