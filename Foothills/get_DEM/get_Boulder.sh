#!/bin/bash

# Download the 30m DEM for the Region araound Boulder, Colorado

mkdir -p $SCRATCH/DEM

eio clip -o $SCRATCH/DEM/Boulder.tif --bounds -106 39 -104 41
