"""Verify official native symbols against the ELF build IDs in an Android bundle."""

import argparse
import hashlib
import json
import struct
import zipfile
from pathlib import Path


def build_id(stream):
    stream.seek(0)
    header = stream.read(64)
    if header[:4] != b"\x7fELF":
        raise ValueError("Symbol entry is not an ELF file")
    elf64 = header[4] == 2
    endian = "<" if header[5] == 1 else ">"
    fields = struct.unpack_from(endian + ("HHIQQQIHHHHHH" if elf64 else "HHIIIIIHHHHHH"), header, 16)
    ph_offset, ph_size, ph_count = fields[4], fields[8], fields[9]
    stream.seek(ph_offset)
    program_headers = stream.read(ph_size * ph_count)
    notes = []
    for index in range(ph_count):
        ph = struct.unpack_from(endian + ("IIQQQQQQ" if elf64 else "IIIIIIII"), program_headers, index * ph_size)
        if ph[0] == 4:  # PT_NOTE: GNU build IDs survive --only-keep-debug.
            notes.append((ph[2] if elf64 else ph[1], ph[5] if elf64 else ph[4]))
    for offset, size in sorted(notes):
        stream.seek(offset)
        data = stream.read(size)
        cursor = 0
        while cursor + 12 <= len(data):
            name_size, desc_size, kind = struct.unpack_from(endian + "III", data, cursor)
            cursor += 12
            name = data[cursor:cursor + name_size].rstrip(b"\0")
            cursor += (name_size + 3) & ~3
            desc = data[cursor:cursor + desc_size]
            cursor += (desc_size + 3) & ~3
            if name == b"GNU" and kind == 3:
                return desc.hex()
    raise ValueError("ELF has no GNU build ID")


def verify(bundle, symbols):
    matches = []
    missing = []
    with zipfile.ZipFile(bundle) as app, zipfile.ZipFile(symbols) as archive:
        entries = archive.namelist()
        for name in app.namelist():
            if not name.startswith("base/lib/") or not name.endswith(".so"):
                continue
            abi, library = name.split("/")[-2:]
            with app.open(name) as stream:
                expected = build_id(stream)
            candidates = [entry for entry in entries if abi in entry.split("/") and
                          (entry.endswith(library) or entry.endswith(library + ".debug") or
                           entry.endswith(library + ".sym"))]
            if not candidates:
                missing.append({"abi": abi, "library": library, "build_id": expected})
                continue
            verified = False
            for entry in candidates:
                with archive.open(entry) as stream:
                    actual = build_id(stream)
                if actual == expected:
                    matches.append({"abi": abi, "library": library, "build_id": expected, "symbol_entry": entry})
                    verified = True
                    break
            if not verified:
                raise ValueError(f"Build ID mismatch for {abi}/{library}")
    if not any(item["library"] == "libgodot_android.so" for item in matches):
        raise ValueError("No matching Godot engine symbols found")
    expected_engines = sum(item["library"] == "libgodot_android.so" for item in matches + missing)
    if sum(item["library"] == "libgodot_android.so" for item in matches) != expected_engines:
        raise ValueError("Missing engine symbols for an ABI shipped in the bundle")
    with symbols.open("rb") as stream:
        symbols_hash = hashlib.file_digest(stream, "sha256").hexdigest()
    with bundle.open("rb") as stream:
        bundle_hash = hashlib.file_digest(stream, "sha256").hexdigest()
    return {"bundle": str(bundle), "bundle_sha256": bundle_hash,
            "symbols": str(symbols), "symbols_sha256": symbols_hash,
            "verified": matches, "not_provided": missing}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path)
    parser.add_argument("symbols", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    report = verify(args.bundle, args.symbols)
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    for match in report["verified"]:
        print(f"MATCH {match['abi']}/{match['library']}: {match['build_id']}")
    for missing in report["not_provided"]:
        print(f"Not included by symbol provider: {missing['abi']}/{missing['library']}")
