load("render.star", "render")
load("http.star", "http")

API_URL = "https://www.gotracker.ca/gotracker/mobile/proxy/web/Messages/Signage/Rail/%s/%s"

DEFAULT_LINE = "LE"
DEFAULT_STATION = "GU"

# Options:
#   "Inbound"
#   "Outbound"
#   "Both"
DEFAULT_DIRECTION = "Both"


def pad2(n):
    if n < 10:
        return "0%d" % n
    return "%d" % n


def time_part(iso):
    # Input example: 2026-06-29T12:28:47
    if iso == None or len(iso) < 16:
        return "?"
    return iso[11:16]


def minutes_from_iso(iso):
    if iso == None or len(iso) < 16:
        return 0

    h = int(iso[11:13])
    m = int(iso[14:16])

    return h * 60 + m


def delay_text(scheduled, actual):
    sched_min = minutes_from_iso(scheduled)
    actual_min = minutes_from_iso(actual)

    diff = actual_min - sched_min

    if diff <= 1 and diff >= -1:
        return "On Time"

    if diff > 1:
        return "+%d min" % diff

    return "%d min" % diff


def status_color(status):
    s = status.lower()

    if "cancel" in s:
        return "#f00"

    if "+" in s or "delay" in s:
        return "#ff0"

    return "#0f0"


def short_destination(dest):
    if dest == "DC Oshawa GO":
        return "Oshawa"

    if dest == "Union":
        return "Union"

    if len(dest) > 12:
        return dest[:12]

    return dest


def direction_label(direction):
    if direction == "Inbound":
        return "WB"

    if direction == "Outbound":
        return "EB"

    return direction[:2]


def fetch_departures(line, station):
    url = API_URL % (line, station)

    res = http.get(
        url,
        ttl_seconds = 60,
    )

    if res.status_code != 200:
        fail("GO Tracker API failed: %d" % res.status_code)

    data = res.json()

    if data.get("errCode") != 0:
        fail("GO Tracker API error: %s" % data.get("errMsg"))

    return data


def flatten_departures(data, wanted_direction):
    trips = []

    for direction in data.get("directions", []):
        dir_name = direction.get("direction")

        if wanted_direction != "Both" and dir_name != wanted_direction:
            continue

        for trip in direction.get("tripMessages", []):
            scheduled = trip.get("scheduled")
            actual = trip.get("actual")

            status = delay_text(scheduled, actual)

            trips.append({
                "direction": dir_name,
                "destination": trip.get("destination") or "?",
                "scheduled": scheduled,
                "actual": actual,
                "track": trip.get("track") or "?",
                "tripName": trip.get("tripName") or "",
                "coachCount": trip.get("coachCount") or 0,
                "isExpress": trip.get("isExpress") or False,
                "status": status,
            })

    return trips


def trip_slide(line, station, trip):
    dest = short_destination(trip["destination"])
    sched = time_part(trip["scheduled"])
    actual = time_part(trip["actual"])
    track = trip["track"]
    status = trip["status"]
    coaches = trip["coachCount"]

    express = ""
    if trip["isExpress"]:
        express = " EXP"

    return render.Box(
        color = "#000",
        child = render.Column(
            children = [
                render.Text(
                    content = "%s %s/%s" % (direction_label(trip["direction"]), line, station),
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
                    content = "%s %sC%s" % (status, coaches, express),
                    font = "tom-thumb",
                    color = status_color(status),
                ),
            ],
        ),
    )


def no_trips_slide(line, station):
    return render.Root(
        child = render.Box(
            color = "#000",
            child = render.Column(
                children = [
                    render.Text(
                        content = "%s/%s" % (line, station),
                        font = "6x10",
                        color = "#0cf",
                    ),
                    render.Text(
                        content = "No trips",
                        font = "6x10",
                        color = "#f66",
                    ),
                ],
            ),
        ),
    )


def main(config):
    line = config.get("line") or DEFAULT_LINE
    station = config.get("station") or DEFAULT_STATION
    wanted_direction = config.get("direction") or DEFAULT_DIRECTION

    data = fetch_departures(line, station)
    trips = flatten_departures(data, wanted_direction)

    if len(trips) == 0:
        return no_trips_slide(line, station)

    slides = []

    # Show first 4 trips as rotating frames.
    count = len(trips)
    if count > 4:
        count = 4

    for i in range(count):
        slides.append(trip_slide(line, station, trips[i]))

    return render.Root(
        delay = 5000,
        child = render.Animation(
            children = slides,
        ),
    )
