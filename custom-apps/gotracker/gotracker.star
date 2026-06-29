load("render.star", "render")
load("http.star", "http")
load("bsoup.star", "bsoup")

BASE_URL = "https://www.gotracker.ca/gotracker/mobile/StationDeparture/%s/%s"

DEFAULT_LINE = "LE"
DEFAULT_STATION = "GU"


def clean(s):
    if s == None:
        return ""

    # Normalize whitespace.
    parts = str(s).split()
    return " ".join(parts)


def fetch_html(line, station):
    url = BASE_URL % (line, station)

    res = http.get(
        url,
        ttl_seconds = 60,  # cache for 1 minute; be polite to the site
    )

    if res.status_code != 200:
        fail("GO Tracker request failed with status %d" % res.status_code)

    return res.body()


def parse_departures(html):
    soup = bsoup.parseHtml(html)

    departures = []

    # GO Tracker commonly exposes rows as table rows.
    rows = soup.find_all("tr")

    for row in rows:
        cells = []

        # Collect table header/data cells.
        for cell in row.find_all("th"):
            txt = clean(cell.get_text())
            if txt != "":
                cells.append(txt)

        for cell in row.find_all("td"):
            txt = clean(cell.get_text())
            if txt != "":
                cells.append(txt)

        if len(cells) < 4:
            continue

        row_text = " ".join(cells).lower()

        # Skip header rows.
        if "destination" in row_text and "scheduled" in row_text:
            continue

        # Expected shape:
        # Destination | Scheduled | Platform | Expected | Notes...
        departures.append({
            "destination": cells[0],
            "scheduled": cells[1],
            "platform": cells[2],
            "expected": cells[3],
            "notes": " ".join(cells[4:]) if len(cells) > 4 else "",
        })

    return departures


def departure_slide(line, station, d):
    title = "%s/%s" % (line, station)

    platform = d["platform"]
    if platform == "" or platform == "-":
        platform = "?"

    status_color = "#0f0"
    if "delay" in d["expected"].lower():
        status_color = "#ff0"
    if "cancel" in d["expected"].lower():
        status_color = "#f00"

    return render.Box(
        color = "#000",
        child = render.Column(
            children = [
                render.Text(
                    content = title,
                    font = "tom-thumb",
                    color = "#888",
                ),
                render.Text(
                    content = d["destination"],
                    font = "6x10",
                    color = "#fff",
                ),
                render.Text(
                    content = d["scheduled"] + "  P" + platform,
                    font = "6x10",
                    color = "#0cf",
                ),
                render.Text(
                    content = d["expected"],
                    font = "tom-thumb",
                    color = status_color,
                ),
            ],
        ),
    )


def error_slide(message):
    return render.Root(
        child = render.Box(
            color = "#000",
            child = render.Column(
                children = [
                    render.Text(
                        content = "GO Tracker",
                        font = "6x10",
                        color = "#0cf",
                    ),
                    render.Text(
                        content = message,
                        font = "tom-thumb",
                        color = "#f66",
                    ),
                ],
            ),
        ),
    )


def main(config):
    line = config.get("line") or DEFAULT_LINE
    station = config.get("station") or DEFAULT_STATION

    line = line.upper()
    station = station.upper()

    html = fetch_html(line, station)
    departures = parse_departures(html)

    if len(departures) == 0:
        return error_slide("No trips found")

    # Show up to first 3 departures as rotating frames.
    slides = []
    count = len(departures)
    if count > 3:
        count = 3

    for i in range(count):
        slides.append(departure_slide(line, station, departures[i]))

    return render.Root(
        delay = 5000,
        child = render.Animation(
            children = slides,
        ),
    )
