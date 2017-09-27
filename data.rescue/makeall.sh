# Run all the steps necessary to make the data rescue poster

# Plot weather, obs, and glow
./data.rescue.R

# Mark regions to be covered in fog
./calculate.fog.background.R
convert $SCRATCH/Posters/data.rescue/fog.overlay.background.png -blur 0x5 -level 25%,100% $SCRATCH/Posters/data.rescue/fog.overlay.background.blurred.png
./calculate.fog.R
convert $SCRATCH/Posters/data.rescue/fog.overlay.png -blur 0x10 $SCRATCH/Posters/data.rescue/fog.overlay.blurred.png

# Make the blurred version of the main image
convert $SCRATCH/Posters/data.rescue/data.rescue.png -blur 0x20 $SCRATCH/Posters/data.rescue/data.rescue.blurred.png

# Smooth the fog

# Mask the original plot with the fog
# Needs lots of RAM (salloc --mem=32G --time=20 --qos=high)
./apply.fog.R

# Make the key and label
./make_overlays.R

# Apply the overlay to make the final image
# Needs lots of RAM (salloc --mem=32G --time=20 --qos=high)
./apply_overlays.R
