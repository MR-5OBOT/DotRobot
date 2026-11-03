import unittest
import sys
import os

# Add .config/tmux to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../.config/tmux")))

import nav_list

class TestNavList(unittest.TestCase):
    def test_parse_windows(self):
        raw_output = (
            "1|opencode|0|2|/home/mr5obot|-\n"
            "2|l3omal|0|1|/home/mr5obot/Desktop|\n"
            "3|claude|1|1|/home/mr5obot|*\n"
        )
        items = nav_list.parse_windows(raw_output)
        self.assertEqual(len(items), 3)
        self.assertEqual(items[0]["index"], "1")
        self.assertEqual(items[0]["name"], "opencode")
        self.assertFalse(items[0]["active"])
        self.assertEqual(items[0]["panes"], "2")
        self.assertEqual(items[0]["path"], "~")
        
        self.assertEqual(items[2]["index"], "3")
        self.assertEqual(items[2]["name"], "claude")
        self.assertTrue(items[2]["active"])

    def test_parse_sessions(self):
        raw_output = "0|1|3|/home/mr5obot\nwork|0|2|/home/mr5obot/work\n"
        items = nav_list.parse_sessions(raw_output)
        self.assertEqual(len(items), 2)
        self.assertEqual(items[0]["name"], "0")
        self.assertTrue(items[0]["active"])
        self.assertEqual(items[0]["windows"], "3")
        self.assertEqual(items[1]["name"], "work")
        self.assertFalse(items[1]["active"])

    def test_fit_path(self):
        self.assertEqual(nav_list.fit_path("~/short", 20), "~/short")
        self.assertEqual(nav_list.fit_path("~/a/very/long/path/to/something/nested", 15), "...thing/nested")

    def test_scroll_offset(self):
        # selected 0, total 10, rows 5 -> offset 0
        self.assertEqual(nav_list.calc_scroll(selected=0, offset=0, rows=5), 0)
        # selected moves down to 5 -> offset becomes 1 (5 - 5 + 1)
        self.assertEqual(nav_list.calc_scroll(selected=5, offset=0, rows=5), 1)
        # selected moves back up to 0 -> offset becomes 0
        self.assertEqual(nav_list.calc_scroll(selected=0, offset=3, rows=5), 0)

if __name__ == "__main__":
    unittest.main()
