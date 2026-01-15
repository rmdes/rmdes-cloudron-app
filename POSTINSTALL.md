## Configuration Required

To display your GitHub projects and starred repos, you need to configure API tokens:

1. Open **File Manager** from the Cloudron app dashboard
2. Edit `/app/data/env.sh`
3. Add your GitHub token:
   ```
   export FORGE_TOKENS='{"github.com": "ghp_your_token_here"}'
   ```
4. **Restart** the app from the Cloudron dashboard

### Getting a GitHub Token

1. Go to [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Generate a new token (classic) with `public_repo` scope
3. Copy the token into env.sh

### Optional: Social Feeds

For Bluesky and Mastodon feeds, add their credentials to env.sh as well.
