load("render.star", "render")
load("http.star", "http")

URL = "https://www.gotracker.ca/gotracker/mobile/proxy/web/Messages/Signage/Rail/LE/GU"

def main():
    res = http.get(URL, ttl_seconds = 60)

    if res.status_code != 200:
        return render.Root(
            child = render.Text(
                content = "HTTP %d" % res.status_code,
                font = "6x10",
                color = "#f00",
            ),
        )

    data = res.json()
    directions = data["directions"]

    total = 0
    for d in directions:
        total = total + len(d["tripMessages"])

    return render.Root(
        child = render.Text(
            content = "Trips %d" % total,
            font = "6x10",
            color = "#0f0",
        ),
    )
