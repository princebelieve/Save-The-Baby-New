"""Validate teaching order and authored mission constraints as content grows."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class AcademyContentChecks(unittest.TestCase):
    def test_journal_titles_and_art_stay_consistent(self):
        curriculum = json.loads((ROOT / "configs/academy.json").read_text(encoding="utf-8"))
        identities = {}
        for lesson in curriculum["lessons"]:
            self.assertEqual(len(lesson["journal_pages"]), len(lesson["pages"]))
            for fact in lesson["journal_pages"]:
                if not fact:
                    continue
                identity = (fact["title"], fact["illustration"])
                self.assertEqual(identities.setdefault(fact["id"], identity), identity, "One skill must keep the same title and illustration across lessons")
                self.assertTrue(fact["fact"])
                self.assertTrue((ROOT / fact["illustration"].removeprefix("res://")).is_file())

    def test_teach_before_use(self):
        curriculum = json.loads((ROOT / "configs/academy.json").read_text())
        introductions = {lesson["id"]: lesson["level"] for lesson in curriculum["lessons"]}
        obstacle_lessons = {"chain": "chain", "lock": "lock", "bomb": "hazard", "electric_trap": "electric"}
        for path in sorted((ROOT / "levels").glob("level*.json")):
            level = json.loads(path.read_text())
            number = level["level_id"]
            with self.subTest(level=number):
                for kind in level["powerups"]["available"]:
                    self.assertGreaterEqual(number, introductions[kind.lower()])
                for kind in level["settings"].get("available_boosters", []):
                    self.assertGreaterEqual(number, introductions["characters" if kind == "ethan" else kind])
                for obstacle in level["obstacles"]["items"]:
                    self.assertGreaterEqual(number, introductions[obstacle_lessons[obstacle["type"]]])
                for kind in ["ethan", "detective", "victor"]:
                    if kind in level["tile_pool"]["tiles"]:
                        self.assertGreaterEqual(number, introductions["characters"])
                self.assertGreaterEqual(level["objectives"][0]["amount"], 18)
                self.assertGreaterEqual(level["moves"]["total"], 20)
                self.assertNotEqual(level["difficulty"], "EXTREMELY_EASY")
                pool = level["tile_pool"]
                evidence_weights = [weight for tile, weight in zip(pool["tiles"], pool["weights"]) if tile in ["key", "phone", "fingerprint", "recorder", "clock"]]
                self.assertEqual(len(set(evidence_weights)), 1, "Goal evidence must not receive a hidden spawn advantage")

    def test_chapters_keep_all_approaches(self):
        for path in sorted((ROOT / "stories").glob("chapter*.json")):
            story = json.loads(path.read_text())
            with self.subTest(story=path.name):
                scene = story["scenes"][0]
                self.assertEqual({choice["id"] for choice in scene["choices"]}, {"alone", "police", "signal"})
                self.assertEqual(set(scene["route_dialogues"]), {"alone", "police", "signal"})
                for choice in scene["choices"]:
                    self.assertTrue(choice["impact"])
                    self.assertTrue(choice["response"])


if __name__ == "__main__":
    unittest.main()
