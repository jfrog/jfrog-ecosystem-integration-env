#!/usr/bin/env python3
"""Update the tool versions pinned in the Dockerfile and README.

Only moves within the current major line (Go: minor line) so a nightly run never
makes a breaking jump. Prints one "- Tool old -> new" line per change.
Tools without a pin (Node.js, Maven, JDK, apt, pip) pick up the latest version
on every image build, so they need no entry here.
"""
import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCKERFILE = ROOT / "Dockerfile"
README = ROOT / "README.md"


def fetch(url):
    with urllib.request.urlopen(url, timeout=30) as resp:
        return resp.read().decode()


def key(version):
    return tuple(int(p) for p in version.split("."))


def latest_go(current):
    line = ".".join(current.split(".")[:2])
    found = [r["version"].removeprefix("go") for r in json.loads(fetch("https://go.dev/dl/?mode=json&include=all"))
             if r.get("stable") and r["version"].removeprefix("go").startswith(line + ".")]
    return max(found, key=key, default=current)


def latest_gradle(current):
    major = current.split(".")[0]
    sdkman = fetch("https://api.sdkman.io/2/candidates/gradle/linuxx64/versions/list?installed=")
    found = []
    for r in json.loads(fetch("https://services.gradle.org/versions/all")):
        v = r["version"]
        if not re.fullmatch(r"\d+\.\d+(\.\d+)?", v) or not v.startswith(major + "."):
            continue
        if r["snapshot"] or r["nightly"] or r["releaseNightly"] or r["activeRc"] or r["broken"] or r["rcFor"] or r["milestoneFor"]:
            continue
        if re.search(rf"(?<![\d.]){re.escape(v)}(?![\d.])", sdkman):  # SDKMAN must carry it
            found.append(v)
    return max(found, key=key, default=current)


def latest_nuget(current):
    major = current.split(".")[0]
    tools = json.loads(fetch("https://dist.nuget.org/tools.json"))["nuget.exe"]
    found = [t["version"] for t in tools
             if t["stage"] == "ReleasedAndBlessed" and re.fullmatch(r"\d+\.\d+\.\d+", t["version"])
             and t["version"].startswith(major + ".")]
    return max(found, key=key, default=current)


# name, Dockerfile regex (group 2 = version), latest(), README row label, README version format
TOOLS = [
    ("Go", r"(go)(\d+\.\d+\.\d+)(\.linux-amd64)", latest_go, "Go", lambda v: ".".join(v.split(".")[:2]) + ".x"),
    ("Gradle", r"(sdk install gradle )(\d+\.\d+(?:\.\d+)?)()", latest_gradle, "Gradle", lambda v: ".".join(v.split(".")[:2]) + ".x"),
    ("NuGet", r"(ARG NUGET_VERSION=)(\d+\.\d+\.\d+)()", latest_nuget, "NuGet", lambda v: ".".join(v.split(".")[:2]) + ".x"),
]


def update_readme(text, label, shown):
    pattern = re.compile(rf"(\|\s*{label}\s*\|)([^|]*)(\|)")
    return pattern.sub(lambda m: f"{m[1]}{(' ' * 5 + shown).ljust(len(m[2]))}{m[3]}", text, count=1)


def main():
    docker = DOCKERFILE.read_text()
    readme = README.read_text()
    for name, regex, latest, label, fmt in TOOLS:
        match = re.search(regex, docker)
        if not match:
            continue
        old = match[2]
        new = latest(old)
        if new == old:
            continue
        docker = docker[:match.start(2)] + new + docker[match.end(2):]
        readme = update_readme(readme, label, fmt(new))
        print(f"- {name} {old} -> {new}")
    DOCKERFILE.write_text(docker)
    README.write_text(readme)


if __name__ == "__main__":
    main()
