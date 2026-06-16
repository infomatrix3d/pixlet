import json
import os
import subprocess
import glob
import shlex

tenant = os.environ["TENANT"]
manifest_path = os.environ.get("MANIFEST", "manifest.json")

print(f"Using manifest: {manifest_path}")
print(f"Tenant: {tenant}")

with open(manifest_path, "r", encoding="utf-8") as f:
    data = json.load(f)

apps = data.get("apps", [])

if not apps:
    print("No enabled apps to render")
    raise SystemExit(0)

def has_placeholder(value):
    if not isinstance(value, str):
        return False
    v = value.strip()
    if not v:
        return True
    if v.endswith(".value") and "[" in v and "]" in v:
        return True
    return False

for app in apps:
    name = app["name"]
    cfg = app.get("config", {}) or {}

    if any(has_placeholder(v) for v in cfg.values()):
        print(f"Skipping {name}: placeholder or blank config still present -> {cfg}")
        continue

    print(f"--- Rendering app: {name} ---")
    print("Config:", cfg)

    star_files = glob.glob(f"tronbyt-apps/apps/{name}/*.star")
    if not star_files:
        print(f"Missing .star file for app: {name} — skipping")
        continue

    star = star_files[0]
    out_dir = f"out/{tenant}"
    os.makedirs(out_dir, exist_ok=True)
    out_file = f"{out_dir}/{name}.webp"

    args = ["pixlet", "render", star]

    for k, v in cfg.items():
        if isinstance(v, bool):
            v = "True" if v else "False"
        elif isinstance(v, (int, float)):
            v = str(v)
        else:
            v = str(v)
        args.append(f"{k}={v}")

    args.extend(["-o", out_file])

    print("Running:", " ".join(shlex.quote(a) for a in args))
    subprocess.run(args, check=True)

print("Render complete")
