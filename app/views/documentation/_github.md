To sign in you'll need an account on GitHub or GitLab. That is where your scraper code is stored; morph.io calls these **forges**.

Your email address is requested from the forge and is only used to send [email alerts](#watching) for scrapers you're watching.

**GitHub.** Read and write access to your public repositories is needed to [create a new scraper](/scrapers/new). To run a scraper, morph.io reaches its repository through the [Morph GitHub App](/documentation/github_app), which you install on yourself or your organisation and point at the repositories you want run.

**GitLab.** The `api` and `read_user` scopes are requested once at sign-in. How morph.io reaches your repositories depends on what your group's plan allows; see [GitLab](/documentation/gitlab).

If you are on both, sign in with one and then connect the other from your settings page. You stay one person on morph.io, and can [move a scraper](/documentation/gitlab#moving) from one forge to the other without its address changing.
