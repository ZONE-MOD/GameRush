#!/usr/bin/env python3
"""Merge base_patch.json and patch_*.json into one deployable catalog."""
import argparse, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATCH_DIR = ROOT / "graphics" / "skin_patches"

def merge_by_id(target, incoming):
    for item in incoming:
        if not isinstance(item, dict) or not item.get("id"):
            continue
        existing = next((i for i, old in enumerate(target) if old.get("id") == item["id"]), None)
        if existing is None:
            target.append(item)
        else:
            target[existing] = item

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default=str(ROOT / "build" / "web" / "patches" / "catalog.json"))
    args = parser.parse_args()
    files = [PATCH_DIR / "base_patch.json"] + sorted(PATCH_DIR.glob("patch_*.json"))
    catalog = {"schema_version": 1, "patches": [], "skins": [], "helmets": []}
    for path in files:
        if not path.exists():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        if data.get("schema_version") != 1:
            raise SystemExit(f"Unsupported patch schema in {path.name}")
        patch_id = data.get("patch_id", path.stem)
        catalog["patches"].append(patch_id)
        merge_by_id(catalog["skins"], data.get("skins", []))
        merge_by_id(catalog["helmets"], data.get("helmets", []))
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Built {out}: {len(catalog['skins'])} skins, {len(catalog['helmets'])} helmets, {len(catalog['patches'])} patches")

if __name__ == "__main__":
    main()
