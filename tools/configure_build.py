#!/usr/bin/env python3
"""Set the Pages patch catalog URL for this CI build without committing it."""
import json, os
from pathlib import Path
root = Path(__file__).resolve().parents[1]
repo = os.environ.get("GITHUB_REPOSITORY", "")
config_path = root / "config" / "game_config.json"
config = json.loads(config_path.read_text(encoding="utf-8"))
if repo:
    owner, name = repo.split("/", 1)
    if name.lower() == f"{owner.lower()}.github.io":
        base = f"https://{owner}.github.io"
    else:
        base = f"https://{owner}.github.io/{name}"
    config["patch_catalog_url"] = base.rstrip("/") + "/patches/catalog.json"
config_path.write_text(json.dumps(config, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("Configured patch catalog URL:", config.get("patch_catalog_url"))
