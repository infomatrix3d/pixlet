load("render.star", "render")
load("http.star", "http")

# Live Vercel API
API_URL = "https://mzamin.vercel.app/api/jugantor"

def main():
    # 1. Fetch live news array from your Vercel API
    response = http.get(API_URL, ttl_seconds=300) 
    if response.status_code != 200:
        return render.Root(
            child = render.Text("API Error", color="#f00")
        )
        
    news_items = response.json()
    
    # Starlark friendly empty list / dictionary error checks
    if not news_items:
        return render.Root(
            child = render.Text("No News", color="#ff0")
        )

    # 2. Extract and stitch together the top 3 headlines
    headlines = []
    
    # Ensure safe loop iteration regardless of how many headlines returned
    count = len(news_items)
    if count > 3:
        count = 3

    for i in range(count):
        # Safely pull title without using type evaluations
        item = news_items[i]
        if item and "title" in item:
            headlines.append(item["title"])
        
    if not headlines:
        return render.Root(
            child = render.Text("Empty Feed", color="#ff0")
        )

    full_scroll_text = "  *** ".join(headlines)

    # 3. Render Layout (64x32 Canvas Layout)
    return render.Root(
        child = render.Column(
            children = [
                # Top Header Banner
                render.Box(
                    width = 64,
                    height = 10,
                    color = "#1a1a2e", 
                    child = render.Center(
                        child = render.Text("JUGANTOR", color="#00fff0", font="6x10")
                    )
                ),
                # Spacer
                render.Box(width=64, height=2),
                # Bottom Scrolling News Box
                render.Box(
                    width = 64,
                    height = 20,
                    child = render.Marquee(
                        width = 64,
                        child = render.Text(full_scroll_text, color="#ffffff", font="tb-8")
                    )
                )
            ]
        )
    )
