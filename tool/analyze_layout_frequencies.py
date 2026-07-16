#!/usr/bin/env python3
"""Reproduce the character frequencies used by the Chordtype layout."""

from __future__ import annotations

import argparse
import collections
import csv
import html
import io
import json
import re
import tarfile
import unicodedata
import xml.etree.ElementTree as ET
import zipfile
from collections.abc import Iterable, Iterator
from pathlib import Path


ENGLISH_LETTERS = "abcdefghijklmnopqrstuvwxyz"
RUSSIAN_LETTERS = "абвгдеёжзийклмнопрстуфхцчшщъыьэюя"
DIGITS = "0123456789"
PUNCTUATION = (
    " ",
    ".",
    ",",
    "?",
    "!",
    "-",
    "'",
    '"',
    "/",
    ":",
    ";",
    "(",
    ")",
    "\\",
    "@",
    "#",
    "&",
    "*",
    "+",
    "=",
    "_",
    "<",
    ">",
    "[",
    "]",
    "{",
    "}",
    "`",
    "^",
    "~",
    "|",
    "$",
    "%",
)

TRANSLATION = str.maketrans(
    {
        "’": "'",
        "‘": "'",
        "`": "'",
        "“": '"',
        "”": '"',
        "«": '"',
        "»": '"',
        "–": "-",
        "—": "-",
        "−": "-",
        "…": "...",
        "\u00a0": " ",
    }
)


def normalize(text: str) -> str:
    normalized = unicodedata.normalize("NFKC", html.unescape(text))
    return re.sub(r"\s+", " ", normalized.translate(TRANSLATION)).strip()


def count_messages(messages: Iterable[str], letters: str) -> dict[str, object]:
    supported = set(letters + DIGITS + "".join(PUNCTUATION))
    counts: collections.Counter[str] = collections.Counter()
    uppercase_count = 0
    message_count = 0
    raw_character_count = 0

    for raw_message in messages:
        message = normalize(raw_message)
        if not message:
            continue

        message_count += 1
        raw_character_count += len(message)
        uppercase_count += sum(character in letters.upper() for character in message)
        counts.update(character for character in message.lower() if character in supported)

    supported_count = sum(counts.values())
    percentages = {
        character: 100 * count / supported_count for character, count in counts.items()
    }
    letters_by_frequency = sorted(
        letters,
        key=lambda character: percentages.get(character, 0),
        reverse=True,
    )

    return {
        "messages": message_count,
        "raw_characters": raw_character_count,
        "supported_characters": supported_count,
        "uppercase_actions_percent": round(100 * uppercase_count / supported_count, 4),
        "message_boundary_actions_percent": round(
            100 * message_count / (supported_count + message_count), 4
        ),
        "letters": [
            [character, round(percentages.get(character, 0), 4)]
            for character in letters_by_frequency
        ],
        "digits_total_percent": round(
            sum(percentages.get(character, 0) for character in DIGITS), 4
        ),
        "digits": [
            [character, round(percentages.get(character, 0), 4)]
            for character in DIGITS
        ],
        "punctuation": [
            [character, round(percentages.get(character, 0), 4)]
            for character in PUNCTUATION
        ],
    }


def nus_sms_messages(archive_path: Path) -> Iterator[str]:
    with zipfile.ZipFile(archive_path) as archive:
        with archive.open("smsCorpus_en_2015.03.09_all.xml") as stream:
            for _, element in ET.iterparse(stream, events=("end",)):
                if element.tag != "message":
                    continue
                text = element.findtext("text")
                if text:
                    yield text
                element.clear()


def toloka_messages(archive_path: Path) -> Iterator[str]:
    with zipfile.ZipFile(archive_path) as archive:
        with archive.open("TlkPersonaChatRus/dialogues.tsv") as raw_stream:
            stream = io.TextIOWrapper(raw_stream, encoding="utf-8", newline="")
            reader = csv.DictReader(stream, delimiter="\t")
            for row in reader:
                for match in re.finditer(
                    r"<span class=participant_[12]>(.*?)</span>",
                    row["dialogue"],
                    flags=re.DOTALL,
                ):
                    message = re.sub(r"<br\s*/?>", " ", match.group(1))
                    message = re.sub(r"^Пользователь\s+[12]:\s*", "", message)
                    if message.strip():
                        yield message


def personachat_messages(archive_path: Path) -> Iterator[str]:
    with tarfile.open(archive_path, mode="r:gz") as archive:
        for split in ("train", "valid", "test"):
            member = archive.extractfile(f"personachat/{split}_self_original.txt")
            if member is None:
                raise FileNotFoundError(f"Persona-Chat split not found: {split}")

            for raw_line in member:
                fields = raw_line.decode("utf-8").rstrip("\n").split("\t")
                if len(fields) < 2:
                    continue
                first = re.sub(r"^\d+\s+", "", fields[0])
                second = fields[1]
                if first and not first.startswith("your persona:"):
                    yield first
                if second:
                    yield second


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--nus-sms",
        required=True,
        type=Path,
        help="NUS English XML ZIP archive",
    )
    parser.add_argument(
        "--toloka",
        required=True,
        type=Path,
        help="Toloka Persona Chat Rus ZIP archive",
    )
    parser.add_argument(
        "--personachat",
        type=Path,
        help="optional original Persona-Chat TGZ used as an English sanity check",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    results = {
        "en_nus_sms": count_messages(
            nus_sms_messages(args.nus_sms), ENGLISH_LETTERS
        ),
        "ru_toloka": count_messages(toloka_messages(args.toloka), RUSSIAN_LETTERS),
    }
    if args.personachat is not None:
        results["en_personachat_check"] = count_messages(
            personachat_messages(args.personachat), ENGLISH_LETTERS
        )

    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
