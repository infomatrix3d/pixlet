load("http.star", "http")
load("render.star", "render")
load("encoding/base64.star", "base64")

API_URL = "https://mzamin.vercel.app/api/jugantor"

def main(config):
    response = http.get(url = API_URL, ttl_seconds = 300) 
    if response.status_code != 200:
        return render.Root(
            child = render.Text(content = "API Error", color = "#f00")
        )
        
    data = response.json()
    if "image_base64" not in data:
        return render.Root(
            child = render.Text(content = "Data Error", color = "#ff0")
        )

    image_bytes = base64.decode(data["image_base64"])

    return render.Root(
        delay = 120, # Higher number makes vertical scroll slower and easier to read
        show_full_animation = True,
        child = render.Marquee(
            height = 32, # Fills the full height of the Tidbyt screen
            scroll_direction = "vertical",
            offset_start = 32, # Starts scrolling from below the viewport border boundary
            child = render.Image(src = image_bytes)
        )
    )
