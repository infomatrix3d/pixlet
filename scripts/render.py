import json, os, subprocess, glob

tenant = os.environ["TENANT"]

with open("manifest.json") as f:
    data = json.load(f)

apps = data.get("apps", [])

if not apps:
    print("No apps to render")
    exit(0)

for app in apps:
    name = app["name"]
    cfg = app.get("config", {})

    print(f"Rendering {name} for tenant {tenant}")
    print("Config:", cfg)

    star_files = glob.glob(f"tronbyt-apps/apps/{name}/*.star")

    if not star_files:
        print("Missing .star file:", name)
        continue

    star = star_files[0]

    out_dir = f"out/{tenant}"
    os.makedirs(out_dir, exist_ok=True)

    out_file = f"{out_dir}/{name}.webp"

    args = ["pixlet", "render", star]

    for k, v in cfg.items():
        if isinstance(v, bool):
            v = "True" if v else "False"
        args.append(f"{k}={v}")

    args.extend(["-o", out_file])

    print("Running:", " ".join(args))
    subprocess.run(args, check=True)
