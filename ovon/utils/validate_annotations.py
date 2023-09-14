import glob

from ovon.utils.utils import load_json


def validate(path):
    files = glob.glob(path + "/*annotated.json")

    for file in files:
        scene = file.split("/")[-1].split("_")[0]
        print("Scene: {}".format(scene))

        viewpoints = load_json(file.replace("_annotated", ""))
        annotated_viewpoints = load_json(file)
        failures = 0
        for uuid, annotation in annotated_viewpoints.items():
            if "Failure" in annotation["instructions"]["@1"]:
                failures += 1
        
        uuids = set(list(annotated_viewpoints.keys()))
        vp_uuids = set(list(viewpoints.keys()))
        if len(vp_uuids.difference(uuids)) != 0:
            print("Incomplete anotations for scene {}!".format(scene))

        print("Total failures: {}/{}".format(failures, len(annotated_viewpoints)))


if __name__ == "__main__":
    validate("data/datasets/languagenav/hm3d/v4_stretch_gpt_4/train/content/")
