load("http.star", "http")
load("render.star", "render")

API_URL = "https://mzamin.vercel.app/api/jugantor"

def main(config):
    # 1. Fetch live news array from your Vercel API
    response = http.get(url = API_URL, ttl_seconds = 300) 
    if response.status_code != 200:
        return render.Root(
            child = render.Text(content = "API Error", color = "#f00")
        )
        
    news_items = response.json()
    
    # Empty feed fallback
    if not news_items:
        return render.Root(
            child = render.Text(content = "No News", color = "#ff0")
        )

    # 2. Extract and stitch together the top 3 headlines safely
    headlines = []
    feed_length = min(len(news_items), 3)

    for i in range(0, feed_length, 1):
        item = news_items[i]
        if "title" in item:
            headlines.append(item["title"])
        
    if not headlines:
        return render.Root(
            child = render.Text(content = "Empty Feed", color = "#ff0")
        )

    # Combine headlines with a clean separator indicator
    full_scroll_text = "  *** ".join(headlines)

    # 3. Render Layout (Using WrappedText inside a horizontal Marquee to safeguard Bengali characters)
    return render.Root(
        delay = 90,
        show_full_animation = True,
        child = render.Column(
            children = [
                # Top Header Banner
                render.Box(
                    width = 64,
                    height = 9,
                    color = "#1a1a2e", 
                    child = render.Center(
                        child = render.Text(content = "JUGANTOR", color = "#00fff0", font = "CG-pixel-4x5-mono")
                    )
                ),
                # Thin accent dividing rule line matching ABC style
                render.Box(width = 64, height = 1, color = "#00fff0"),
                # Bottom Scrolling News Container
                render.Box(
                    width = 64,
                    height = 22,
                    child = render.Marquee(
                        width = 64,
                        scroll_direction = "horizontal",
                        child = render.WrappedText(
                            content = full_scroll_text, 
                            color = "#ffffff", 
                            font = "CG-pixel-3x5-mono",
                            width = 800 # Explicit wide canvas block allocation for the marquee text length
                        )
                    )
                )
            ]
        )
    )
