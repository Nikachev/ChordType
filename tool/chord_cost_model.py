#!/usr/bin/env python3
"""Numerical ergonomic cost model for 6-key chorded keyboard masks.

Each chord (a bitmask of up to 6 keys) gets a numerical cost that combines
key-count penalty, individual finger penalties, and a spread penalty for
non-thumb fingers.  A transition cost between two consecutive chords is also
provided for future bigram-level layout optimization.

Run as a script to see the ranked list and a comparison with the hand-tuned
``chordEaseOrder`` from ``lib/chord_data.dart``.
"""

from __future__ import annotations

import math
import re
from dataclasses import dataclass, field
from pathlib import Path


# ---------------------------------------------------------------------------
# Finger / bit definitions
# ---------------------------------------------------------------------------

BIT_P = 1    # Pinky
BIT_R = 2    # Ring
BIT_M = 4    # Middle
BIT_I = 8    # Index
BIT_T1 = 16  # Primary thumb
BIT_T2 = 32  # Secondary thumb

FINGER_BITS: list[int] = [BIT_P, BIT_R, BIT_M, BIT_I, BIT_T1, BIT_T2]

FINGER_NAMES: dict[int, str] = {
    BIT_P: "P",
    BIT_R: "R",
    BIT_M: "M",
    BIT_I: "I",
    BIT_T1: "T1",
    BIT_T2: "T2",
}

# Non-thumb finger bits in physical order (pinky → index).
NON_THUMB_BITS: list[int] = [BIT_P, BIT_R, BIT_M, BIT_I]

# Position index for spread computation (P=0, R=1, M=2, I=3).
_FINGER_POSITION: dict[int, int] = {
    BIT_P: 0,
    BIT_R: 1,
    BIT_M: 2,
    BIT_I: 3,
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _uses_both_thumbs(mask: int) -> bool:
    """Return True if *mask* has both thumb bits set."""
    return (mask & BIT_T1 != 0) and (mask & BIT_T2 != 0)


def valid_masks() -> list[int]:
    """Return the 47 usable chord masks (1-63, excluding T1+T2 combos)."""
    return [m for m in range(1, 64) if not _uses_both_thumbs(m)]


def mask_label(mask: int) -> str:
    """Human-readable label for a chord mask, e.g. ``P+M+T1``."""
    parts = [FINGER_NAMES[b] for b in FINGER_BITS if mask & b]
    return "+".join(parts)


def popcount(mask: int) -> int:
    """Number of set bits in *mask*."""
    return bin(mask).count("1")


# ---------------------------------------------------------------------------
# Cost model
# ---------------------------------------------------------------------------

# Default per-finger penalties.
DEFAULT_FINGER_PENALTIES: dict[int, float] = {
    BIT_T1: 0.5,
    BIT_T2: 0.7,
    BIT_I: 1.0,
    BIT_M: 1.2,
    BIT_R: 1.8,
    BIT_P: 2.5,
}


@dataclass
class ChordCostModel:
    """Configurable ergonomic cost model for 6-key chords.

    Parameters
    ----------
    w_keys:
        Weight for the key-count penalty term.
    w_spread:
        Weight for the spread penalty term.
    w_shared:
        Weight for shared-finger count in the transition cost.
    w_release:
        Weight for the release complexity in the transition cost.
    finger_penalties:
        Per-finger penalty values keyed by bit constant.
    """

    w_keys: float = 1.0
    w_spread: float = 0.5
    w_shared: float = 2.0
    w_release: float = 0.3
    finger_penalties: dict[int, float] = field(
        default_factory=lambda: dict(DEFAULT_FINGER_PENALTIES),
    )

    # -- single-chord cost --------------------------------------------------

    def key_count_penalty(self, n: int) -> float:
        """Superlinear penalty for pressing *n* keys simultaneously."""
        return n ** 1.5

    def spread_penalty(self, mask: int) -> float:
        """Distance between the furthest-apart non-thumb fingers.

        Fingers are ordered P(0)–R(1)–M(2)–I(3).  Only non-thumb fingers
        contribute.  If fewer than two non-thumb fingers are used the spread
        is 0.
        """
        positions = [
            _FINGER_POSITION[b] for b in NON_THUMB_BITS if mask & b
        ]
        if len(positions) < 2:
            return 0.0
        return float(max(positions) - min(positions))

    def chord_cost(self, mask: int) -> float:
        """Return the total ergonomic cost for a single chord *mask*."""
        n = popcount(mask)
        cost = self.w_keys * self.key_count_penalty(n)
        cost += sum(
            self.finger_penalties[b] for b in FINGER_BITS if mask & b
        )
        cost += self.w_spread * self.spread_penalty(mask)
        return cost

    # -- bigram transition cost ---------------------------------------------

    def transition_cost(self, mask_a: int, mask_b: int) -> float:
        """Cost of typing *mask_b* immediately after *mask_a*.

        Penalizes shared non-thumb fingers (must release and re-press) and
        the overall complexity of releasing the first chord.
        """
        shared = sum(
            1 for b in NON_THUMB_BITS if (mask_a & b) and (mask_b & b)
        )
        return (
            self.w_shared * shared
            + self.w_release * popcount(mask_a)
        )

    # -- ranking ------------------------------------------------------------

    def ranked_masks(self) -> list[int]:
        """Return all 47 valid masks sorted by ascending chord cost."""
        masks = valid_masks()
        masks.sort(key=self.chord_cost)
        return masks


# ---------------------------------------------------------------------------
# chordEaseOrder extraction from chord_data.dart
# ---------------------------------------------------------------------------

def _read_chord_ease_order() -> list[int]:
    """Parse ``chordEaseOrder`` from ``lib/chord_data.dart``."""
    dart_path = Path(__file__).resolve().parent.parent / "lib" / "chord_data.dart"
    text = dart_path.read_text(encoding="utf-8")

    match = re.search(
        r"const\s+List<int>\s+chordEaseOrder\s*=\s*<int>\[(.*?)\];",
        text,
        re.DOTALL,
    )
    if not match:
        raise RuntimeError("chordEaseOrder not found in chord_data.dart")

    return [int(x) for x in re.findall(r"\d+", match.group(1))]


# ---------------------------------------------------------------------------
# Pretty-printing helpers
# ---------------------------------------------------------------------------

def _format_row(
    rank: int,
    mask: int,
    cost: float,
    dart_rank: int | None,
) -> str:
    delta = ""
    if dart_rank is not None:
        diff = dart_rank - rank
        if diff > 0:
            delta = f"  (dart: #{dart_rank + 1}, Δ +{diff})"
        elif diff < 0:
            delta = f"  (dart: #{dart_rank + 1}, Δ {diff})"
    label = mask_label(mask)
    return f"  {rank + 1:3d}. mask {mask:2d}  ({mask:06b})  {label:16s}  cost {cost:6.2f}{delta}"


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> None:
    """Print ranked chord masks with costs and compare to ``chordEaseOrder``."""
    model = ChordCostModel()
    ranked = model.ranked_masks()

    try:
        dart_order = _read_chord_ease_order()
        dart_rank_of: dict[int, int] = {m: i for i, m in enumerate(dart_order)}
    except (FileNotFoundError, RuntimeError) as exc:
        print(f"Warning: could not read chordEaseOrder: {exc}")
        dart_rank_of = {}

    print("Chord cost model — ranked masks (cheapest first)")
    print("=" * 72)
    print(
        f"  Weights: w_keys={model.w_keys}, w_spread={model.w_spread}, "
        f"w_shared={model.w_shared}, w_release={model.w_release}"
    )
    print()

    for rank, mask in enumerate(ranked):
        cost = model.chord_cost(mask)
        print(_format_row(rank, mask, cost, dart_rank_of.get(mask)))

    # Summary of large disagreements.
    if dart_rank_of:
        print()
        print("Largest disagreements (|Δ| ≥ 5):")
        print("-" * 72)
        model_rank_of = {m: i for i, m in enumerate(ranked)}
        disagreements: list[tuple[int, int, int]] = []
        for mask in ranked:
            dr = dart_rank_of.get(mask)
            if dr is not None:
                mr = model_rank_of[mask]
                diff = abs(dr - mr)
                if diff >= 5:
                    disagreements.append((diff, mask, dr - mr))
        disagreements.sort(reverse=True)
        if not disagreements:
            print("  None — model and dart order agree within 4 positions.")
        for diff, mask, signed in disagreements:
            label = mask_label(mask)
            direction = "easier in dart" if signed > 0 else "harder in dart"
            print(f"  mask {mask:2d}  {label:16s}  |Δ|={diff:2d}  ({direction})")


if __name__ == "__main__":
    main()
