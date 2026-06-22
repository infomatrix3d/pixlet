load("http.star", "http")
load("render.star", "render")
load("encoding/base64.star", "base64")

API_URL = "https://mzamin.vercel.app/api/jugantor"

def main(config):
    # 1. Fetch backend payload
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

    # 2. Decode the Base64 image back into binary PNG bytes
    image_bytes = base64.decode(data["image_base64"])

    # 3. Render inside a horizontal marquee
    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Marquee(
            width = 64,
            scroll_direction = "horizontal",
            child = render.Image(src = image_bytes)
        )
    )
