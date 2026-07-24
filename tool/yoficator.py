#!/usr/bin/env python3
"""Standalone dictionary-based Russian ё (yo) restorer.

Downloads and parses the eyo-kernel safe word list, then replaces
unambiguous е → ё in Russian text.  Works on Python 3.9+.

Usage::

    from yoficator import yoify

    print(yoify("Еще одна елка"))  # → Ещё одна ёлка
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Dict, Optional

# ---------------------------------------------------------------------------
# Dictionary loading
# ---------------------------------------------------------------------------

_DICT_PATH = Path(__file__).with_name("yo_dict.txt")

# Lazy singleton: loaded on first call to yoify().
_yo_dict: Optional[Dict[str, str]] = None


def _expand_pattern(line: str) -> list[str]:
    """Expand a single eyo-kernel dictionary line into concrete word forms.

    Lines may contain one ``(alt1|alt2|…)`` group at the end which encodes
    multiple suffixes.  An empty alternative (e.g. ``(|а|у)``) means the
    stem itself is also a valid form.

    Examples::

        >>> _expand_pattern("ёлк(а|е|и|ой|у)")
        ['ёлка', 'ёлке', 'ёлки', 'ёлкой', 'ёлку']
        >>> _expand_pattern("ёж")
        ['ёж']
    """

    match = re.search(r"\(([^)]*)\)$", line)
    if match is None:
        return [line]

    stem = line[: match.start()]
    alternatives = match.group(1).split("|")
    return [stem + alt for alt in alternatives]


def _load_dict() -> Dict[str, str]:
    """Load *yo_dict.txt* and build ``{word_without_ё: word_with_ё}``."""

    mapping: Dict[str, str] = {}
    with open(_DICT_PATH, encoding="utf-8") as fh:
        for raw_line in fh:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            for word in _expand_pattern(line):
                # Key: lowercase form with ё replaced by е.
                key = word.lower().replace("ё", "е")
                # Only keep the first (most common) mapping when duplicates
                # arise from different dictionary lines.
                if key not in mapping:
                    mapping[key] = word.lower()
    return mapping


# ---------------------------------------------------------------------------
# Case-transfer helper
# ---------------------------------------------------------------------------

def _transfer_case(source: str, target: str) -> str:
    """Apply the case pattern of *source* onto *target*.

    Handles three common patterns:

    * ALL CAPS  → target uppercased
    * Title Case → target title-cased
    * Otherwise  → character-by-character transfer
    """

    if source.isupper():
        return target.upper()
    if source[0].isupper() and source[1:].islower():
        return target[0].upper() + target[1:]
    # Fallback: per-character transfer (handles mixed case reasonably).
    result: list[str] = []
    for i, ch in enumerate(target):
        if i < len(source) and source[i].isupper():
            result.append(ch.upper())
        else:
            result.append(ch)
    return "".join(result)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

# Pattern that splits text into word tokens (sequences of Cyrillic + ё/Ё)
# and non-word separators, keeping both in the result list.
_WORD_RE = re.compile(r"([А-Яа-яЁё]+)")


def yoify(text: str) -> str:
    """Restore ё in *text* using the eyo-kernel safe dictionary.

    Only unambiguous replacements from the *safe* word list are made.
    The original case of each word is preserved.

    Parameters
    ----------
    text:
        Arbitrary Russian text (may also contain non-Russian content,
        which is passed through unchanged).

    Returns
    -------
    str
        Text with safe ё replacements applied.
    """

    global _yo_dict  # noqa: PLW0603
    if _yo_dict is None:
        _yo_dict = _load_dict()

    parts = _WORD_RE.split(text)
    result: list[str] = []

    for i, part in enumerate(parts):
        if i % 2 == 1:
            # This is a word token (matched by _WORD_RE).
            key = part.lower().replace("ё", "е")
            replacement = _yo_dict.get(key)
            if replacement is not None and replacement != key:
                part = _transfer_case(part, replacement)
        result.append(part)

    return "".join(result)


# ---------------------------------------------------------------------------
# Quick self-test
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    samples = [
        "Еще одна елка",
        "ЕЛКИ-ПАЛКИ",
        "все ежики",
        "Берёза",  # already has ё — should stay
    ]
    for s in samples:
        print(f"  {s!r:30s} → {yoify(s)!r}")
