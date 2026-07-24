#!/usr/bin/env python3
"""Reproduce the character and bigram frequencies used by the Chordtype layout.

English corpora: DailyDialog (IJCNLP 2017) and Cornell Movie-Dialogs.
Russian corpus: Toloka Persona Chat Rus.
Optional sanity-check: Persona-Chat (ParlAI).

Requires only the Python standard library.  The bundled ``yoficator``
module provides optional Russian ё restoration.
"""

from __future__ import annotations

import argparse
import collections
import csv
import sys
import html
import io
import json
import re
import tarfile
import unicodedata
import zipfile
from collections.abc import Iterable, Iterator
from pathlib import Path

try:
    from yoficator import yoify as _yoify_func

    _HAS_YOIFY = True
except ImportError:  # yoficator is optional; ё restoration is skipped without it
    _HAS_YOIFY = False


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


def count_messages(
    messages: Iterable[str],
    letters: str,
    *,
    yoify: bool = False,
) -> dict[str, object]:
    """Count character and bigram frequencies in *messages*.

    Parameters
    ----------
    messages:
        Iterable of raw message strings.
    letters:
        Alphabet string for the target language.
    yoify:
        If ``True`` and *yoficator* is installed, apply ё restoration to
        every normalised message before counting.
    """

    if yoify and not _HAS_YOIFY:
        print(
            "WARNING: --yoify requested but yoficator is not available; "
            "skipping ё restoration",
            file=sys.stderr,
        )
        yoify = False

    supported = set(letters + DIGITS + "".join(PUNCTUATION))
    counts: collections.Counter[str] = collections.Counter()
    bigram_counts: collections.Counter[str] = collections.Counter()
    uppercase_count = 0
    message_count = 0
    raw_character_count = 0

    for raw_message in messages:
        message = normalize(raw_message)
        if yoify:
            message = _yoify_func(message)
        if not message:
            continue

        message_count += 1
        raw_character_count += len(message)
        uppercase_count += sum(character in letters.upper() for character in message)

        lowered = message.lower()
        stream = [ch for ch in lowered if ch in supported]
        counts.update(stream)
        bigram_counts.update(
            stream[i] + stream[i + 1] for i in range(len(stream) - 1)
        )

    supported_count = sum(counts.values())
    percentages = {
        character: 100 * count / supported_count for character, count in counts.items()
    }
    letters_by_frequency = sorted(
        letters,
        key=lambda character: percentages.get(character, 0),
        reverse=True,
    )

    bigram_total = sum(bigram_counts.values())
    bigram_percentages = [
        [bigram, round(100 * count / bigram_total, 4)]
        for bigram, count in bigram_counts.most_common()
        if 100 * count / bigram_total >= 0.01
    ]

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
        "bigrams": bigram_percentages,
    }


def dailydialog_messages(archive_path: Path) -> Iterator[str]:
    """Yield utterances from a DailyDialog zip archive.

    Each line of ``dialogues_text.txt`` is one dialogue with utterances
    separated by the ``__eou__`` delimiter.
    """

    with zipfile.ZipFile(archive_path) as archive:
        candidates = [n for n in archive.namelist() if n.endswith("dialogues_text.txt")]
        if not candidates:
            raise FileNotFoundError("dialogues_text.txt not found in archive")
        with archive.open(candidates[0]) as stream:
            for raw_line in stream:
                line = raw_line.decode("utf-8").rstrip("\n")
                for utterance in line.split("__eou__"):
                    utterance = utterance.strip()
                    if utterance:
                        yield utterance


def cornell_messages(archive_path: Path) -> Iterator[str]:
    """Yield dialogue lines from a Cornell Movie-Dialogs zip archive.

    The file ``movie_lines.txt`` contains lines in the format::

        L123 +++$+++ u456 +++$+++ m789 +++$+++ NAME +++$+++ text

    The last field is the actual utterance text.
    """

    with zipfile.ZipFile(archive_path) as archive:
        candidates = [n for n in archive.namelist() if n.endswith("movie_lines.txt")]
        if not candidates:
            raise FileNotFoundError("movie_lines.txt not found in archive")
        with archive.open(candidates[0]) as stream:
            for raw_line in stream:
                line = raw_line.decode("latin-1", errors="replace").rstrip("\n")
                parts = line.split(" +++$+++ ")
                text = parts[-1].strip()
                if text:
                    yield text


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
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dailydialog",
        required=True,
        type=Path,
        help="DailyDialog ZIP archive",
    )
    parser.add_argument(
        "--cornell",
        required=True,
        type=Path,
        help="Cornell Movie-Dialogs ZIP archive",
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
    parser.add_argument(
        "--yoify",
        action="store_true",
        help="restore ё in Russian text (requires yoficator)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    results = {
        "en_dailydialog": count_messages(
            dailydialog_messages(args.dailydialog), ENGLISH_LETTERS
        ),
        "en_cornell": count_messages(
            cornell_messages(args.cornell), ENGLISH_LETTERS
        ),
        "ru_toloka": count_messages(
            toloka_messages(args.toloka), RUSSIAN_LETTERS, yoify=args.yoify
        ),
    }
    if args.personachat is not None:
        results["en_personachat_check"] = count_messages(
            personachat_messages(args.personachat), ENGLISH_LETTERS
        )

    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
