Personal website and portfolio for Ricardo Mendes.

## Features

- **Portfolio Display**: Showcases GitHub projects with recent commits
- **Social Integration**: Live feeds from Bluesky, Mastodon, and Spotify
- **Blog Feed**: Pulls articles from external RSS feed
- **GitHub Starred**: Displays your starred repositories
- **YouTube Integration**: Shows latest videos and live status

## Configuration

After installation, edit `/app/data/env.sh` to configure your API tokens:

- **GitHub Token**: Required for projects and starred repos display
- **Bluesky Credentials**: Optional, for social feed
- **Mastodon Credentials**: Optional, for social feed

Restart the app after making changes.

## Technology

Built with Hugo static site generator and Go backend APIs.
Based on a template from [Felicitas Pojtinger](https://github.com/pojntfx/felicitas.pojtinger.com).
