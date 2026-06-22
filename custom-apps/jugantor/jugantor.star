load("http.star", "http")
load("render.star", "render")
load("encoding/base64.star", "base64")

API_URL = "https://mzamin.vercel.app/api/jugantor"

def main(config):
    response = http.get(url = API_URL, ttl_seconds = 300)

    if response.status_code != 200:
        return render.Root(
            child = render.Text(content = "API Error", color = "#ff0000")
        )

    data = response.json()

    if "error" in data:
        return render.Root(
            child = render.Text(content = "SVG->PNG Err", color = "#ffff00")
        )

    if "image_base64" not in data:
        return render.Root(
            child = render.Text(content = "Data Error", color = "#ffff00")
        )

    image_bytes = base64.decode(data["image_base64"])

    return render.Root(
        delay = 120,
        show_full_animation = True,
        child = render.Marquee(
            height = 32,
            scroll_direction = "vertical",
            offset_start = 32,
            child = render.Image(src = image_bytes)
        )
    )
