# Make the multi-reanalysis figure

./20CR2c_make.streamlines.R  &
./CERA20C_make.streamlines.R &
./ERA5_make.streamlines.R    &
./ERAI_make.streamlines.R    &
wait

./20CR2c.render.R  &
./CERA20C.render.R &
./ERA5_render.R    &
./ERAI.render.R    &
wait

convert -density 300 20CR2c.pdf   20CR2c.png  &
convert -density 300 CERA20C.pdf  CERA20C.png &
convert -density 300 ERA5.pdf     ERA5.png    &
convert -density 300 ERAI.pdf     ERAI.png    &
wait

./merge.R
