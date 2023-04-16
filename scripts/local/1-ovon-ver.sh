#!/bin/bash

export GLOG_minloglevel=2
export HABITAT_SIM_LOG=quiet
export MAGNUM_LOG=quiet

MAIN_ADDR=$(scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -n 1)
export MAIN_ADDR

TENSORBOARD_DIR="junk/tb/ovon/ddppo/resnetclip_rgb_text/overfitting/"
CHECKPOINT_DIR="junk/data/new_checkpoints/ovon/ddppo/resnetclip_rgb_text/overfitting/"
DATA_PATH="data/datasets/ovon/hm3d/v1"

export CUDA_LAUNCH_BLOCKING=1
python -um ovon.run \
  --run-type train \
  --exp-config config/experiments/ddppo_objectnav_hm3d.yaml \
  habitat_baselines.num_environments=16 \
  habitat_baselines.trainer_name="ddppo" \
  habitat_baselines.rl.policy.name=PointNavResNetCLIPPolicy \
  habitat_baselines.rl.ddppo.train_encoder=False \
  habitat_baselines.rl.ddppo.backbone=resnet50_clip_avgpool \
  habitat_baselines.tensorboard_dir=${TENSORBOARD_DIR} \
  habitat_baselines.checkpoint_folder=${CHECKPOINT_DIR} \
  habitat.dataset.data_path=${DATA_PATH}/train/train.json.gz \
  +habitat/task/lab_sensors@habitat.task.lab_sensors.clip_objectgoal_sensor=clip_objectgoal_sensor \
  ~habitat.task.lab_sensors.objectgoal_sensor \
  habitat.task.lab_sensors.clip_objectgoal_sensor.cache=data/clip_embeddings/ovon_hm3d_cache.pkl \
  habitat_baselines.rl.policy.add_clip_linear_projection=True \
  habitat.task.measurements.success.success_distance=0.25 \
  habitat.dataset.type="OVON-v1" \
  habitat.task.measurements.distance_to_goal.type=OVONDistanceToGoal \
  habitat.simulator.type="OVONSim-v0"

