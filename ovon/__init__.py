from ovon import config
from ovon.dataset import ovon_dataset
from ovon.measurements import collision_penalty, sum_reward
from ovon.models import clip_policy
from ovon.trainers import dagger, ppo_trainer_no_2d

try:
    import frontier_exploration
except ModuleNotFoundError as e:
    # If the error was due to the frontier_exploration package not being installed, then
    # pass, but warn. Do not pass if it was due to another package being missing.
    if e.name != "frontier_exploration":
        raise e
    else:
        print(
            "Warning: frontier_exploration package not installed. Things may not work. "
            "To install:\n"
            "git clone git@github.com:naokiyokoyama/frontier_explorer.git &&\n"
            "cd frontier_explorer && pip install -e ."
        )
