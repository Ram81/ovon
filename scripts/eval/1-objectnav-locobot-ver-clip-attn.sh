#!/bin/bash
#SBATCH --job-name=ovon
#SBATCH --output=slurm_logs/eval/ovon-ver-%j.out
#SBATCH --error=slurm_logs/eval/ovon-ver-%j.err
#SBATCH --gpus 1
#SBATCH --nodes 1
#SBATCH --cpus-per-task 10
#SBATCH --ntasks-per-node 1
#SBATCH --constraint=a40
#SBATCH --partition=short
#SBATCH --exclude=cheetah,ig-88
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

TENSORBOARD_DIR="tb/objectnav/ver/hm3d_6cat/resnetclip_rgb_text_attnpool/seed_1/evals/"
EVAL_CHECKPOINT_DIR="data/new_checkpoints/objectnav/ver/hm3d_6cat/resnetclip_rgb_text_attnpool/seed_1/"
DATA_PATH="data/datasets/objectnav/hm3d/v1"

srun python -um ovon.run \
  --run-type eval \
  --exp-config config/experiments/ddppo_objectnav_hm3d.yaml \
  habitat_baselines.num_environments=20 \
  habitat_baselines.rl.policy.name=PointNavResNetCLIPPolicy \
  habitat_baselines.rl.ddppo.train_encoder=False \
  habitat_baselines.rl.ddppo.backbone=resnet50_clip_attnpool \
  habitat_baselines.tensorboard_dir=${TENSORBOARD_DIR} \
  habitat_baselines.eval_ckpt_path_dir=${EVAL_CHECKPOINT_DIR} \
  habitat_baselines.load_resume_state_config=False \
  habitat_baselines.eval.use_ckpt_config=False \
  habitat_baselines.eval.split=val \
  +habitat/task/lab_sensors@habitat.task.lab_sensors.clip_objectgoal_sensor=clip_objectgoal_sensor \
  ~habitat.task.lab_sensors.objectgoal_sensor \
  habitat.task.lab_sensors.clip_objectgoal_sensor.cache=data/clip_embeddings/mp3d_categories_no_norm.pkl \
  +habitat_baselines.rl.ddppo.late_fusion=False \
  +habitat_baselines.rl.ddppo.add_clip_linear=False \
