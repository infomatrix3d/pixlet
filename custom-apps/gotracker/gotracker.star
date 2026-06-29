load("render.star", "render")
load("http.star", "http")

URL = "https://www.gotracker.ca/gotracker/mobile/proxy/web/Messages/Signage/Rail/LE/GU"

def main():
    res = http.get(URL, ttl_seconds = 60)

    body = res.body()

    return render.Root(
        child = render.Marquee(
            child = render.Text(
                content = body[:120],
                font = "tom-thumb",
                color = "#0f0",
            ),
        ),
    )
