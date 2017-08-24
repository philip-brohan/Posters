#!/usr/bin/env Rscript

# Render each 20CR2c ensemble member as a seperate SPICE job

for(member in seq(1,56)) {
  sink('20CR2c.member.slm')
  cat('#!/bin/ksh -l\n')
  cat('#SBATCH --output=/scratch/hadpb/slurm_output/20CR2c.member-%j.out\n')
  cat('#SBATCH --qos=normal\n')
  cat('#SBATCH --mem=16G\n')
  cat('#SBATCH --ntasks=1\n')
  cat('#SBATCH --ntasks-per-core=1\n')
  cat('#SBATCH --time=20\n')
  cat(sprintf("20CR2c.render.R --member=%d",member))
  sink()
  system('sbatch 20CR2c.member.slm')
  unlink('20CR2c.member.slm')
}
