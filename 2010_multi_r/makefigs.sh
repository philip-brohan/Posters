# Make the multi-reanalysis figure

#./20CR2c_make.streamlines.R  &
#./CERA20C_make.streamlines.R &
#./ERA5_make.streamlines.R    &
#./ERAI_make.streamlines.R    &
#wait

./20CR2c.render.R  &
./CERA20C.render.R &
./ERA5.render.R    &
./ERAI.render.R    &
wait

convert -density 300 $SCRATCH/Posters/2010_multi_r/20CR2c.pdf   $SCRATCH/Posters/2010_multi_r/20CR2c.png  &
convert -density 300 $SCRATCH/Posters/2010_multi_r/CERA20C.pdf  $SCRATCH/Posters/2010_multi_r/CERA20C.png &
convert -density 300 $SCRATCH/Posters/2010_multi_r/ERA5.pdf     $SCRATCH/Posters/2010_multi_r/ERA5.png    &
convert -density 300 $SCRATCH/Posters/2010_multi_r/ERAI.pdf     $SCRATCH/Posters/2010_multi_r/ERAI.png    &
wait

./merge.R

convert $SCRATCH/Posters/2010_multi_r/merged.png $SCRATCH/Posters/2010_multi_r/merged.pdf
