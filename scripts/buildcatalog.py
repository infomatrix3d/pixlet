import os
import re
import json
import argparse

# ----------------------------
# Arguments
# ----------------------------
parser = argparse.ArgumentParser()
parser.add_argument("--community", required=True)
parser.add_argument("--allowed", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

COMMUNITY_APPS = os.path.join(args.community, "apps")
OUTPUT_DIR = args.output

os.makedirs(f"{OUTPUT_DIR}/schemas", exist_ok=True)

# ----------------------------
# Load allowed apps
# ----------------------------
with open(args.allowed) as f:
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
def parse_schema(content):
    fields = {}

    pattern = r'schema\.(\w+)\((.*?)\)'
    matches = re.findall(pattern, content, re.DOTALL)

    for field_type, args in matches:
        id_match = re.search(r'id\s*=\s*"([^"]+)"', args)
        name_match = re.search(r'name\s*=\s*"([^"]+)"', args)
        desc_match = re.search(r'desc\s*=\s*"([^"]+)"', args)
        default_match = re.search(r'default\s*=\s*([^,\n]+)', args)

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

            field["default"] = value

        fields[field_id] = field

    return fields

# ----------------------------
# Extract star file
# ----------------------------
def extract_star(app):
    app_path = os.path.join(COMMUNITY_APPS, app)

    # ✅ validate folder exists
    if not os.path.exists(app_path):
        raise Exception(f"App '{app}' not found")

    # ✅ find ANY .star file (FIX for Tronbyt repo)
    star_files = [f for f in os.listdir(app_path) if f.endswith(".star")]

    if not star_files:
        raise Exception(f"No .star file found for '{app}'")

    # ✅ choose first .star file
    star_file = os.path.join(app_path, star_files[0])

    print(f"   ↳ using star file: {star_files[0]}")

    with open(star_file) as f:
        content = f.read()

    # ✅ enforce schema existence
    if "def get_schema()" not in content:
        raise Exception(f"Schema missing in '{app}'")

    schema = parse_schema(content)

    return {
        "name": app,
        "configSchema": schema
    }

# ----------------------------
# Process apps
# ----------------------------
for app in allowed_apps:
    print(f"➡️ Processing app: {app}")

    try:
        result = extract_star(app)

        # ✅ write schema file per app
        with open(f"{OUTPUT_DIR}/schemas/{app}.json", "w") as f:
            json.dump(result, f, indent=2)

        catalog["apps"].append(result)

    except Exception as e:
        print(f"❌ Skipping '{app}': {e}")
        continue

# ----------------------------
# Write catalog
# ----------------------------
with open(f"{OUTPUT_DIR}/catalog.json", "w") as f:
    json.dump(catalog, f, indent=2)

print("\n✅ Catalog build complete")
print(f"✅ Apps processed: {len(catalog['apps'])}")
