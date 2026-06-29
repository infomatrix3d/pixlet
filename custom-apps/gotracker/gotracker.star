load("render.star", "render")
load("http.star", "http")

API_URL = "https://www.gotracker.ca/gotracker/mobile/proxy/web/Messages/Signage/Rail/%s/%s"

DEFAULT_LINE = "LE"
DEFAULT_STATION = "GU"
DEFAULT_DIRECTION = "Both"


def time_part(iso):
    # Example: 2026-06-29T12:28:47
    if iso == None:
        return "?"
    if len(iso) < 16:
        return "?"
    return iso[11:16]


def is_delayed(scheduled, actual):
    # Very simple check: if scheduled HH:MM != actual HH:MM, call it updated.
    if scheduled == None or actual == None:
        return False

    return time_part(scheduled) != time_part(actual)


def get_status(scheduled, actual):
    if is_delayed(scheduled, actual):
        return "Updated"
    return "On Time"


def get_status_color(status):
    if status == "Updated":
        return "#ff0"
    return "#0f0"


def short_destination(dest):
    if dest == None:
        return "?"

    if dest == "DC Oshawa GO":
        return "Oshawa"

    if len(dest) > 12:
        return dest[:12]

    return dest


def direction_short(direction):
    if direction == "Inbound":
        return "WB"
    if direction == "Outbound":
        return "EB"
    return "GO"


def fetch_data(line, station):
    url = API_URL % (line, station)

    res = http.get(
        url,
        ttl_seconds = 60,
    )

    if res.status_code != 200:
        fail("HTTP error %d" % res.status_code)

    data = res.json()

    if data.get("errCode") != 0:
        fail("API error")

    return data


def flatten_trips(data, wanted_direction):
    trips = []

    directions = data.get("directions")
    if directions == None:
        return trips

    for direction in directions:
        dir_name = direction.get("direction")

        if wanted_direction != "Both" and dir_name != wanted_direction:
            continue

        trip_messages = direction.get("tripMessages")
        if trip_messages == None:
            continue

        for trip in trip_messages:
            trips.append({
                "direction": dir_name,
                "destination": trip.get("destination"),
                "scheduled": trip.get("scheduled"),
                "actual": trip.get("actual"),
                "track": trip.get("track"),
                "tripName": trip.get("tripName"),
                "coachCount": trip.get("coachCount"),
                "isExpress": trip.get("isExpress"),
            })

    return trips


def trip_screen(line, station, trip):
    destination = short_destination(trip.get("destination"))
    scheduled = time_part(trip.get("scheduled"))
    actual = time_part(trip.get("actual"))

    track = trip.get("track")
    if track == None or track == "":
        track = "?"

    coach_count = trip.get("coachCount")
    if coach_count == None:
        coach_count = "?"
    else:
        coach_count = str(coach_count)

    status = get_status(trip.get("scheduled"), trip.get("actual"))

    detail = "%s P%s" % (scheduled, track)

    if actual != scheduled:
        detail = "%s>%s P%s" % (scheduled, actual, track)

    return render.Box(
        color = "#000",
        child = render.Column(
            children = [
                render.Text(
                    content = "%s %s/%s" % (
                        direction_short(trip.get("direction")),
                        line,
                        station,
                    ),
                    font = "tom-thumb",
                    color = "#888",
                ),
                render.Text(
                    content = destination,
                    font = "6x10",
                    color = "#fff",
                ),
                render.Text(
                    content = detail,
                    font = "6x10",
                    color = "#0cf",
                ),
                render.Text(
                    content = "%s %sC" % (status, coach_count),
                    font = "tom-thumb",
                    color = get_status_color(status),
                ),
            ],
        ),
    )


def no_trips_screen(line, station):
    return render.Box(
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
    )


def main(config):
    line = config.get("line") or DEFAULT_LINE
    station = config.get("station") or DEFAULT_STATION
    wanted_direction = config.get("direction") or DEFAULT_DIRECTION

    data = fetch_data(line, station)
    trips = flatten_trips(data, wanted_direction)

    if len(trips) == 0:
        return render.Root(
            child = no_trips_screen(line, station),
        )

    screens = []

    count = len(trips)
    if count > 4:
        count = 4

    for i in range(count):
        screens.append(trip_screen(line, station, trips[i]))

    return render.Root(
        delay = 5000,
        child = render.Animation(
            children = screens,
        ),
    )
