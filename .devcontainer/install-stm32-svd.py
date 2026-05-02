#!/usr/bin/env python3

import argparse
import json
import shutil
import tempfile
import xml.etree.ElementTree as ET
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urljoin
from urllib.request import urlopen


INDEX_URL = "https://www.keil.com/pack/index.pidx"


def fetch_index() -> list[dict[str, str]]:
    with urlopen(INDEX_URL, timeout=60) as response:
        root = ET.parse(response).getroot()

    packages: list[dict[str, str]] = []
    for pdsc in root.findall(".//pdsc"):
        vendor = (pdsc.get("vendor") or "").strip()
        name = (pdsc.get("name") or "").strip()
        version = (pdsc.get("version") or "").strip()
        base_url = (pdsc.get("url") or "").strip()

        if vendor != "Keil":
            continue
        if not name.startswith("STM32") or not name.endswith("_DFP"):
            continue
        if not version or not base_url:
            continue

        packages.append(
            {
                "vendor": vendor,
                "name": name,
                "version": version,
                "base_url": base_url,
                "pack_url": urljoin(base_url, f"{vendor}.{name}.{version}.pack"),
            }
        )

    if not packages:
        raise RuntimeError("Keil STM32 DFP index returned no packages")

    return sorted(packages, key=lambda package: package["name"])


def download_file(url: str, destination: Path) -> None:
    with urlopen(url, timeout=120) as response, destination.open("wb") as output:
        shutil.copyfileobj(response, output)


def normalize_text(raw: bytes) -> str:
    text = raw.decode("utf-8-sig", errors="ignore")
    return "\n".join(line.rstrip() for line in text.splitlines()) + "\n"


def normalize_member_path(member: str) -> Path:
    relative = Path(*Path(member).parts)
    if relative.is_absolute() or ".." in relative.parts:
        raise RuntimeError(f"Unsafe archive path: {member}")
    return relative


def install_svds(destination: Path) -> None:
    packages = fetch_index()
    destination = destination.resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)

    staging_root = Path(tempfile.mkdtemp(prefix="stm32-svd."))
    staging_dir = staging_root / destination.name
    staging_dir.mkdir(parents=True, exist_ok=True)

    manifest_entries: list[dict] = []
    total_files = 0

    try:
        for package in packages:
            name = package["name"]
            version = package["version"]
            url = package["pack_url"]
            pack_path = staging_root / f"{name}.{version}.pack"

            print(f"Downloading {name} {version} from Keil...")
            download_file(url, pack_path)

            installed_files: list[str] = []
            with zipfile.ZipFile(pack_path) as archive:
                svd_members = sorted(name for name in archive.namelist() if name.lower().endswith(".svd"))
                if not svd_members:
                    print(f"Skipping {name}: pack contained no SVD files")
                    continue

                package_dir = staging_dir / name
                package_dir.mkdir(parents=True, exist_ok=True)

                for member in svd_members:
                    normalized = normalize_text(archive.read(member))
                    relative_path = normalize_member_path(member)
                    target = package_dir / relative_path
                    target.parent.mkdir(parents=True, exist_ok=True)

                    if target.exists():
                        existing = target.read_text(encoding="utf-8", errors="ignore")
                        if existing != normalized:
                            raise RuntimeError(f"Conflicting SVD contents for {name}/{relative_path.as_posix()}")
                    else:
                        target.write_text(normalized, encoding="utf-8")
                        total_files += 1

                    installed_files.append(f"{name}/{relative_path.as_posix()}")

            manifest_entries.append(
                {
                    "name": name,
                    "version": version,
                    "source_url": url,
                    "files": installed_files,
                }
            )

        manifest = {
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "index_url": INDEX_URL,
            "packages": manifest_entries,
            "file_count": total_files,
        }
        (staging_dir / ".manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")

        if destination.exists():
            shutil.rmtree(destination)
        staging_dir.rename(destination)
    finally:
        shutil.rmtree(staging_root, ignore_errors=True)

    print(f"Installed {total_files} STM32 SVD files from Keil packs to {destination}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Install STM32 SVD files from Keil CMSIS packs.")
    parser.add_argument("--dest", default="/opt/st/stm32-svd", help="Destination directory for normalized SVD files")
    args = parser.parse_args()

    install_svds(Path(args.dest))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())