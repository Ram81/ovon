#!/bin/bash
export GLOG_minloglevel=2
export HABITAT_SIM_LOG=quiet
export MAGNUM_LOG=quiet

export PYTHONPATH=/srv/flash1/rramrakhya6/spring_2023/habitat-sim/src_python/

TENSORBOARD_DIR="tb/objectnav/ver/resnetclip_rgb_text/hm3d_22cat/seed_2_fusion"
CHECKPOINT_DIR="data/new_checkpoints/objectnav/ver/resnetclip_rgb_text/hm3d_22cat/seed_2_fusion"
DATA_PATH="data/datasets/objectnav/hm3d_semantic_v0.2/v1"

python -um ovon.run \
  --run-type train \
  --exp-config config/experiments/ddppo_objectnav_hm3d.yaml \
  habitat_baselines.trainer_name="ver" \
  habitat_baselines.rl.ppo.hidden_size=1024 \
  habitat_baselines.rl.policy.name=PointNavResNetCLIPPolicy \
  habitat_baselines.rl.ddppo.train_encoder=False \
  habitat_baselines.rl.ddppo.backbone=resnet50_clip_avgpool \
  habitat_baselines.tensorboard_dir=${TENSORBOARD_DIR} \
  habitat_baselines.checkpoint_folder=${CHECKPOINT_DIR} \
  habitat.dataset.data_path=${DATA_PATH}/train/train.json.gz \
  +habitat/task/lab_sensors@habitat.task.lab_sensors.clip_objectgoal_sensor=clip_objectgoal_sensor \
  ~habitat.task.lab_sensors.objectgoal_sensor \
  habitat.task.lab_sensors.clip_objectgoal_sensor.cache=data/clip_embeddings/mp3d_categories_no_norm.pkl
