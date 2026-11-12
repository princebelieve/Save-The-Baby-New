"""Verify release content, native alignment, and APK/AAB content parity."""
import argparse
import hashlib
import json
import re
import struct
import subprocess
import zipfile
from pathlib import Path


def check(bundle: Path, apk: Path, root: Path, aapt2: Path | None = None):
    report = {"artifacts": {}, "native_alignment": [], "json_files_verified": 0}
    with zipfile.ZipFile(bundle) as aab, zipfile.ZipFile(apk) as application:
        bundle_assets = {name.split("/assets/", 1)[1]: name for name in aab.namelist() if "/assets/" in name and not name.endswith("/")}
        for path, archive, prefix in [(bundle, aab, "base/"), (apk, application, "")]:
            names = archive.namelist()
            assert not any("/assets/tests/" in "/" + name or name.endswith(".jks") or "/assets/server/" in "/" + name for name in names), "Private/development content in release"
            report["artifacts"][path.name] = {"bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
            for name in names:
                if name.startswith(prefix + "lib/arm64-v8a/") and name.endswith(".so"):
                    data = archive.read(name)
                    assert data[:5] == b"\x7fELF\x02"
                    offset = struct.unpack_from("<Q", data, 32)[0]
                    size, count = struct.unpack_from("<HH", data, 54)
                    alignments = []
                    for index in range(count):
                        header = struct.unpack_from("<IIQQQQQQ", data, offset + index * size)
                        if header[0] == 1:
                            assert header[7] >= 16384, f"16KB segment alignment missing: {name}"
                            alignments.append(header[7])
                    report["native_alignment"].append({"artifact": path.name, "library": name, "load_alignments": alignments})
        for name in aab.namelist():
            if name.startswith("base/lib/") and name.endswith(".so"):
                assert aab.read(name) == application.read(name.removeprefix("base/")), f"APK/AAB native library mismatch: {name}"
        for folder in ["levels", "stories", "configs"]:
            for source in (root / folder).rglob("*.json"):
                relative = source.relative_to(root).as_posix()
                name = "assets/" + relative
                assert aab.read(bundle_assets[relative]) == source.read_bytes(), f"AAB content mismatch: {relative}"
                assert application.read(name) == source.read_bytes(), f"APK content mismatch: {relative}"
                report["json_files_verified"] += 1
        aab_assets = {"assets/" + name: entry for name, entry in bundle_assets.items()}
        apk_assets = {name for name in application.namelist() if name.startswith("assets/")}
        # AGP packages APK runtime profiles separately from bundle metadata.
        apk_assets -= {"assets/dexopt/baseline.prof", "assets/dexopt/baseline.profm"}
        assert set(aab_assets) == apk_assets, "APK/AAB asset lists differ"
        for name, bundle_name in aab_assets.items():
            assert aab.getinfo(bundle_name).CRC == application.getinfo(name).CRC, f"APK/AAB asset mismatch: {name}"
        report["matching_asset_count"] = len(aab_assets)
    if aapt2:
        badging = subprocess.run([str(aapt2), "dump", "badging", str(apk)], check=True, capture_output=True, text=True).stdout
        version = int(re.search(r"version/code=(\d+)", (root / "export_presets.cfg").read_text()).group(1))
        assert f"name='com.savethebaby.game' versionCode='{version}'" in badging
        assert "targetSdkVersion:'36'" in badging and "minSdkVersion:'24'" in badging
        assert not re.search(r"^\s*uses-feature: name='android.hardware.vulkan", badging, re.M), "Required Vulkan would exclude older phones"
        report["manifest"] = {"package": "com.savethebaby.game", "version_code": version, "target_sdk": 36, "min_sdk": 24, "vulkan_required": False}
    output = bundle.with_name(bundle.stem + "-content-verification.json")
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Verified {report['json_files_verified']} source JSON files, {report['matching_asset_count']} matching assets, ARM64 ELF alignment; report: {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--aapt2", type=Path)
    args = parser.parse_args()
    check(args.bundle, args.apk, Path(__file__).resolve().parent.parent, args.aapt2)
