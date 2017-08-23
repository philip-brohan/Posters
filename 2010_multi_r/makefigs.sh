# Make the multi-reanalysis figure

./20CR2c_make.streamlines.R  &
./CERA20C_make.streamlines.R &
./ERA5_make.streamlines.R    &
./ERAI_make.streamlines.R    &
wait

./20CR2c.render.R  &
./CERA20C.render.R &
./ERA5.render.R    &
./ERAI.render.R    &
wait

./merge.R

convert $SCRATCH/Posters/2010_multi_r/merged.png $SCRATCH/Posters/2010_multi_r/merged.pdf
