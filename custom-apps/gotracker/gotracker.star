load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")

URL = "https://www.gotracker.ca/gotracker/mobile/proxy/web/Messages/Signage/Rail/LE/GU"

def time_part(iso):
    if iso == None:
        return "?"
    if len(iso) < 16:
        return "?"
    return iso[11:16]

def main():
    res = http.get(URL, ttl_seconds = 60)
    data = json.decode(res.body())

    direction = data["directions"][0]
    trip = direction["tripMessages"][0]

    dest = trip["destination"]
    sched = time_part(trip["scheduled"])
    actual = time_part(trip["actual"])
    track = trip["track"]
    coaches = str(trip["coachCount"])

    status = "On Time"
    color = "#0f0"

    if sched != actual:
        status = "Upd " + actual
        color = "#ff0"

    return render.Root(
        child = render.Box(
            color = "#000",
            child = render.Column(
                children = [
                    render.Text(
                        content = "LE/GU WB",
                        font = "tom-thumb",
                        color = "#888",
                    ),
                    render.Text(
                        content = dest,
                        font = "6x10",
                        color = "#fff",
                    ),
                    render.Text(
                        content = "%s P%s" % (sched, track),
                        font = "6x10",
                        color = "#0cf",
                    ),
                    render.Text(
                        content = "%s %sC" % (status, coaches),
                        font = "tom-thumb",
                        color = color,
                    ),
                ],
            ),
        ),
    )
