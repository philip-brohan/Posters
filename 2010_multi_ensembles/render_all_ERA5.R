#!/usr/bin/env Rscript

# Render each ERA5 ensemble member as a seperate SPICE job

for(member in seq(0,9)) {
  sink('ERA5.member.slm')
  cat('#!/bin/ksh -l\n')
  cat('#SBATCH --output=/scratch/hadpb/slurm_output/ERA5.member-%j.out\n')
  cat('#SBATCH --qos=normal\n')
  cat('#SBATCH --mem=16G\n')
  cat('#SBATCH --ntasks=1\n')
  cat('#SBATCH --ntasks-per-core=1\n')
  cat('#SBATCH --time=20\n')
  cat(sprintf("ERA5.render.R --member=%d",member))
  sink()
  system('sbatch ERA5.member.slm')
  unlink('ERA5.member.slm')
}
