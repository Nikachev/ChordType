#!/usr/bin/env python3
"""Tests for the chord ergonomic cost model."""

from __future__ import annotations

import math
import unittest

from chord_cost_model import (
    BIT_I,
    BIT_M,
    BIT_P,
    BIT_R,
    BIT_T1,
    BIT_T2,
    FINGER_BITS,
    NON_THUMB_BITS,
    ChordCostModel,
    popcount,
    valid_masks,
)


class TestValidMasks(unittest.TestCase):
    """Verify the set of usable chord masks."""

    def test_count(self) -> None:
        """There should be exactly 47 valid masks."""
        self.assertEqual(len(valid_masks()), 47)

    def test_no_both_thumbs(self) -> None:
        """No mask should have both T1 and T2 set."""
        for mask in valid_masks():
            with self.subTest(mask=mask):
                self.assertFalse(
                    (mask & BIT_T1 != 0) and (mask & BIT_T2 != 0),
                    f"mask {mask} ({mask:06b}) uses both thumbs",
                )

    def test_range(self) -> None:
        """All masks should be in [1, 63]."""
        for mask in valid_masks():
            self.assertGreaterEqual(mask, 1)
            self.assertLessEqual(mask, 63)


class TestChordCost(unittest.TestCase):
    """Test chord_cost() properties."""

    def setUp(self) -> None:
        self.model = ChordCostModel()

    def test_all_costs_positive(self) -> None:
        """Every valid mask must have a positive cost."""
        for mask in valid_masks():
            with self.subTest(mask=mask):
                self.assertGreater(self.model.chord_cost(mask), 0.0)

    def test_all_costs_finite(self) -> None:
        """Every cost must be finite."""
        for mask in valid_masks():
            with self.subTest(mask=mask):
                self.assertTrue(math.isfinite(self.model.chord_cost(mask)))

    def test_single_finger_cheapest(self) -> None:
        """Single-finger chords should be cheaper than any multi-finger chord."""
        single_masks = [b for b in FINGER_BITS]
        multi_masks = [m for m in valid_masks() if popcount(m) >= 2]
        max_single = max(self.model.chord_cost(m) for m in single_masks)
        min_multi = min(self.model.chord_cost(m) for m in multi_masks)
        self.assertLess(max_single, min_multi)

    def test_thumb_only_cheapest_single(self) -> None:
        """Among single-finger chords, T1 should be the cheapest."""
        costs = {b: self.model.chord_cost(b) for b in FINGER_BITS}
        self.assertEqual(
            min(costs, key=costs.get),  # type: ignore[arg-type]
            BIT_T1,
            f"T1 should be cheapest single-finger chord, got costs: {costs}",
        )

    def test_more_fingers_more_cost(self) -> None:
        """Adding a finger to any chord should increase the cost.

        We test by comparing the cheapest n+1-finger chord against
        the most expensive n-finger chord *of the same non-thumb
        composition* would be complex, so instead we verify the global
        trend: the minimum cost among (n+1)-finger chords is greater
        than the minimum cost among n-finger chords.
        """
        for n in range(1, 5):
            masks_n = [m for m in valid_masks() if popcount(m) == n]
            masks_n1 = [m for m in valid_masks() if popcount(m) == n + 1]
            if not masks_n or not masks_n1:
                continue
            min_n = min(self.model.chord_cost(m) for m in masks_n)
            min_n1 = min(self.model.chord_cost(m) for m in masks_n1)
            with self.subTest(n=n):
                self.assertGreater(
                    min_n1,
                    min_n,
                    f"min cost for {n + 1}-finger chords should exceed "
                    f"min cost for {n}-finger chords",
                )


class TestSpreadPenalty(unittest.TestCase):
    """Verify spread_penalty() logic."""

    def setUp(self) -> None:
        self.model = ChordCostModel()

    def test_single_finger_zero_spread(self) -> None:
        """A single non-thumb finger has zero spread."""
        for b in NON_THUMB_BITS:
            self.assertEqual(self.model.spread_penalty(b), 0.0)

    def test_thumb_only_zero_spread(self) -> None:
        """Thumb-only chords have zero spread."""
        self.assertEqual(self.model.spread_penalty(BIT_T1), 0.0)
        self.assertEqual(self.model.spread_penalty(BIT_T2), 0.0)

    def test_adjacent_fingers_spread_one(self) -> None:
        """Adjacent non-thumb fingers should have spread 1."""
        self.assertEqual(self.model.spread_penalty(BIT_R | BIT_M), 1.0)
        self.assertEqual(self.model.spread_penalty(BIT_M | BIT_I), 1.0)
        self.assertEqual(self.model.spread_penalty(BIT_P | BIT_R), 1.0)

    def test_pinky_index_spread_three(self) -> None:
        """P + I should have spread 3 (maximum)."""
        self.assertEqual(self.model.spread_penalty(BIT_P | BIT_I), 3.0)

    def test_thumb_does_not_affect_spread(self) -> None:
        """Adding a thumb should not change the spread penalty."""
        base = BIT_R | BIT_I
        self.assertEqual(
            self.model.spread_penalty(base),
            self.model.spread_penalty(base | BIT_T1),
        )


class TestTransitionCost(unittest.TestCase):
    """Test transition_cost() properties."""

    def setUp(self) -> None:
        self.model = ChordCostModel()

    def test_shared_fingers_increase_cost(self) -> None:
        """Transition with shared non-thumb fingers costs more than without."""
        # Same chord → all non-thumb fingers are shared.
        mask = BIT_I | BIT_M
        cost_same = self.model.transition_cost(mask, mask)
        # Disjoint non-thumb fingers.
        cost_disjoint = self.model.transition_cost(BIT_I, BIT_P)
        self.assertGreater(cost_same, cost_disjoint)

    def test_thumb_sharing_ignored(self) -> None:
        """Shared thumb keys should NOT increase the shared-finger count."""
        cost_a = self.model.transition_cost(BIT_T1, BIT_T1)
        cost_b = self.model.transition_cost(BIT_T1, BIT_I)
        # Both have popcount(mask_a)=1, no shared non-thumb fingers → equal.
        self.assertEqual(cost_a, cost_b)

    def test_more_keys_higher_release(self) -> None:
        """A chord with more keys should have a higher release cost."""
        cost_1key = self.model.transition_cost(BIT_I, BIT_M)
        cost_3key = self.model.transition_cost(BIT_I | BIT_M | BIT_R, BIT_M)
        self.assertGreater(cost_3key, cost_1key)


class TestRankedMasks(unittest.TestCase):
    """Test ranked_masks() output."""

    def setUp(self) -> None:
        self.model = ChordCostModel()

    def test_length(self) -> None:
        """ranked_masks() should return all 47 valid masks."""
        self.assertEqual(len(self.model.ranked_masks()), 47)

    def test_sorted_ascending(self) -> None:
        """Masks should be in non-decreasing cost order."""
        ranked = self.model.ranked_masks()
        costs = [self.model.chord_cost(m) for m in ranked]
        for i in range(len(costs) - 1):
            self.assertLessEqual(
                costs[i],
                costs[i + 1],
                f"cost[{i}] ({costs[i]}) > cost[{i+1}] ({costs[i+1]})",
            )

    def test_no_duplicates(self) -> None:
        """No mask should appear twice."""
        ranked = self.model.ranked_masks()
        self.assertEqual(len(ranked), len(set(ranked)))


if __name__ == "__main__":
    unittest.main()
