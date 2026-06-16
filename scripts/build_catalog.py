import os
import re
import json
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--community", required=True)
parser.add_argument("--allowed", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

COMMUNITY_APPS = os.path.join(args.community, "apps")
OUTPUT_DIR = args.output

os.makedirs(f"{OUTPUT_DIR}/schemas", exist_ok=True)

# ✅ Load allowed apps
with open(args.allowed) as f:
    allowed_apps = [line.strip() for line in f if line.strip()]

catalog = {"apps": []}


# ✅ Type mapping
TYPE_MAP = {
    "Text": "string",
    "Toggle": "boolean",
    "Dropdown": "string",
    "Color": "string"
}


def parse_schema(file_content):
    fields = {}

    pattern = r'schema\.(\w+)\((.*?)\)'

    matches = re.findall(pattern, file_content, re.DOTALL)

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
            if value in ["True", "False"]:
                value = value == "True"
            field["default"] = value

        fields[field_id] = field

    return fields


def extract_star(app):
    star_file = os.path.join(COMMUNITY_APPS, app, f"{app}.star")

    if not os.path.exists(star_file):
        print(f"⚠️ Missing app: {app}")
        return None

    with open(star_file) as f:
        content = f.read()

    if "def get_schema()" not in content:
        raise Exception(f"❌ Schema missing in {app}")

    schema = parse_schema(content)

    return {
        "name": app,
        "configSchema": schema
    }


# ✅ Process apps
for app in allowed_apps:
    try:
        result = extract_star(app)

        if result is None:
            continue

        # write individual schema
        with open(f"{OUTPUT_DIR}/schemas/{app}.json", "w") as f:
            json.dump(result, f, indent=2)

        catalog["apps"].append(result)

    except Exception as e:
        print(f"❌ Error processing {app}: {e}")
        exit(1)


# ✅ Write catalog
with open(f"{OUTPUT_DIR}/catalog.json", "w") as f:
    json.dump(catalog, f, indent=2)

print("✅ Catalog built successfully")
