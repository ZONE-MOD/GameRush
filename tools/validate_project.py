#!/usr/bin/env python3
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
required = [
    "project.godot", "game/main.tscn", "game/main.gd", "game/runner_world.tscn",
    "game/runner_world.gd", "game/player.gd", "game/level_manager.gd",
    "graphics/skin_patches/base_patch.json", "graphics/skin_patch_loader.gd",
    "graphics/skin_patch_service.gd", "audio/audio_manager.gd", "server/api_client.gd", "config/game_config.json"
]
missing = [p for p in required if not (root/p).is_file()]
if missing:
    raise SystemExit("Missing files: " + ", ".join(missing))
for p in ["graphics/skin_patches/base_patch.json", "config/game_config.json"]:
    json.loads((root/p).read_text(encoding="utf-8"))
print("Project structure and core JSON files: OK")
