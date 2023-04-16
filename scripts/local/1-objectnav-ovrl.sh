#!/bin/bash

export GLOG_minloglevel=2
export HABITAT_SIM_LOG=quiet
export MAGNUM_LOG=quiet

MAIN_ADDR=$(scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -n 1)
export MAIN_ADDR

TENSORBOARD_DIR="junk/tb/objectnav/ver/ovrl_resnet50/hm3d_6cat/seed_1"
CHECKPOINT_DIR="junk/data/new_checkpoints/objectnav/ver/ovrl_resnet50/hm3d_6cat/seed_1"
DATA_PATH="data/datasets/objectnav/hm3d/v1"

python -um ovon.run \
  --run-type train \
  --exp-config config/experiments/ddppo_objectnav_hm3d.yaml \
  habitat_baselines.num_environments=32 \
  habitat_baselines.trainer_name="ver" \
  habitat_baselines.load_resume_state_config=false \
  habitat_baselines.rl.policy.name=OVRLPolicy \
  habitat_baselines.rl.ddppo.train_encoder=true \
  habitat_baselines.tensorboard_dir=${TENSORBOARD_DIR} \
  habitat_baselines.checkpoint_folder=${CHECKPOINT_DIR} \
  habitat.dataset.data_path=${DATA_PATH}/train/train.json.gz \
  +habitat/task/lab_sensors@habitat.task.lab_sensors.clip_objectgoal_sensor=clip_objectgoal_sensor \
  ~habitat.task.lab_sensors.objectgoal_sensor \
  habitat.task.lab_sensors.clip_objectgoal_sensor.cache=data/clip_embeddings/mp3d_categories.pkl \

