load("http.star", "http")
load("render.star", "render")

API_URL = "https://mzamin.vercel.app/api/jugantor"

def main(config):
    # 1. Fetch live news array from your Vercel API (cache for 5 minutes)
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
        # Ensure 'title' key exists before using it
        if "title" in item:
            headlines.append(item["title"])
        
    if not headlines:
        return render.Root(
            child = render.Text(content = "Empty Feed", color = "#ff0")
        )

    full_scroll_text = "  *** ".join(headlines)

    # 3. Render Layout (64x32 Canvas Layout matching your preferences)
    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                # Top Header Banner
                render.Box(
                    width = 64,
                    height = 10,
                    color = "#1a1a2e", 
                    child = render.Center(
                        child = render.Text(content = "JUGANTOR", color = "#00fff0", font = "6x10")
                    )
                ),
                # Spacer
                render.Box(width = 64, height = 2),
                # Bottom Scrolling News Box
                render.Box(
                    width = 64,
                    height = 20,
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(content = full_scroll_text, color = "#ffffff", font = "tb-8")
                    )
                )
            ]
        )
    )
