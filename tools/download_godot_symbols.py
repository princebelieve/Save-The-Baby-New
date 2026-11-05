"""Prepare official Android symbols for the ABIs in the existing Play bundle."""
import concurrent.futures
import json
import struct
import threading
import time
import urllib.request
import zipfile
from pathlib import Path
from verify_play_symbols import verify

WORKSPACE = Path(__file__).resolve().parents[1]
ROOT = WORKSPACE / "build/android/symbols"
BUNDLE = WORKSPACE / "build/android/SaveTheBaby.aab"
NAME = "Godot_native_debug_symbols.4.6.3.stable.template_release.android.zip"
API = "https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.6.3-stable"
HEADERS = {"User-Agent": "SaveTheBaby-ReleaseSymbols"}


def request_range(url, start, end, total):
    request = urllib.request.Request(url, headers={**HEADERS, "Range": f"bytes={start}-{end}"})
    response = urllib.request.urlopen(request, timeout=90)
    if response.status != 206 or response.headers.get("Content-Range") != f"bytes {start}-{end}/{total}":
        response.close()
        raise RuntimeError("Server did not return the exact requested byte range")
    return response


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    target = ROOT / "native-debug-symbols-v2.zip"
    receipt = ROOT / "verification-v2.json"
    if target.exists() and receipt.exists():
        previous = json.loads(receipt.read_text(encoding="utf-8"))
        current = verify(BUNDLE, target)
        if current["symbols_sha256"] != previous["symbols_sha256"]:
            raise RuntimeError("Existing symbols differ from the verified download receipt")
        previous.update(current)
        receipt.write_text(json.dumps(previous, indent=2) + "\n", encoding="utf-8")
        print(f"Already downloaded; all bundle build IDs verified: {target}", flush=True)
        return
    with zipfile.ZipFile(BUNDLE) as app:
        abis = {name.split("/")[2] for name in app.namelist() if name.startswith("base/lib/") and name.endswith(".so")}
    with urllib.request.urlopen(urllib.request.Request(API, headers=HEADERS), timeout=40) as response:
        release = json.load(response)
    asset = next(a for a in release["assets"] if a["name"] == NAME)
    total = asset["size"]
    with request_range(asset["browser_download_url"], total - 65536, total - 1, total) as response:
        download_url = response.url
        tail = response.read()
    entries = []
    pos = tail.find(b"PK\x01\x02")
    while pos >= 0 and tail[pos:pos + 4] == b"PK\x01\x02":
        header = struct.unpack_from("<4s6H3I5H2I", tail, pos)
        end = pos + 46 + header[10] + header[11] + header[12]
        name = tail[pos + 46:pos + 46 + header[10]].decode()
        entries.append((name, header[16], tail[pos:end]))
        pos = end
    selected = [entry for entry in entries if entry[0].split("/")[0] in abis]
    if not selected:
        raise RuntimeError("No official symbols match the bundle ABIs")
    last_selected = max(entry[1] for entry in selected)
    after = [entry[1] for entry in entries if entry[1] > last_selected]
    if not after:
        raise RuntimeError("This prefix download requires an archive entry after the selected ABIs")
    prefix_size = min(after)
    original_chunk = (total + 7) // 8
    ranges = []
    tasks = []
    for begin in range(0, prefix_size, original_chunk):
        index = begin // original_chunk
        limit = min(prefix_size, begin + original_chunk)
        cached = ROOT / f"symbols-segment-{index:02d}.part"
        existing = min(cached.stat().st_size, limit - begin) if cached.exists() else 0
        if existing:
            ranges.append((begin, existing, cached))
        start = begin + existing
        while start < limit:
            end = min(limit, start + 8 * 1024 * 1024) - 1
            part = ROOT / f"range-{start:09d}-{end:09d}.part"
            tasks.append((start, end, part))
            ranges.append((start, end - start + 1, part))
            start = end + 1
    lock = threading.Lock()
    completed = [0]

    def fetch(task):
        start, end, part = task
        expected = end - start + 1
        for attempt in range(5):
            existing = part.stat().st_size if part.exists() else 0
            if existing == expected:
                return
            if existing > expected:
                raise RuntimeError("Cached range is too long")
            try:
                with request_range(download_url, start + existing, end, total) as response, part.open("ab") as output:
                    while block := response.read(256 * 1024):
                        output.write(block)
                if part.stat().st_size != expected:
                    raise RuntimeError("Incomplete range")
                with lock:
                    completed[0] += 1
                    print(f"Downloaded range {completed[0]}/{len(tasks)}", flush=True)
                return
            except Exception:
                if attempt == 4:
                    raise
                time.sleep(1)

    print(f"Bundle ABIs: {sorted(abis)}; reusing cached data; fetching {len(tasks)} missing ranges.", flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
        list(executor.map(fetch, tasks))
    target = ROOT / "native-debug-symbols-v2.zip"
    temporary = ROOT / "native-debug-symbols-v2.zip.part"
    with temporary.open("wb") as output:
        cursor = 0
        for start, length, path in sorted(ranges):
            if start != cursor:
                raise RuntimeError("Archive range gap or overlap")
            with path.open("rb") as source:
                remaining = length
                while remaining:
                    block = source.read(min(1024 * 1024, remaining))
                    if not block:
                        raise RuntimeError("Truncated downloaded range")
                    output.write(block)
                    remaining -= len(block)
            cursor += length
        directory = b"".join(entry[2] for entry in selected)
        output.write(directory)
        output.write(struct.pack("<4s4H2IH", b"PK\x05\x06", 0, 0, len(selected), len(selected), len(directory), prefix_size, 0))
    with zipfile.ZipFile(temporary) as archive:
        if archive.testzip() is not None:
            raise RuntimeError("Native symbol archive CRC validation failed")
    report = verify(BUNDLE, temporary)
    temporary.replace(target)
    report["symbols"] = str(target)
    report["official_source"] = asset["browser_download_url"]
    report["official_full_archive_digest"] = asset.get("digest")
    report["validation"] = "Exact official ZIP entries, CRC validation, and ELF build ID matching against the bundle. Repackaged for its ABIs; upload ZIP has its own SHA-256."
    (ROOT / "verification-v2.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    # Only remove this downloader's known cache files after successful verification.
    for path in {item[2] for item in ranges}:
        path.unlink(missing_ok=True)
    for index in range(8):
        (ROOT / f"symbols-segment-{index:02d}.part").unlink(missing_ok=True)
    (ROOT / (NAME + ".part")).unlink(missing_ok=True)
    print(f"READY: {target}", flush=True)
    for item in report["verified"]:
        print(f"BUILD ID MATCH: {item['abi']}/{item['library']}", flush=True)


if __name__ == "__main__":
    main()
