load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")

URL = "https://www.gotracker.ca/gotracker/mobile/proxy/web/Messages/Signage/Rail/LE/GU"

def main():
    res = http.get(URL, ttl_seconds = 60)

    data = json.decode(res.body())

    directions = data["directions"]

    return render.Root(
        child = render.Box(
            color = "#000",
            child = render.Column(
                children = [
                    render.Text(
                        content = "Dirs %d" % len(directions),
                        font = "6x10",
                        color = "#0f0",
                    ),
                    render.Text(
                        content = directions[0]["direction"],
                        font = "6x10",
                        color = "#0cf",
                    ),
                ],
            ),
        ),
    )
