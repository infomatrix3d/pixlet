load("render.star", "render")
load("http.star", "http")

URL = "https://www.gotracker.ca/gotracker/mobile/proxy/web/Messages/Signage/Rail/LE/GU"

def main():
    res = http.get(URL, ttl_seconds = 60)
    body = res.body()

    snippet = body[:20]

    return render.Root(
        child = render.Box(
            color = "#000",
            child = render.Column(
                children = [
                    render.Text(
                        content = "Body:",
                        font = "6x10",
                        color = "#0f0",
                    ),
                    render.Text(
                        content = snippet,
                        font = "tom-thumb",
                        color = "#fff",
                    ),
                ],
            ),
        ),
    )
