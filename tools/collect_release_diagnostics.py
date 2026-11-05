"""Extract the exact mapping embedded in an AAB and verify its native symbols."""

import argparse
import hashlib
import json
import re
import shutil
import zipfile
from pathlib import Path

from verify_play_symbols import verify


def collect(bundle, symbols):
    prefix = bundle.with_suffix("")
    mapping_path = prefix.with_name(prefix.name + "-mapping.txt")
    report_path = prefix.with_name(prefix.name + "-diagnostics.json")
    with zipfile.ZipFile(bundle) as archive:
        mapping_entry = "BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map"
        mapping = archive.read(mapping_entry)
        text = mapping.decode("utf-8")
        if "# compiler: R8" not in text:
            raise ValueError("Bundle does not contain a real R8-generated mapping")
        renamed = re.findall(r"^([^ #\s][^ ]*) -> ([^: ]+):$", text, re.MULTILINE)
        obfuscated = [(original, final) for original, final in renamed if original != final]
        if not obfuscated:
            raise ValueError("Mapping contains no obfuscated classes")
        required = [
            "org.godotengine.godot.Godot",
            "org.godotengine.godot.GodotLib",
            "com.poingstudios.godot.admob.ads.PoingGodotAdMob",
            "org.godotengine.plugin.googleplaybilling.GodotGooglePlayBilling",
            "com.godot.game.GodotApp",
        ]
        for name in required:
            if f"{name} -> {name}:" not in text:
                raise ValueError(f"R8 did not preserve a required bridge class: {name}")
        levels = [entry for entry in archive.namelist() if "/levels/level" in entry and entry.endswith(".json")]
        daily = [entry for entry in archive.namelist() if entry.endswith("/configs/daily_activities.json")]
        if len(levels) != 1050 or not daily:
            raise ValueError("Bundle is missing the current campaign or daily activities")
        if not any(entry.startswith("META-INF/") and entry.endswith((".RSA", ".EC", ".DSA")) for entry in archive.namelist()):
            raise ValueError("Bundle is not signed")
    mapping_path.write_bytes(mapping)
    report = verify(bundle, symbols)
    report.update({
        "mapping": str(mapping_path), "mapping_embedded": True,
        "mapping_sha256": hashlib.sha256(mapping).hexdigest(),
        "obfuscated_class_count": len(obfuscated), "preserved_bridge_classes": required,
        "level_count": len(levels), "daily_activities_included": True,
    })
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"MAPPING READY: {mapping_path}")
    print(f"R8-obfuscated classes: {len(obfuscated)}; JNI/plugin bridge names preserved.")
    print(f"Verified native libraries: {len(report['verified'])}; campaign files: {len(levels)}.")
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path)
    parser.add_argument("symbols", type=Path)
    args = parser.parse_args()
    collect(args.bundle, args.symbols)
