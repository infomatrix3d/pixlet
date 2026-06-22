load("render.star", "render")
load("http.star", "http")

# Replace this with your actual Vercel deployment URL
# Swap "jugantor" out for "samakal" or "mzamin" to change sources
API_URL = "https://your-project.vercel.app/api/jugantor"

def main():
    # 1. Fetch live news array from your Vercel API
    response = http.get(API_URL, ttl_seconds=300) # Caches data for 5 minutes
    if response.status_code != 200:
        return render.Root(
            child = render.Text("API Error", color="#f00")
        )
        
    news_items = response.json()
    
    # Fallback if the list comes back empty
    if not news_items or type(news_items) == "dict" and "error" in news_items:
        return render.Root(
            child = render.Text("No News", color="#ff0")
        )

    # 2. Extract and stitch together the top 3 headlines with a clear separator
    headlines = []
    for i in range(min(3, len(news_items))):
        headlines.append(news_items[i]["title"])
        
    full_scroll_text = "  *** ".join(headlines)

    # 3. Render Layout (64x32 Canvas Layout)
    return render.Root(
        # Use show_full_animation to ensure the text scrolls fully before switching apps
        show_full_animation = True, 
        child = render.Column(
            children = [
                # Top Header Banner
                render.Box(
                    width = 64,
                    height = 10,
                    color = "#1a1a2e", # Dark background for header
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
                        # The horizontal Marquee matches the width boundary and scrolls right-to-left
                        child = render.Text(full_scroll_text, color="#ffffff", font="tb-8")
                    )
                )
            ]
        )
    )
