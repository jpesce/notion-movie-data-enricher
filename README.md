<p align="center">
  <p align="center">
   <img src="https://github.com/user-attachments/assets/7fdc5944-fe4d-42c3-9e53-712601c74afc" alt="Movie Data Enricher">
  </p>
  <h1 align="center"><b>The Catalog Movie Data Enricher</b></h1>
  <p align="center">
    Enrich movie metadata in Notion database
  </p>
</p>

The Catalog Movie Data Enricher is a program that adds information about movies on a Notion
database. It currently supports:
* **Movie name**: given an initial movie name, _e.g._ 'tampopo', it replaces it for its properly
capitalized name and, if it's a non-english title, adds both the original and translated names. For
example, 'tampopo' becomes '[タンポポ
(Tampopo)](https://www.themoviedb.org/movie/11830?language=en-US)', 'Playtime' becomes
'[PlayTime](https://www.themoviedb.org/movie/10227-playtime?language=en-US)'.
* **Year**: if given, use the information to find the right movie, _e.g._ Nosferatu from
[1922](https://www.themoviedb.org/movie/653-nosferatu-eine-symphonie-des-grauens?language=en-US) or
from [2024](https://www.themoviedb.org/movie/426063-nosferatu?language=en-US). Otherwise, adds the
year of the movie it finds.
* **Director**: adds the directors or creators of the title.
* **TV shows**: if no movies are found with the provided information, it searches for TV shows.
_E.g._ '[All Watched Over by Machines of Loving
Grace](https://www.themoviedb.org/tv/44045-all-watched-over-by-machines-of-loving-grace?language=en-US)'
is a TV documentary, not a movie.
* **Poster**: sets the movie poster as the page cover.

Currently, it leverages data available from [TMDB](https://www.themoviedb.org/).

After updating the page, it ticks a 'Don't enrich' checkbox to prevent further updates in future
executions. This enables manual edits to the page's content. However, the recommended practice is to
correct any inaccuracies directly at the source (TMDB).
