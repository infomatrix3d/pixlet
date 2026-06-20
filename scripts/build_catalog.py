import os
import re
import json
import argparse
from pathlib import Path

# ----------------------------
# Arguments
# ----------------------------
parser = argparse.ArgumentParser()
parser.add_argument("--community", required=True, help="Path to community repo root or apps root")
parser.add_argument("--custom", required=False, help="Path to local custom apps root")
parser.add_argument("--allowed", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()


# ----------------------------
# Helpers
# ----------------------------
def resolve_apps_root(raw_path: str | None) -> Path | None:
    if not raw_path:
        return None

    root = Path(raw_path).resolve()

    # Support either:
    # - repo root containing /apps
    # - direct apps root
    nested = root / "apps"
    if nested.is_dir():
        return nested

    return root


COMMUNITY_APPS = resolve_apps_root(args.community)
CUSTOM_APPS = resolve_apps_root(args.custom)
OUTPUT_DIR = Path(args.output).resolve()

(OUTPUT_DIR / "schemas").mkdir(parents=True, exist_ok=True)


# ----------------------------
# Load allowed apps
# ----------------------------
with open(args.allowed, encoding="utf-8") as f:
    allowed_apps = [
        line.strip()
        for line in f
        if line.strip() and not line.strip().startswith("#")
    ]

catalog = {"apps": []}


# ----------------------------
# Type mapping
# ----------------------------
TYPE_MAP = {
    "Text": "string",
    "Toggle": "boolean",
    "Dropdown": "string",
    "Color": "string"
}


# ----------------------------
# Parse schema
# ----------------------------
def parse_schema(content: str):
    fields = {}

    pattern = r'schema\.(\w+)\((.*?)\)'
    matches = re.findall(pattern, content, re.DOTALL)

    for field_type, args_block in matches:
        id_match = re.search(r'id\s*=\s*"([^"]+)"', args_block)
        name_match = re.search(r'name\s*=\s*"([^"]+)"', args_block)
        desc_match = re.search(r'desc\s*=\s*"([^"]+)"', args_block)
        default_match = re.search(r'default\s*=\s*([^,\n]+)', args_block)

        if not id_match:
            continue

        field_id = id_match.group(1)

        field = {
            "type": TYPE_MAP.get(field_type, "string")
        }

        if name_match:
            field["label"] = name_match.group(1)

        if desc_match:
            field["description"] = desc_match.group(1)

        if default_match:
            value = default_match.group(1).strip()

            if value == "True":
                value = True
            elif value == "False":
                value = False
            else:
                # strip surrounding quotes if present
                value = value.strip('"').strip("'")

            field["default"] = value

        fields[field_id] = field

    return fields


# ----------------------------
# Locate app directory
# ----------------------------
def find_app_dir(app_name: str):
    # Custom takes precedence
    if CUSTOM_APPS:
        custom_path = CUSTOM_APPS / app_name
        if custom_path.is_dir():
            return custom_path, "custom"

    community_path = COMMUNITY_APPS / app_name
    if community_path.is_dir():
        return community_path, "community"

    return None, None


# ----------------------------
# Find .star file
# ----------------------------
def find_star_file(app_dir: Path, app_name: str) -> Path | None:
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


# ----------------------------
# Extract schema from .star
# ----------------------------
def extract_star(app_name: str):
    app_dir, source = find_app_dir(app_name)

    if not app_dir:
        raise Exception(f"App '{app_name}' not found in custom or community sources")

    star_file = find_star_file(app_dir, app_name)
    if not star_file:
        raise Exception(f"No .star file found for '{app_name}'")

    print(f"   ↳ source: {source}")
    print(f"   ↳ using star file: {star_file.name}")

    content = star_file.read_text(encoding="utf-8")

    if "def get_schema()" not in content:
        raise Exception(f"Schema missing in '{app_name}'")

    schema = parse_schema(content)

    return {
        "name": app_name,
        "configSchema": schema
    }


# ----------------------------
# Process apps
# ----------------------------
for app in allowed_apps:
    print(f"➡️ Processing app: {app}")

    try:
        result = extract_star(app)

        schema_path = OUTPUT_DIR / "schemas" / f"{app}.json"
        schema_path.write_text(json.dumps(result, indent=2), encoding="utf-8")

        catalog["apps"].append(result)

    except Exception as e:
        print(f"❌ Skipping '{app}': {e}")
        continue


# ----------------------------
# Write catalog
# ----------------------------
catalog_path = OUTPUT_DIR / "catalog.json"
catalog_path.write_text(json.dumps(catalog, indent=2), encoding="utf-8")

print("\n✅ Catalog build complete")
print(f"✅ Apps processed: {len(catalog['apps'])}")
