#!/bin/bash

content_dir="data/datasets/ovon/hm3d/v1/train/content"
gz_files=`ls ${content_dir}/*json.gz`
for i in ${gz_files[@]}
do
  base=`basename $i`
  base=${base%.*}  # remove .gz
  base=${base%.*}  # remove .json
  echo $base
  sbatch --job-name=${base} \
    --output=slurm_logs/${base}.out \
    --error=slurm_logs/${base}.err \
    --export=ALL,SCENE_PATH=$i \
    scripts/dataset/clean_scene_dataset.sh
done

