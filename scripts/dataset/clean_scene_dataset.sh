#!/bin/bash
#SBATCH --gpus 1
#SBATCH --nodes 1
#SBATCH --cpus-per-task 7
#SBATCH --ntasks-per-node 1
#SBATCH --partition=short,user-overcap
#SBATCH --signal=USR1@100
#SBATCH --requeue
#SBATCH --exclude calculon,alexa,cortana,bmo,c3po,ripl-s1,t1000,hal

export GLOG_minloglevel=2
export HABITAT_SIM_LOG=quiet
export MAGNUM_LOG=quiet

MAIN_ADDR=$(scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -n 1)
export MAIN_ADDR

source /srv/flash1/rramrakhya6/miniconda3/etc/profile.d/conda.sh
conda deactivate
conda activate ovon

echo "\n"
echo $SCENE_PATH
echo $(which python)
echo "ola"

srun python ovon/dataset/clean_episodes.py --path $SCENE_PATH --output-path data/datasets/ovon/hm3d/v3/train/content