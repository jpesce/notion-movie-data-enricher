<p align="center">
  <img src="https://github.com/user-attachments/assets/7fdc5944-fe4d-42c3-9e53-712601c74afc" alt="Movie catalog in Notion">
  <h1 align="center"><b>The Catalog Movie Data Enricher</b></h1>
</p>

Automatically enrich movie entries in a Notion database by fetching and filling in relevant data
from [TMDB](https://tmdb.org/) and [IMDb](https://imdb.com/).

I use this utility for curating a personal movie catalog that stays accurate, informative, and
visually appealing with minimal manual input.

## What It Does

For each movie entry in my Notion database, the program populates the following fields:

| **Field**   | **Description** | **Examples** |
| ----------- | --- | --- |
| Movie Name  | Properly capitalizes title. For non-English titles, adds both original and translated names. | `タンポポ (Tampopo)`, `PlayTime` |
| Director    | Lists the directors or creators of the movie. | `Akira Kurosawa` |
| Year        | Sets the official release year. | `1985` |
| Poster      | Sets the movie poster as the Notion page cover. | Pulled from TMDB |
| TMDB Link   | Direct link to the movie’s TMDB page. | `https://www.themoviedb.org/movie/10322` |
| IMDb Link   | Direct link to the movie’s IMDb page. | `https://www.imdb.com/title/tt0165798/` |
| IMDb Rating | Fills in the IMDb rating for quick reference. | `7.9` |
| Enriched    | Checkbox indicating entry has been processed and enriched. | `true` |

## TV Show Support

If no movie matches are found, the program will automatically check for TV shows.
For example, [`All Watched Over by Machines of Loving
Grace`](https://www.themoviedb.org/tv/44045-all-watched-over-by-machines-of-loving-grace?language=en-US)
is a TV documentary, not a movie — and will still be found and enriched.

## Search Strategy

The program identifies the correct TMDB entry using the following fallback strategy:

1. **TMDB Link Present**: Uses it to retrieve movie data directly.

2. **IMDb Link Present**: Uses the IMDb ID to look up the TMDB equivalent.

3. **No Links Available**: Falls back to searching TMDB by the Notion page title. Movies are
   prioritized over TV shows when multiple results are found.

## Data Sources

- [TMDB (The Movie Database)](https://www.themoviedb.org/) — for movie metadata, posters, titles, and directors.
- [Unofficial IMDb API](https://imdbapi.dev/) — for IMDb ratings.

## Update Tracking

Once an entry is successfully enriched, the program checks the **'Enriched'** checkbox on the Notion
page. This ensures that the entry is skipped in future runs and any manual tweaks are preserved.

> [!TIP] 
> For long-term accuracy, it's recommended to correct data directly on
> [TMDB](https://www.themoviedb.org/) if discrepancies are found instead of correcting directly in
> Notion.
