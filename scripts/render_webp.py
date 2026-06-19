#!/usr/bin/env python3

from pathlib import Path
import argparse
import json
import re
import shutil
import subprocess
import sys


def load_allowed(path: Path):
    apps = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        apps.append(line)
    return apps


def load_variants(path: Path | None):
    if path is None or not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def sanitize_filename(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-zA-Z0-9._-]+", "_", value)
    value = re.sub(r"_+", "_", value)
    return value.strip("_") or "default"


def stringify_value(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return ""
    return str(value)


def find_star_file(app_dir: Path, app_name: str):
    preferred = app_dir / f"{app_name}.star"
    if preferred.exists():
        return preferred

    for candidate in ["main.star", "app.star"]:
        p = app_dir / candidate
        if p.exists():
            return p

    root_stars = sorted(app_dir.glob("*.star"))
    if root_stars:
        return root_stars[0]

    recursive_stars = sorted(app_dir.rglob("*.star"))
    if recursive_stars:
        return recursive_stars[0]

    return None


def render_variant(pixlet_cmd: str, star_file: Path, config: dict, is_2x: bool = False):
    cmd = [pixlet_cmd, "render"]

    if is_2x:
        cmd.append("-2")

    cmd.append(star_file.name)

    for key, value in (config or {}).items():
        rendered = stringify_value(value)
        if rendered == "":
            continue
        cmd.append(f"{key}={rendered}")

    print(f"[CMD] {' '.join(cmd)}")
    subprocess.run(cmd, cwd=star_file.parent, check=True)

    if is_2x:
        expected_webp = star_file.with_name(f"{star_file.stem}@2x.webp")
    else:
        expected_webp = star_file.with_suffix(".webp")

    if not expected_webp.exists():
        raise FileNotFoundError(f"Expected rendered file not found: {expected_webp}")

    return expected_webp


def main():
    parser = argparse.ArgumentParser(description="Render allowed Tronbyt apps to WEBP with variants and metadata.")
    parser.add_argument("--community", required=True, help="Path to cloned apps root, e.g. apps/apps")
    parser.add_argument("--allowed", required=True, help="Path to allowed_apps.txt")
    parser.add_argument("--output", required=True, help="Output folder for rendered WEBP files")
    parser.add_argument("--variants", required=False, help="Path to render_variants.json")
    parser.add_argument("--pixlet", default="pixlet", help="Pixlet executable name/path")
    parser.add_argument("--continue-on-error", action="store_true", help="Continue rendering other apps/variants if one fails")
    args = parser.parse_args()

    community_root = Path(args.community).resolve()
    allowed_file = Path(args.allowed).resolve()
    output_root = Path(args.output).resolve()
    variants_file = Path(args.variants).resolve() if args.variants else None

    output_root.mkdir(parents=True, exist_ok=True)

    allowed_apps = load_allowed(allowed_file)
    variants_map = load_variants(variants_file)

    if not allowed_apps:
        print("No allowed apps found.")
        return 0

    failures = []
    metadata = {}

    for app_name in allowed_apps:
        app_dir = community_root / app_name

        if not app_dir.exists():
            print(f"[WARN] App directory not found: {app_dir}")
            failures.append((app_name, "directory_not_found"))
            if not args.continue_on_error:
                break
            continue

        star_file = find_star_file(app_dir, app_name)
        if not star_file:
            print(f"[WARN] No .star file found for app: {app_name}")
            failures.append((app_name, "star_not_found"))
            if not args.continue_on_error:
                break
            continue

        app_output_dir = output_root / app_name
        app_output_dir.mkdir(parents=True, exist_ok=True)
        metadata[app_name] = []

        app_variants = variants_map.get(app_name, [])

        # ALWAYS render the two defaults first
        render_queue = [
            {
                "name": "default",
                "config": {},
                "is_2x": False
            },
            {
                "name": "default_2x",
                "config": {},
                "is_2x": True
            }
        ]

        # Then add user-defined variants
        for variant in app_variants:
            variant_name = sanitize_filename(variant.get("name", "default"))
            is_2x = bool(variant.get("is_2x", False))
            config = variant.get("config", {}) or {}

            # Avoid collisions with reserved built-in default names
            if variant_name in {"default", "default_2x"}:
                continue

            render_queue.append({
                "name": variant_name,
                "config": config,
                "is_2x": is_2x
            })

        for item in render_queue:
            variant_name = item["name"]
            config = item["config"]
            is_2x = item["is_2x"]

            try:
                print(f"[INFO] Rendering app={app_name}, variant={variant_name}, is_2x={is_2x}")
                rendered_webp = render_variant(args.pixlet, star_file, config, is_2x=is_2x)

                destination = app_output_dir / f"{variant_name}.webp"
                shutil.copy2(rendered_webp, destination)
                print(f"[OK] Saved {destination}")

                metadata[app_name].append({
                    "name": variant_name,
                    "file": f"output/webp/{app_name}/{variant_name}.webp",
                    "config": config,
                    "is_2x": is_2x
                })

                # cleanup temporary generated file inside cloned apps tree
                rendered_webp.unlink(missing_ok=True)

            except subprocess.CalledProcessError as e:
                print(f"[ERROR] Pixlet render failed app={app_name}, variant={variant_name}: {e}")
                failures.append((app_name, variant_name, "render_failed"))
                if not args.continue_on_error:
                    break
            except Exception as e:
                print(f"[ERROR] Unexpected error app={app_name}, variant={variant_name}: {e}")
                failures.append((app_name, variant_name, str(e)))
                if not args.continue_on_error:
                    break

        if failures and not args.continue_on_error:
            break

    index_file = output_root / "index.json"
    index_file.write_text(json.dumps(metadata, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"[OK] Wrote metadata index: {index_file}")

    if failures:
        print("\nRender completed with failures:")
        for item in failures:
            print(" - " + " | ".join(item))
        return 1

    print("\nAll WEBP files rendered successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
