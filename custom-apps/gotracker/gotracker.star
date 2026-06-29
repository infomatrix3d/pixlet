load("render.star", "render")
load("http.star", "http")

URL = "https://www.gotracker.ca/gotracker/mobile/proxy/web/Messages/Signage/Rail/LE/GU"

def main():
    res = http.get(URL, ttl_seconds = 60)
    body = res.body()

    return render.Root(
        child = render.Box(
            color = "#000",
            child = render.Column(
                children = [
                    render.Text(
                        content = "HTTP %d" % res.status_code,
                        font = "6x10",
                        color = "#0f0",
                    ),
                    render.Text(
                        content = "Len %d" % len(body),
                        font = "6x10",
                        color = "#0cf",
                    ),
                ],
            ),
        ),
    )
