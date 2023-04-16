#!/bin/bash
#SBATCH --job-name=ovon
#SBATCH --output=slurm_logs/ovon-ver-%j.out
#SBATCH --error=slurm_logs/ovon-ver-%j.err
#SBATCH --gpus 4
#SBATCH --nodes 1
#SBATCH --cpus-per-task 16
#SBATCH --ntasks-per-node 4
#SBATCH --constraint=a40
#SBATCH --partition=short
#SBATCH --exclude=cheetah,cyborg,xaea-12,megazord,megabot,ig-88,dave
#SBATCH --signal=USR1@100

export GLOG_minloglevel=2
export HABITAT_SIM_LOG=quiet
export MAGNUM_LOG=quiet

MAIN_ADDR=$(scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -n 1)
export MAIN_ADDR

source /srv/flash1/rramrakhya6/miniconda3/etc/profile.d/conda.sh
conda deactivate
conda activate ovon

export PYTHONPATH=/srv/flash1/rramrakhya6/spring_2023/habitat-sim/src_python/

TENSORBOARD_DIR="tb/objectnav/ver/hm3d_6cat/resnet_ovrl_linear/seed_2_no_prompt"
CHECKPOINT_DIR="data/new_checkpoints/objectnav/ver/hm3d_6cat/resnet_ovrl_linear/seed_2_no_prompt"
DATA_PATH="data/datasets/objectnav/hm3d/v1"

srun python -um ovon.run \
  --run-type train \
  --exp-config config/experiments/ddppo_objectnav_hm3d.yaml \
  habitat_baselines.trainer_name="ver" \
  habitat_baselines.rl.policy.name=OVRLPolicy \
  habitat_baselines.rl.ddppo.train_encoder=False \
  habitat_baselines.tensorboard_dir=${TENSORBOARD_DIR} \
  habitat_baselines.checkpoint_folder=${CHECKPOINT_DIR} \
  habitat.dataset.data_path=${DATA_PATH}/train/train.json.gz \
  +habitat/task/lab_sensors@habitat.task.lab_sensors.clip_objectgoal_sensor=clip_objectgoal_sensor \
  ~habitat.task.lab_sensors.objectgoal_sensor \
  habitat.task.lab_sensors.clip_objectgoal_sensor.cache=data/clip_embeddings/hm3d_categories.pkl \
  habitat_baselines.rl.policy.add_clip_linear_projection=True
