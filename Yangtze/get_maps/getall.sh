#!/bin/bash

# Download all the maps from UCSD
#  They are served as tiles, so we need to dezoomify to get the
#   high-resolution version.

/Users/philip/Applications/dezoomify-rs -l https://library.ucsd.edu/zoomify/bb/16/bb1673549w/ImageProperties.xml original/bb1673549w.jpg
/Users/philip/Applications/dezoomify-rs -l https://library.ucsd.edu/zoomify/bb/21/bb2151374v/ImageProperties.xml original/bb2151374v.jpg
/Users/philip/Applications/dezoomify-rs -l https://library.ucsd.edu/zoomify/bb/35/bb3516575h/ImageProperties.xml original/bb3516575h.jpg
/Users/philip/Applications/dezoomify-rs -l https://library.ucsd.edu/zoomify/bb/48/bb4847640t/ImageProperties.xml original/bb4847640t.jpg
/Users/philip/Applications/dezoomify-rs -l https://library.ucsd.edu/zoomify/bb/57/bb5700892q/ImageProperties.xml original/bb5700892q.jpg
/Users/philip/Applications/dezoomify-rs -l https://library.ucsd.edu/zoomify/bb/60/bb60421919/ImageProperties.xml original/bb60421919.jpg
/Users/philip/Applications/dezoomify-rs -l https://library.ucsd.edu/zoomify/bb/68/bb68954435/ImageProperties.xml original/bb68954435.jpg
/Users/philip/Applications/dezoomify-rs -l https://library.ucsd.edu/zoomify/bb/53/bb53595913/ImageProperties.xml original/bb53595913.jpg
/Users/philip/Applications/dezoomify-rs -l https://library.ucsd.edu/zoomify/bb/35/bb35507031/ImageProperties.xml original/bb35507031.jpg

