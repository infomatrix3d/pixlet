load("render.star", "render")
load("http.star", "http")

def main():
    res = http.get(
        "https://www.gotracker.ca/gotracker/mobile/proxy/web/Messages/Signage/Rail/LE/GU",
        ttl_seconds = 60,
    )

    return render.Root(
        child = render.Text(
            content = "HTTP %d" % res.status_code,
            font = "6x10",
            color = "#0f0",
        ),
    )
