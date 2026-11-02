"""Check repository source without displaying matched credential values."""
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATTERNS = {
    "credential-bearing MongoDB URI": re.compile(r"mongodb(?:\+srv)?://[^\s/:<>`\"']+:[^\s@<>`\"']+@[^\s<>`\"']+"),
    "private key": re.compile(r"-----BEGIN (?:RSA |EC )?PRIVATE KEY-----"),
    "Google OAuth secret": re.compile(r"GOCSPX-[A-Za-z0-9_-]{15,}"),
    "Google API key": re.compile(r"AIza[A-Za-z0-9_-]{30,}"),
    "GitHub token": re.compile(r"(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,})"),
}
EXTENSIONS = {".md", ".txt", ".gd", ".js", ".json", ".cfg", ".yaml", ".yml", ".html", ".py", ".ps1", ".log", ".env"}


def main():
    names = subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT).decode().split("\0")
    findings = []
    scanned = 0
    for name in sorted(set(names)):
        path = ROOT / name
        if not name or not path.is_file() or (path.suffix.lower() not in EXTENSIONS and ".env" not in path.name):
            continue
        scanned += 1
        text = path.read_text(encoding="utf-8", errors="replace")
        for label, pattern in PATTERNS.items():
            for match in pattern.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                findings.append(f"{name}:{line}: {label} (value withheld)")
    for finding in findings:
        print(finding)
    print(f"Scanned {scanned} source files; {len(findings)} credential-pattern findings.")
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
