#!/bin/bash

./sync.py --bucket=philip.brohan.org.big-files --prefix=Posters/Spilhaus --name=spilhaus_ostia_meto.pdf

convert -geometry 500x1000 -rotate 90 spilhaus_ostia_meto.pdf spilhaus_ostia_meto.png
