#!/usr/bin/env Rscript

# Render each CERA ensemble member as a seperate SPICE job

for(member in seq(0,9)) {
  sink('CERA.member.slm')
  cat('#!/bin/ksh -l\n')
  cat('#SBATCH --output=/scratch/hadpb/slurm_output/CERA.member-%j.out\n')
  cat('#SBATCH --qos=normal\n')
  cat('#SBATCH --mem=16G\n')
  cat('#SBATCH --ntasks=1\n')
  cat('#SBATCH --ntasks-per-core=1\n')
  cat('#SBATCH --time=20\n')
  cat(sprintf("CERA20C.render.R --member=%d",member))
  sink()
  system('sbatch CERA.member.slm')
  unlink('CERA.member.slm')
}
