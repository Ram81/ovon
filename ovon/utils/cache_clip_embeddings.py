import argparse
import glob
import os
from typing import List

import clip
import numpy as np
import torch
from tqdm import tqdm
from transformers import BertConfig, BertModel, BertTokenizer

from ovon.utils.utils import load_dataset, save_pickle

PROMPT = "{category}"


class BertEmbedder:
    def __init__(self, model: str = "bert-base-uncased") -> None:
        self.model = BertModel.from_pretrained(model)
        self.tokenizer = BertTokenizer.from_pretrained(model)
        self.model.to("cuda")

    def embed(self, query: List[str]):
        encoded_dict = self.tokenizer.encode_plus(
            query,                      # Sentence to encode.
            add_special_tokens = True,  # Add '[CLS]' and '[SEP]'
            max_length = 77,           # Pad & truncate all sentences.
            padding='max_length',
            return_attention_mask = True,   # Construct attn. masks.
            return_tensors = 'pt',     # Return pytorch tensors.
        ).to("cuda")

        with torch.no_grad():
            outputs = self.model(**encoded_dict)
            embeddings = outputs[0].mean(dim=1).squeeze(0)
        return embeddings

    def batch_embed(self, batch_queries: List[str]):
        embeddings = []
        for query in batch_queries:
            embeddings.append(self.embed(query))
        return embeddings


def tokenize_and_batch(clip, goal_categories):
    tokens = []
    for category in goal_categories:
        prompt = PROMPT.format(category=category)
        tokens.append(clip.tokenize(prompt, context_length=77).numpy())
    return torch.tensor(np.array(tokens)).cuda()


def get_bert():
    bert = BertEmbedder()
    return bert


def save_to_disk(text_embedding, goal_categories, output_path):
    output = {}
    for goal_category, embedding in zip(goal_categories, text_embedding):
        output[goal_category] = embedding.detach().cpu().numpy()
    save_pickle(output, output_path)


def cache_embeddings(goal_categories, output_path, clip_model="RN50"):
    if clip_model == "BERT":
        model = get_bert()
        text_embedding = model.batch_embed(goal_categories)
    else:
        model, _ = clip.load(clip_model)
        batch = tokenize_and_batch(clip, goal_categories)

        with torch.no_grad():
            print(batch.shape)
            text_embedding = model.encode_text(batch.flatten(0, 1)).float()
    print("Goals: {}, Embeddings: {}, Shape: {}".format(len(goal_categories), len(text_embedding), text_embedding[0].shape))
    save_to_disk(text_embedding, goal_categories, output_path)


def load_categories_from_dataset(path):
    files = glob.glob(os.path.join(path, "*json.gz"))

    categories = []
    for f in tqdm(files):
        dataset = load_dataset(f)
        for goal_key in dataset["goals_by_category"].keys():
            categories.append(goal_key.split("_")[1])
    return list(set(categories))


def clean_instruction(instruction):
    instruction = instruction.replace("instruction:", "")
    instruction = instruction.replace("find the", "")
    instruction = instruction.replace("go to", "").replace("\n", " ")
    # instruction = " ".join(instruction.split(" ")[:50])
    return instruction.strip()


def cache_ovon_goals(dataset_path, output_path):
    goal_categories = load_categories_from_dataset(dataset_path)
    val_seen_categories = load_categories_from_dataset(
        dataset_path.replace("train", "val_seen")
    )
    val_unseen_easy_categories = load_categories_from_dataset(
        dataset_path.replace("train", "val_unseen_easy")
    )
    val_unseen_hard_categories = load_categories_from_dataset(
        dataset_path.replace("train", "val_unseen_hard")
    )
    goal_categories.extend(val_seen_categories)
    goal_categories.extend(val_unseen_easy_categories)
    goal_categories.extend(val_unseen_hard_categories)

    print("Total goal categories: {}".format(len(goal_categories)))
    print(
        "Train categories: {}, Val seen categories: {}, Val unseen easy categories: {}, Val unseen hard categories: {}".format(
            len(goal_categories),
            len(val_seen_categories),
            len(val_unseen_easy_categories),
            len(val_unseen_hard_categories),
        )
    )
    cache_embeddings(goal_categories, output_path)


def cache_language_goals(dataset_path, output_path, model):
    files = glob.glob(os.path.join(dataset_path, "*json.gz"))
    instructions = set()
    for file in tqdm(files):
        dataset = load_dataset(file)
        for episode in dataset["episodes"]:
            cleaned_instruction = clean_instruction(episode["instructions"][0].lower())
            instructions.add(cleaned_instruction)

    print("Total instructions: {}".format(len(instructions)))
    max_instruction_len = 0
    for instruction in instructions:
        max_instruction_len = max(max_instruction_len, len(instruction.split(" ")))
    print("Max instruction length: {}".format(max_instruction_len))

    cache_embeddings(list(instructions), output_path, model)


def main(dataset_path, output_path, dataset, model):
    if dataset == "ovon":
        cache_ovon_goals(dataset_path, output_path)
    elif dataset == "lnav":
        cache_language_goals(dataset_path, output_path, model)
    else:
        raise NotImplementedError


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--dataset-path",
        type=str,
        required=True,
        help="file path of OVON dataset",
    )
    parser.add_argument(
        "--output-path",
        type=str,
        required=True,
        help="output path of clip features",
    )
    parser.add_argument(
        "--dataset",
        type=str,
        required=True,
        help="ovon",
    )
    parser.add_argument(
        "--model",
        type=str,
        required=True,
        help="RN50",
    )
    args = parser.parse_args()

    main(args.dataset_path, args.output_path, args.dataset, args.model)
