import json
import os
import subprocess
import glob
import shlex

# ✅ Inputs from workflow
tenant = os.environ["TENANT"]
manifest_path = os.environ.get("MANIFEST", "manifest.json")

print(f"Using manifest: {manifest_path}")
print(f"Tenant: {tenant}")

# ✅ Load manifest
with open(manifest_path, "r", encoding="utf-8") as f:
    data = json.load(f)

apps = data.get("apps", [])

# ✅ Nothing to render → exit cleanly
if not apps:
    print("No enabled apps to render")
    raise SystemExit(0)


# ✅ Helper: detect empty/default values
def is_empty_or_default(value):
    if value is None:
        return True

    if isinstance(value, str):
        v = value.strip()

        # ✅ empty string
        if not v:
            return True

        # ✅ placeholder like teamOptions[0].value
        if ".value" in v and "[" in v:
            return True

    return False


# ✅ Render loop
for app in apps:
    name = app["name"]
    cfg = app.get("config", {}) or {}

    print(f"\n--- Rendering app: {name} ---")
    print("Raw config:", cfg)

    # ✅ Find .star file
    star_files = glob.glob(f"tronbyt-apps/apps/{name}/*.star")

    if not star_files:
        print(f"❌ Missing .star file for {name} — skipping")
        continue

    star = star_files[0]

    # ✅ Output path
    out_dir = f"out/{tenant}"
    os.makedirs(out_dir, exist_ok=True)
    out_file = f"{out_dir}/{name}.webp"

    # ✅ Base command
    args = ["pixlet", "render", star]

    # ✅ Build ONLY valid params
    valid_params = []

    for k, v in cfg.items():
        if not is_empty_or_default(v):
            if isinstance(v, bool):
                v = "True" if v else "False"
            elif isinstance(v, (int, float)):
                v = str(v)
            else:
                v = str(v)

            valid_params.append(f"{k}={v}")

    # ✅ Decide behavior
    if valid_params:
        print(f"✅ Using config params: {valid_params}")
        args.extend(valid_params)
    else:
        print("✅ No valid config → using Pixlet defaults")

    # ✅ Output file
    args.extend(["-o", out_file])

    # ✅ Log command (safe quoting)
    print("Running:", " ".join(shlex.quote(a) for a in args))

    try:
        subprocess.run(args, check=True)
        print(f"✅ Rendered: {out_file}")
    except subprocess.CalledProcessError as e:
        print(f"❌ Render failed for {name}: {e}")
        continue

print("\n✅ Rendering complete")
