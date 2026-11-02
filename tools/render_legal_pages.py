from html import escape
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
LEGAL_SOURCE = ROOT / "legal"
OUTPUT = ROOT / "docs" / "legal"


def inline_markup(value: str) -> str:
    value = escape(value, quote=True)
    value = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", value)
    value = re.sub(
        r"(?<![\w/])([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})",
        r'<a href="mailto:\1">\1</a>',
        value,
        flags=re.IGNORECASE,
    )
    value = re.sub(
        r"(https://sbi\.globalcreest\.com)",
        r'<a href="\1">\1</a>',
        value,
        flags=re.IGNORECASE,
    )
    return value


def render_body(markdown: str) -> tuple[str, str]:
    title = "Legal Information"
    blocks: list[str] = []
    paragraph: list[str] = []
    in_list = False

    def close_paragraph() -> None:
        if paragraph:
            blocks.append(f"<p>{inline_markup(' '.join(paragraph))}</p>")
            paragraph.clear()

    def close_list() -> None:
        nonlocal in_list
        if in_list:
            blocks.append("</ul>")
            in_list = False

    for raw_line in markdown.splitlines():
        line = raw_line.strip()
        if not line:
            close_paragraph()
            close_list()
            continue

        heading = re.match(r"^(#{1,3})\s+(.+)$", line)
        if heading:
            close_paragraph()
            close_list()
            level = len(heading.group(1))
            heading_text = heading.group(2).strip()
            if level == 1:
                title = re.sub(r"\*\*", "", heading_text)
            blocks.append(f"<h{level}>{inline_markup(heading_text)}</h{level}>")
            continue

        bullet = re.match(r"^-\s+(.+)$", line)
        if bullet:
            close_paragraph()
            if not in_list:
                blocks.append("<ul>")
                in_list = True
            blocks.append(f"<li>{inline_markup(bullet.group(1))}</li>")
            continue

        close_list()
        paragraph.append(line)

    close_paragraph()
    close_list()
    return title, "\n".join(blocks)


def render_page(title: str, body: str, canonical_url: str, page_label: str) -> str:
    return f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light">
  <title>{escape(title)} | Save The Baby</title>
  <link rel="canonical" href="{escape(canonical_url, quote=True)}">
  <style>
    :root {{ color-scheme: light; font-family: system-ui, -apple-system, "Segoe UI", sans-serif; color: #183047; background: #f4f1e8; }}
    body {{ margin: 0; padding: 2rem 1rem; }}
    main {{ box-sizing: border-box; max-width: 52rem; margin: 0 auto; padding: clamp(1.25rem, 5vw, 3rem); background: #fffdf8; border: 1px solid #d9d1bf; border-radius: 1rem; box-shadow: 0 1rem 3rem #18304712; }}
    h1, h2, h3 {{ line-height: 1.25; color: #122b43; }}
    h1 {{ margin-top: 0; font-size: clamp(1.8rem, 5vw, 2.5rem); }}
    h2 {{ margin-top: 2rem; padding-bottom: .35rem; border-bottom: 1px solid #e7dfcf; font-size: 1.25rem; }}
    p, li {{ line-height: 1.7; }}
    a {{ color: #155b83; }}
    .site-context {{ max-width: 52rem; margin: 0 auto 1rem; color: #596875; font-size: .9rem; }}
    footer {{ max-width: 52rem; margin: 1rem auto 0; color: #596875; font-size: .9rem; }}
  </style>
</head>
<body>
  <p class="site-context"><a href="https://sbi.globalcreest.com/">S. B. Ibhadode Technologies</a> / <a href="https://sbi.globalcreest.com/save-the-baby">Save The Baby</a> / {escape(page_label)}</p>
  <main>
{body}
  </main>
  <footer>Save The Baby legal information · Published by S. B. Ibhadode Technologies · <a href="https://sbi.globalcreest.com/save-the-baby">Save The Baby home</a> · <a href="https://sbi.globalcreest.com/">Company website</a> · <a href="mailto:info@sbi.globalcreest.com">info@sbi.globalcreest.com</a></footer>
</body>
</html>
'''


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    pages = {
        "privacy_policy.md": (
            "privacy-policy.html",
            "https://sbi.globalcreest.com/save-the-baby/privacy-policy",
            "Privacy Policy",
        ),
        "terms_and_conditions.md": (
            "terms-and-conditions.html",
            "https://sbi.globalcreest.com/save-the-baby/terms-and-conditions",
            "Terms and Conditions",
        ),
    }
    for source_name, (output_name, canonical_url, page_label) in pages.items():
        source = LEGAL_SOURCE / source_name
        title, body = render_body(source.read_text(encoding="utf-8"))
        with (OUTPUT / output_name).open("w", encoding="utf-8", newline="\n") as page:
            page.write(render_page(title, body, canonical_url, page_label))


if __name__ == "__main__":
    main()
