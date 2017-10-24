# Scripts to make the overlay image with the key text.

# Make /Users/philip/LocalData/Posters/EnKF_Fort_William/Key.pdf
#  from the pages file.

# Export to Key.png at 1500 dpi.

# Make background transparent
convert /Users/philip/LocalData/Posters/EnKF_Fort_William/Key.png -fuzz 10% -transparent white /Users/philip/LocalData/Posters/EnKF_Fort_William/Key.transparent.png

# Rescale to correct size
convert /Users/philip/LocalData/Posters/EnKF_Fort_William/Key.transparent.png -geometry 4965x7020! /Users/philip/LocalData/Posters/EnKF_Fort_William/Key.transparent.scaled.png

