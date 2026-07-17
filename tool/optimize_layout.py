#!/usr/bin/env python3
"""Optimize chord–character assignments for the Chordtype chorded keyboard.

Reads character and bigram frequency data produced by
``analyze_layout_frequencies.py`` and searches for a mask assignment that
minimizes the weighted sum of unigram cost (chord ergonomic cost × character
frequency) and bigram cost (transition cost × bigram frequency) across both
English and Russian layouts.

Pipeline
--------
1. **Greedy initialization** — assign the highest-frequency characters to the
   cheapest available chord masks.
2. **Hill climbing** — try every pairwise swap within the same category
   (punctuation, language-specific) and accept improvements.
3. **Simulated annealing** — refine with stochastic swaps for a configurable
   number of iterations.

Usage::

    python3 tool/optimize_layout.py \\
        --frequencies data/frequencies.json \\
        [--alpha 0.7] [--beta 0.3] \\
        [--iterations 50000] [--seed 42]

The JSON result is printed to *stdout*; progress is reported to *stderr*.
"""

from __future__ import annotations

import argparse
import copy
import json
import math
import random
import sys
from pathlib import Path
from typing import Any

# Ensure ``tool/`` is importable when running from the repository root.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from chord_cost_model import ChordCostModel, mask_label, valid_masks


# ---------------------------------------------------------------------------
# Constants — fixed mask assignments (shared between EN and RU)
# ---------------------------------------------------------------------------

SPACE_MASK = 16        # T1
BACKSPACE_MASK = 5     # P+M
ENTER_MASK = 10        # R+I
SWITCH_MASK = 47       # P+R+M+I+T2
NUMBERS_MASK = 30      # R+M+I+T1

FIXED_MASKS: dict[int, str] = {
    SPACE_MASK: "Space",
    BACKSPACE_MASK: "Backspace",
    ENTER_MASK: "Enter",
    SWITCH_MASK: "EN/RU switch",
    NUMBERS_MASK: "Numbers & symbols layer",
}

# Shared punctuation keys: base → shifted.
SHARED_PUNCTUATION: dict[str, str] = {
    ".": ">",
    "?": "!",
    ",": "<",
    ")": "(",
    "'": '"',
    ":": ";",
    "-": "_",
    "=": "+",
}

# EN-only symbol pairs: base → shifted.
EN_ONLY_SYMBOLS: dict[str, str] = {
    "#": "@",
    "*": "^",
    "/": "\\",
    "&": "|",
    "~": "`",
    "$": "%",
    "[": "]",
}

ENGLISH_LETTERS = "abcdefghijklmnopqrstuvwxyz"
RUSSIAN_LETTERS = "абвгдеёжзийклмнопрстуфхцчшщъыьэюя"

# ---------------------------------------------------------------------------
# Current layout (from chord_data.dart) for diff output
# ---------------------------------------------------------------------------

CURRENT_EN_LETTERS: dict[int, str] = {
    8: "e", 4: "a", 32: "o", 2: "t", 1: "i", 24: "n", 12: "h", 40: "s",
    18: "r", 36: "l", 6: "u", 17: "m", 34: "d", 33: "y", 9: "g", 3: "c",
    28: "w", 22: "p", 26: "k", 38: "b", 42: "f", 14: "v", 19: "j",
    37: "x", 13: "z", 11: "q",
}

CURRENT_EN_SYMBOLS: dict[int, str] = {
    41: "#", 46: "*", 29: "/", 45: "&", 27: "~", 39: "$", 31: "[",
}

CURRENT_RU_LETTERS: dict[int, str] = {
    8: "о", 4: "е", 32: "а", 2: "т", 1: "н", 24: "и", 12: "с", 40: "р",
    18: "в", 36: "л", 6: "к", 17: "м", 34: "у", 33: "я", 9: "д", 3: "ь",
    28: "б", 22: "п", 26: "ю", 38: "ч", 42: "ы", 14: "з", 19: "г",
    37: "ж", 13: "ш", 11: "х", 41: "й", 46: "э", 29: "щ", 45: "ц",
    27: "ё", 39: "ф", 31: "ъ",
}

CURRENT_SHIFT_MASK = 20

CURRENT_PUNCT_MASKS: dict[int, str] = {
    44: ".", 21: "?", 25: ",", 35: ")", 7: "'", 23: ":", 43: "-", 15: "=",
}


# ---------------------------------------------------------------------------
# Frequency helpers
# ---------------------------------------------------------------------------

def _merge_en_frequencies(
    data: dict[str, Any],
    *,
    weight_daily: float = 0.5,
    weight_cornell: float = 0.5,
) -> dict[str, Any]:
    """Merge ``en_dailydialog`` and ``en_cornell`` into a single EN section.

    Letter and bigram percentages are combined with the given weights
    (default: simple average, i.e. 0.5/0.5).
    """
    dd = data["en_dailydialog"]
    co = data["en_cornell"]

    # --- letters ---
    dd_letters = {ch: pct for ch, pct in dd["letters"]}
    co_letters = {ch: pct for ch, pct in co["letters"]}
    all_letters = sorted(
        set(dd_letters) | set(co_letters),
        key=lambda ch: -(
            weight_daily * dd_letters.get(ch, 0.0)
            + weight_cornell * co_letters.get(ch, 0.0)
        ),
    )
    merged_letters = [
        [ch, round(weight_daily * dd_letters.get(ch, 0.0)
                    + weight_cornell * co_letters.get(ch, 0.0), 4)]
        for ch in all_letters
    ]

    # --- bigrams ---
    dd_bigrams = {bg: pct for bg, pct in dd["bigrams"]}
    co_bigrams = {bg: pct for bg, pct in co["bigrams"]}
    all_bigrams_set = set(dd_bigrams) | set(co_bigrams)
    merged_bigrams_raw = {
        bg: weight_daily * dd_bigrams.get(bg, 0.0)
            + weight_cornell * co_bigrams.get(bg, 0.0)
        for bg in all_bigrams_set
    }
    merged_bigrams = sorted(
        [[bg, round(pct, 4)] for bg, pct in merged_bigrams_raw.items() if pct >= 0.01],
        key=lambda x: -x[1],
    )

    # --- punctuation ---
    dd_punct = {ch: pct for ch, pct in dd["punctuation"]}
    co_punct = {ch: pct for ch, pct in co["punctuation"]}
    all_punct = sorted(
        set(dd_punct) | set(co_punct),
        key=lambda ch: -(
            weight_daily * dd_punct.get(ch, 0.0)
            + weight_cornell * co_punct.get(ch, 0.0)
        ),
    )
    merged_punct = [
        [ch, round(weight_daily * dd_punct.get(ch, 0.0)
                    + weight_cornell * co_punct.get(ch, 0.0), 4)]
        for ch in all_punct
    ]

    # --- scalars ---
    uppercase = round(
        weight_daily * dd["uppercase_actions_percent"]
        + weight_cornell * co["uppercase_actions_percent"], 4,
    )
    digits = round(
        weight_daily * dd["digits_total_percent"]
        + weight_cornell * co["digits_total_percent"], 4,
    )
    msg_boundary = round(
        weight_daily * dd["message_boundary_actions_percent"]
        + weight_cornell * co["message_boundary_actions_percent"], 4,
    )

    return {
        "letters": merged_letters,
        "bigrams": merged_bigrams,
        "punctuation": merged_punct,
        "uppercase_actions_percent": uppercase,
        "digits_total_percent": digits,
        "message_boundary_actions_percent": msg_boundary,
    }


def _build_freq_table(
    section: dict[str, Any],
) -> tuple[dict[str, float], dict[str, float]]:
    """Return ``(char_freq, bigram_freq)`` dicts from a frequency section.

    ``char_freq`` includes letters, punctuation symbols (base forms only),
    and synthetic entries for Shift, Space, Enter, and Backspace whose
    frequencies are inferred from the section metadata.
    """
    char_freq: dict[str, float] = {}

    for ch, pct in section["letters"]:
        char_freq[ch] = pct

    for ch, pct in section["punctuation"]:
        char_freq[ch] = pct

    # Synthetic frequencies for control chords.
    char_freq["__shift__"] = section["uppercase_actions_percent"]
    char_freq["__enter__"] = section["message_boundary_actions_percent"]
    # Backspace frequency is not directly measured; approximate as ~2%.
    char_freq["__backspace__"] = 2.0

    bigram_freq: dict[str, float] = {}
    for bg, pct in section["bigrams"]:
        bigram_freq[bg] = pct

    return char_freq, bigram_freq


# ---------------------------------------------------------------------------
# Assignment data structures
# ---------------------------------------------------------------------------

class Assignment:
    """Mutable assignment of characters to chord masks.

    Attributes
    ----------
    shift_mask:
        Mask used for the Shift modifier (shared EN/RU).
    punct_mask:
        ``{mask: base_char}`` for the 8 shared punctuation keys.
    en_letter_mask:
        ``{mask: letter}`` — 26 English letters.
    en_symbol_mask:
        ``{mask: symbol}`` — 7 EN-only symbol pairs.
    ru_letter_mask:
        ``{mask: letter}`` — 33 Russian letters.
    """

    def __init__(self) -> None:
        self.shift_mask: int = 0
        self.punct_mask: dict[int, str] = {}
        self.en_letter_mask: dict[int, str] = {}
        self.en_symbol_mask: dict[int, str] = {}
        self.ru_letter_mask: dict[int, str] = {}

    # -- convenience reverse maps -------------------------------------------

    def en_char_to_mask(self) -> dict[str, int]:
        """Map every EN character (letters + symbols + punctuation base) → mask."""
        out: dict[str, int] = {}
        for m, ch in self.en_letter_mask.items():
            out[ch] = m
        for m, ch in self.en_symbol_mask.items():
            out[ch] = m
        for m, ch in self.punct_mask.items():
            out[ch] = m
        out[" "] = SPACE_MASK
        out["__shift__"] = self.shift_mask
        out["__enter__"] = ENTER_MASK
        out["__backspace__"] = BACKSPACE_MASK
        return out

    def ru_char_to_mask(self) -> dict[str, int]:
        """Map every RU character (letters + punctuation base) → mask."""
        out: dict[str, int] = {}
        for m, ch in self.ru_letter_mask.items():
            out[ch] = m
        for m, ch in self.punct_mask.items():
            out[ch] = m
        out[" "] = SPACE_MASK
        out["__shift__"] = self.shift_mask
        out["__enter__"] = ENTER_MASK
        out["__backspace__"] = BACKSPACE_MASK
        return out

    def copy(self) -> Assignment:
        a = Assignment()
        a.shift_mask = self.shift_mask
        a.punct_mask = dict(self.punct_mask)
        a.en_letter_mask = dict(self.en_letter_mask)
        a.en_symbol_mask = dict(self.en_symbol_mask)
        a.ru_letter_mask = dict(self.ru_letter_mask)
        return a


# ---------------------------------------------------------------------------
# Cost evaluation
# ---------------------------------------------------------------------------

def _unigram_cost(
    char_freq: dict[str, float],
    char_to_mask: dict[str, int],
    model: ChordCostModel,
) -> float:
    """Σ freq(char) × chord_cost(mask(char)) for all assigned characters."""
    total = 0.0
    for ch, freq in char_freq.items():
        mask = char_to_mask.get(ch)
        if mask is not None:
            total += freq * model.chord_cost(mask)
    return total


def _bigram_cost(
    bigram_freq: dict[str, float],
    char_to_mask: dict[str, int],
    model: ChordCostModel,
) -> float:
    """Σ bigram_freq(a,b) × transition_cost(mask(a), mask(b))."""
    total = 0.0
    for bg, freq in bigram_freq.items():
        if len(bg) == 2:
            m_a = char_to_mask.get(bg[0])
            m_b = char_to_mask.get(bg[1])
            if m_a is not None and m_b is not None:
                total += freq * model.transition_cost(m_a, m_b)
    return total


def evaluate(
    assignment: Assignment,
    en_char_freq: dict[str, float],
    en_bigram_freq: dict[str, float],
    ru_char_freq: dict[str, float],
    ru_bigram_freq: dict[str, float],
    model: ChordCostModel,
    alpha: float,
    beta: float,
) -> float:
    """Compute the total objective cost for an assignment.

    ``total = α × (unigram_EN + unigram_RU) + β × (bigram_EN + bigram_RU)``
    """
    en_map = assignment.en_char_to_mask()
    ru_map = assignment.ru_char_to_mask()

    uni = _unigram_cost(en_char_freq, en_map, model) + _unigram_cost(ru_char_freq, ru_map, model)
    bi = _bigram_cost(en_bigram_freq, en_map, model) + _bigram_cost(ru_bigram_freq, ru_map, model)

    return alpha * uni + beta * bi


# ---------------------------------------------------------------------------
# Greedy initialization
# ---------------------------------------------------------------------------

def _greedy_init(
    en_char_freq: dict[str, float],
    ru_char_freq: dict[str, float],
    model: ChordCostModel,
) -> Assignment:
    """Assign characters to masks greedily by frequency × cost.

    Steps:
    1. Determine the 42 optimizable masks.
    2. Assign Shift to the mask whose cost is closest to its combined frequency
       rank.
    3. Assign 8 shared punctuation characters.
    4. Assign 33 language-specific masks (EN letters + symbols paired with RU
       letters).
    """
    all_valid = set(valid_masks())
    fixed = set(FIXED_MASKS)
    optimizable = sorted(all_valid - fixed, key=model.chord_cost)

    assignment = Assignment()

    # --- Shift ---------------------------------------------------------------
    shift_freq = (
        en_char_freq.get("__shift__", 0.0)
        + ru_char_freq.get("__shift__", 0.0)
    )
    # Shift is moderately frequent — pick a good mask for it.
    # We rank Shift among all items below but first just grab the cheapest mask
    # that is "appropriate" (i.e. we want Shift relatively cheap).
    # Strategy: collect all (combined_freq, item) pairs, sort descending,
    # then assign cheapest mask to highest-freq item.  Shift is one of those
    # items and will naturally land on a good mask.

    # For the greedy phase we'll build a unified sorted list of all items to
    # assign, then iterate through masks cheapest-first.

    # --- Build item list sorted by combined frequency (descending) -----------

    # Punctuation items.
    punct_items: list[tuple[float, str, str]] = []  # (freq, category, char)
    for base_char in SHARED_PUNCTUATION:
        freq = en_char_freq.get(base_char, 0.0) + ru_char_freq.get(base_char, 0.0)
        punct_items.append((freq, "punct", base_char))

    # Shift.
    shift_item = (shift_freq, "shift", "__shift__")

    # Language-specific items.  EN has 26 letters + 7 symbols = 33 slots.
    # RU has 33 letters.  They share the same 33 masks.  We sort by combined
    # frequency of (EN_letter[i] + RU_letter[i]) where letters are sorted
    # independently by frequency.

    en_letters_sorted = sorted(
        ENGLISH_LETTERS,
        key=lambda ch: en_char_freq.get(ch, 0.0),
        reverse=True,
    )
    en_symbols_sorted = sorted(
        EN_ONLY_SYMBOLS.keys(),
        key=lambda ch: en_char_freq.get(ch, 0.0),
        reverse=True,
    )
    # Full EN list: 26 letters first (most frequent), then 7 symbols.
    en_all = en_letters_sorted + en_symbols_sorted  # 33 items

    ru_letters_sorted = sorted(
        RUSSIAN_LETTERS,
        key=lambda ch: ru_char_freq.get(ch, 0.0),
        reverse=True,
    )  # 33 items

    # Pair them up: the i-th most frequent EN char shares a mask with the
    # i-th most frequent RU char.
    lang_items: list[tuple[float, int, str, str]] = []  # (freq, index, en_ch, ru_ch)
    for i, (en_ch, ru_ch) in enumerate(zip(en_all, ru_letters_sorted)):
        freq = en_char_freq.get(en_ch, 0.0) + ru_char_freq.get(ru_ch, 0.0)
        lang_items.append((freq, i, en_ch, ru_ch))
    lang_items.sort(key=lambda x: x[0], reverse=True)

    # --- Assign masks (cheapest-first to highest-freq items) -----------------

    # Combine everything into a single priority list sorted by frequency desc.
    all_items: list[tuple[float, str, Any]] = []
    all_items.append((shift_item[0], "shift", None))
    for freq, _, base_char in punct_items:
        all_items.append((freq, "punct", base_char))
    for freq, idx, en_ch, ru_ch in lang_items:
        all_items.append((freq, "lang", (idx, en_ch, ru_ch)))

    all_items.sort(key=lambda x: x[0], reverse=True)

    mask_idx = 0
    for freq, category, payload in all_items:
        mask = optimizable[mask_idx]
        mask_idx += 1

        if category == "shift":
            assignment.shift_mask = mask
        elif category == "punct":
            assignment.punct_mask[mask] = payload
        elif category == "lang":
            _idx, en_ch, ru_ch = payload
            if en_ch in ENGLISH_LETTERS:
                assignment.en_letter_mask[mask] = en_ch
            else:
                assignment.en_symbol_mask[mask] = en_ch
            assignment.ru_letter_mask[mask] = ru_ch

    return assignment


# ---------------------------------------------------------------------------
# Swap helpers
# ---------------------------------------------------------------------------

def _swap_masks_in_dict(d: dict[int, str], m1: int, m2: int) -> None:
    """Swap values at keys *m1* and *m2* in dict *d* (in-place)."""
    has_1 = m1 in d
    has_2 = m2 in d
    if has_1 and has_2:
        d[m1], d[m2] = d[m2], d[m1]
    elif has_1:
        d[m2] = d.pop(m1)
    elif has_2:
        d[m1] = d.pop(m2)


def _apply_lang_swap(a: Assignment, m1: int, m2: int) -> None:
    """Swap two language-specific masks in both EN and RU maps."""
    _swap_masks_in_dict(a.en_letter_mask, m1, m2)
    _swap_masks_in_dict(a.en_symbol_mask, m1, m2)
    _swap_masks_in_dict(a.ru_letter_mask, m1, m2)


def _apply_punct_swap(a: Assignment, m1: int, m2: int) -> None:
    """Swap two punctuation masks."""
    _swap_masks_in_dict(a.punct_mask, m1, m2)


def _apply_shift_lang_swap(a: Assignment, m1: int, m2: int) -> None:
    """Swap Shift mask (*m1*) with a language mask (*m2*).

    Shift moves to *m2*; the language character that was on *m2* moves to *m1*.
    """
    a.shift_mask = m2
    # Move the language entry from m2 → m1.
    if m2 in a.en_letter_mask:
        a.en_letter_mask[m1] = a.en_letter_mask.pop(m2)
    elif m2 in a.en_symbol_mask:
        a.en_symbol_mask[m1] = a.en_symbol_mask.pop(m2)
    if m2 in a.ru_letter_mask:
        a.ru_letter_mask[m1] = a.ru_letter_mask.pop(m2)


def _apply_shift_punct_swap(a: Assignment, m1: int, m2: int) -> None:
    """Swap Shift mask (*m1*) with a punctuation mask (*m2*)."""
    a.shift_mask = m2
    a.punct_mask[m1] = a.punct_mask.pop(m2)


# ---------------------------------------------------------------------------
# Hill climbing
# ---------------------------------------------------------------------------

def _hill_climb(
    assignment: Assignment,
    en_char_freq: dict[str, float],
    en_bigram_freq: dict[str, float],
    ru_char_freq: dict[str, float],
    ru_bigram_freq: dict[str, float],
    model: ChordCostModel,
    alpha: float,
    beta: float,
) -> float:
    """Perform hill climbing with pairwise swaps until no improvement.

    Returns the final cost.
    """
    best_cost = evaluate(
        assignment, en_char_freq, en_bigram_freq,
        ru_char_freq, ru_bigram_freq, model, alpha, beta,
    )

    improved = True
    iteration = 0
    while improved:
        improved = False
        iteration += 1
        print(
            f"  Hill-climbing pass {iteration}, cost = {best_cost:.4f}",
            file=sys.stderr,
        )

        # --- language mask swaps ---
        lang_masks = sorted(
            set(assignment.en_letter_mask)
            | set(assignment.en_symbol_mask)
        )
        for i in range(len(lang_masks)):
            for j in range(i + 1, len(lang_masks)):
                m1, m2 = lang_masks[i], lang_masks[j]
                _apply_lang_swap(assignment, m1, m2)
                new_cost = evaluate(
                    assignment, en_char_freq, en_bigram_freq,
                    ru_char_freq, ru_bigram_freq, model, alpha, beta,
                )
                if new_cost < best_cost - 1e-9:
                    best_cost = new_cost
                    improved = True
                else:
                    _apply_lang_swap(assignment, m1, m2)  # undo

        # --- punctuation mask swaps ---
        punct_masks = sorted(assignment.punct_mask)
        for i in range(len(punct_masks)):
            for j in range(i + 1, len(punct_masks)):
                m1, m2 = punct_masks[i], punct_masks[j]
                _apply_punct_swap(assignment, m1, m2)
                new_cost = evaluate(
                    assignment, en_char_freq, en_bigram_freq,
                    ru_char_freq, ru_bigram_freq, model, alpha, beta,
                )
                if new_cost < best_cost - 1e-9:
                    best_cost = new_cost
                    improved = True
                else:
                    _apply_punct_swap(assignment, m1, m2)  # undo

        # --- Shift ↔ language swaps ---
        shift_m = assignment.shift_mask
        for m2 in list(lang_masks):
            saved = assignment.copy()
            _apply_shift_lang_swap(assignment, shift_m, m2)
            new_cost = evaluate(
                assignment, en_char_freq, en_bigram_freq,
                ru_char_freq, ru_bigram_freq, model, alpha, beta,
            )
            if new_cost < best_cost - 1e-9:
                best_cost = new_cost
                improved = True
                shift_m = assignment.shift_mask  # updated
            else:
                # Restore.
                assignment.shift_mask = saved.shift_mask
                assignment.en_letter_mask = saved.en_letter_mask
                assignment.en_symbol_mask = saved.en_symbol_mask
                assignment.ru_letter_mask = saved.ru_letter_mask

        # --- Shift ↔ punctuation swaps ---
        shift_m = assignment.shift_mask
        for m2 in list(punct_masks):
            saved = assignment.copy()
            _apply_shift_punct_swap(assignment, shift_m, m2)
            new_cost = evaluate(
                assignment, en_char_freq, en_bigram_freq,
                ru_char_freq, ru_bigram_freq, model, alpha, beta,
            )
            if new_cost < best_cost - 1e-9:
                best_cost = new_cost
                improved = True
                shift_m = assignment.shift_mask
            else:
                assignment.shift_mask = saved.shift_mask
                assignment.punct_mask = saved.punct_mask

    return best_cost


# ---------------------------------------------------------------------------
# Simulated annealing
# ---------------------------------------------------------------------------

def _simulated_annealing(
    assignment: Assignment,
    en_char_freq: dict[str, float],
    en_bigram_freq: dict[str, float],
    ru_char_freq: dict[str, float],
    ru_bigram_freq: dict[str, float],
    model: ChordCostModel,
    alpha: float,
    beta: float,
    iterations: int,
    rng: random.Random,
    *,
    t_start: float = 10.0,
    t_end: float = 0.01,
    cooling_rate: float = 0.999,
) -> float:
    """Run simulated annealing starting from the current assignment.

    Returns the final best cost.
    """
    current_cost = evaluate(
        assignment, en_char_freq, en_bigram_freq,
        ru_char_freq, ru_bigram_freq, model, alpha, beta,
    )
    best_cost = current_cost
    best_assignment = assignment.copy()

    temp = t_start
    accepted = 0

    lang_masks = sorted(
        set(assignment.en_letter_mask)
        | set(assignment.en_symbol_mask)
    )
    punct_masks = sorted(assignment.punct_mask)

    for step in range(iterations):
        if step > 0 and step % 10000 == 0:
            print(
                f"  SA step {step}/{iterations}, T={temp:.4f}, "
                f"cost={current_cost:.4f}, best={best_cost:.4f}, "
                f"accepted={accepted}",
                file=sys.stderr,
            )

        # Pick a random swap category.
        # Weighted towards language swaps since there are far more of them.
        r = rng.random()
        if r < 0.70:
            # Language swap.
            m1, m2 = rng.sample(lang_masks, 2)
            _apply_lang_swap(assignment, m1, m2)
            undo = lambda: _apply_lang_swap(assignment, m1, m2)
        elif r < 0.88:
            # Punctuation swap.
            m1, m2 = rng.sample(punct_masks, 2)
            _apply_punct_swap(assignment, m1, m2)
            undo = lambda: _apply_punct_swap(assignment, m1, m2)
        elif r < 0.94:
            # Shift ↔ language.
            saved = assignment.copy()
            m2 = rng.choice(lang_masks)
            old_shift = assignment.shift_mask
            _apply_shift_lang_swap(assignment, old_shift, m2)
            # Update lang_masks for subsequent iterations.
            if old_shift in lang_masks:
                pass  # shouldn't be
            # Build undo closure.
            _saved = saved
            def undo(s=_saved):
                assignment.shift_mask = s.shift_mask
                assignment.en_letter_mask = s.en_letter_mask
                assignment.en_symbol_mask = s.en_symbol_mask
                assignment.ru_letter_mask = s.ru_letter_mask
        else:
            # Shift ↔ punctuation.
            saved = assignment.copy()
            m2 = rng.choice(punct_masks)
            old_shift = assignment.shift_mask
            _apply_shift_punct_swap(assignment, old_shift, m2)
            _saved = saved
            def undo(s=_saved):
                assignment.shift_mask = s.shift_mask
                assignment.punct_mask = s.punct_mask

        new_cost = evaluate(
            assignment, en_char_freq, en_bigram_freq,
            ru_char_freq, ru_bigram_freq, model, alpha, beta,
        )
        delta = new_cost - current_cost

        if delta < 0 or rng.random() < math.exp(-delta / max(temp, 1e-15)):
            # Accept.
            current_cost = new_cost
            accepted += 1

            # Refresh mask lists after structural changes.
            lang_masks = sorted(
                set(assignment.en_letter_mask)
                | set(assignment.en_symbol_mask)
            )
            punct_masks = sorted(assignment.punct_mask)

            if current_cost < best_cost:
                best_cost = current_cost
                best_assignment = assignment.copy()
        else:
            undo()

        temp = max(temp * cooling_rate, t_end)

    # Restore best-seen assignment.
    assignment.shift_mask = best_assignment.shift_mask
    assignment.punct_mask = best_assignment.punct_mask
    assignment.en_letter_mask = best_assignment.en_letter_mask
    assignment.en_symbol_mask = best_assignment.en_symbol_mask
    assignment.ru_letter_mask = best_assignment.ru_letter_mask

    print(
        f"  SA finished: best={best_cost:.4f}, accepted={accepted}/{iterations}",
        file=sys.stderr,
    )
    return best_cost


# ---------------------------------------------------------------------------
# Diff with current layout
# ---------------------------------------------------------------------------

def _compute_changes(assignment: Assignment) -> list[dict[str, Any]]:
    """Compare *assignment* against the current layout from chord_data.dart."""
    changes: list[dict[str, Any]] = []

    # Gather all masks that appear in either the old or new layout.
    all_masks = sorted(
        set(assignment.en_letter_mask)
        | set(assignment.en_symbol_mask)
        | set(assignment.ru_letter_mask)
        | set(CURRENT_EN_LETTERS)
        | set(CURRENT_EN_SYMBOLS)
        | set(CURRENT_RU_LETTERS)
    )

    for mask in all_masks:
        old_en = CURRENT_EN_LETTERS.get(mask) or CURRENT_EN_SYMBOLS.get(mask)
        new_en = assignment.en_letter_mask.get(mask) or assignment.en_symbol_mask.get(mask)
        old_ru = CURRENT_RU_LETTERS.get(mask)
        new_ru = assignment.ru_letter_mask.get(mask)

        if old_en != new_en or old_ru != new_ru:
            changes.append({
                "mask": mask,
                "was_en": old_en or "",
                "now_en": new_en or "",
                "was_ru": old_ru or "",
                "now_ru": new_ru or "",
            })

    # Shift change.
    if assignment.shift_mask != CURRENT_SHIFT_MASK:
        changes.insert(0, {
            "mask_change": "shift",
            "was_mask": CURRENT_SHIFT_MASK,
            "now_mask": assignment.shift_mask,
        })

    # Punctuation changes.
    for mask, base_char in sorted(assignment.punct_mask.items()):
        old_char = CURRENT_PUNCT_MASKS.get(mask)
        if old_char != base_char:
            changes.append({
                "mask": mask,
                "was_punct": old_char or "",
                "now_punct": base_char,
            })

    return changes


# ---------------------------------------------------------------------------
# JSON report
# ---------------------------------------------------------------------------

def _build_report(
    assignment: Assignment,
    model: ChordCostModel,
    alpha: float,
    beta: float,
    iterations: int,
    initial_cost: float,
    optimized_cost: float,
) -> dict[str, Any]:
    """Build the final JSON report dict."""
    improvement = (
        100.0 * (initial_cost - optimized_cost) / initial_cost
        if initial_cost > 0 else 0.0
    )

    chord_ease_order = sorted(valid_masks(), key=model.chord_cost)

    return {
        "metadata": {
            "alpha": alpha,
            "beta": beta,
            "iterations": iterations,
            "initial_cost": round(initial_cost, 4),
            "optimized_cost": round(optimized_cost, 4),
            "improvement_percent": round(improvement, 2),
        },
        "fixed_assignments": {
            str(mask): name for mask, name in sorted(FIXED_MASKS.items())
        },
        "shift_mask": assignment.shift_mask,
        "shared_punctuation": {
            str(mask): [base, SHARED_PUNCTUATION[base]]
            for mask, base in sorted(assignment.punct_mask.items())
        },
        "english_layout": {
            "letters": {
                str(mask): ch
                for mask, ch in sorted(
                    assignment.en_letter_mask.items(),
                    key=lambda x: model.chord_cost(x[0]),
                )
            },
            "language_symbols": {
                str(mask): ch
                for mask, ch in sorted(
                    assignment.en_symbol_mask.items(),
                    key=lambda x: model.chord_cost(x[0]),
                )
            },
        },
        "russian_layout": {
            "letters": {
                str(mask): ch
                for mask, ch in sorted(
                    assignment.ru_letter_mask.items(),
                    key=lambda x: model.chord_cost(x[0]),
                )
            },
        },
        "chord_ease_order": chord_ease_order,
        "changes_from_current": _compute_changes(assignment),
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Optimize chord–character layout for Chordtype.",
    )
    parser.add_argument(
        "--frequencies",
        required=True,
        type=Path,
        help="Path to the JSON produced by analyze_layout_frequencies.py",
    )
    parser.add_argument(
        "--alpha",
        type=float,
        default=0.7,
        help="Weight for unigram cost (default: 0.7)",
    )
    parser.add_argument(
        "--beta",
        type=float,
        default=0.3,
        help="Weight for bigram cost (default: 0.3)",
    )
    parser.add_argument(
        "--iterations",
        type=int,
        default=50_000,
        help="Number of simulated-annealing iterations (default: 50000)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for reproducibility (default: 42)",
    )
    parser.add_argument(
        "--en-weight-daily",
        type=float,
        default=0.5,
        help="Weight for DailyDialog when merging EN corpora (default: 0.5)",
    )
    parser.add_argument(
        "--en-weight-cornell",
        type=float,
        default=0.5,
        help="Weight for Cornell when merging EN corpora (default: 0.5)",
    )
    return parser.parse_args()


def main() -> None:
    """Run the full optimization pipeline and print the JSON report."""
    args = parse_args()
    rng = random.Random(args.seed)

    # --- Load frequencies ----------------------------------------------------
    print("Loading frequencies …", file=sys.stderr)
    freq_data = json.loads(args.frequencies.read_text(encoding="utf-8"))

    en_section = _merge_en_frequencies(
        freq_data,
        weight_daily=args.en_weight_daily,
        weight_cornell=args.en_weight_cornell,
    )
    ru_section = freq_data["ru_toloka"]

    en_char_freq, en_bigram_freq = _build_freq_table(en_section)
    ru_char_freq, ru_bigram_freq = _build_freq_table(ru_section)

    model = ChordCostModel()

    # --- 1. Greedy initialization --------------------------------------------
    print("Step 1: Greedy initialization …", file=sys.stderr)
    assignment = _greedy_init(en_char_freq, ru_char_freq, model)
    initial_cost = evaluate(
        assignment, en_char_freq, en_bigram_freq,
        ru_char_freq, ru_bigram_freq, model, args.alpha, args.beta,
    )
    print(f"  Initial cost = {initial_cost:.4f}", file=sys.stderr)

    # --- 2. Hill climbing ----------------------------------------------------
    print("Step 2: Hill climbing …", file=sys.stderr)
    hc_cost = _hill_climb(
        assignment, en_char_freq, en_bigram_freq,
        ru_char_freq, ru_bigram_freq, model, args.alpha, args.beta,
    )
    print(f"  Hill-climbing cost = {hc_cost:.4f}", file=sys.stderr)

    # --- 3. Simulated annealing ----------------------------------------------
    print(f"Step 3: Simulated annealing ({args.iterations} iterations) …", file=sys.stderr)
    sa_cost = _simulated_annealing(
        assignment, en_char_freq, en_bigram_freq,
        ru_char_freq, ru_bigram_freq, model, args.alpha, args.beta,
        iterations=args.iterations, rng=rng,
    )
    print(f"  Final cost = {sa_cost:.4f}", file=sys.stderr)

    # --- Build and emit report -----------------------------------------------
    report = _build_report(
        assignment, model, args.alpha, args.beta,
        args.iterations, initial_cost, sa_cost,
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
