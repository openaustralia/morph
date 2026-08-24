# Containerised dev environment via devcontainer

Status: accepted

Development and Capistrano deployment on macOS happen inside the
containerised dev environment (the compose stack behind `make docker-up`,
wrapped by the devcontainer in `.devcontainer/`), with the Ruby containers
built as linux/amd64 and run under Rosetta on Apple silicon. Native macOS
development is unsupported, because it is currently impossible: `Gemfile.lock`
locks only the `x86_64-linux` platform, and the locked
`sorbet-static 0.5.10262` ships Darwin builds only up to `universal-darwin-22`,
so bundler cannot resolve the bundle on any current macOS at all. Sorbet also
has no Linux ARM64 build ([sorbet/sorbet#4119](https://github.com/sorbet/sorbet/issues/4119)),
which is why the containers are amd64 rather than arm64.

The devcontainer wraps the existing `docker-compose.yml` plus
`docker_images/persistent_services.yaml` rather than defining its own image,
so there is one definition of the Ruby environment. It forwards the host's
SSH agent, which is what lets `bundle exec cap staging deploy` and
`bundle exec cap production deploy` run from inside the container without
copying keys into it.

## Considered options

- Fix native macOS development: rejected for now. It needs a Sorbet upgrade
  (or exclusion), darwin platforms added to `Gemfile.lock`, and building
  Ruby 2.7.6 on current macOS, which is its own fight. ADR 0005 moves the
  application to Ruby 3.4, which dissolves most of this; revisit native
  support after that lands rather than doing the work twice.
- A standalone devcontainer image independent of compose: rejected, because
  it duplicates the Ruby environment definition and the two would drift.

## Consequences

- Everything on Apple silicon runs under emulation (the Ruby containers,
  MySQL 5.7, and the amd64-only buildstep scraper images), so it is slow.
  "Use Rosetta for x86/amd64 emulation on Apple Silicon" must be switched on
  in Docker Desktop.
- `mitmdump2` is no longer a startup dependency of `web`; it sits behind the
  `proxy` compose profile. The proxy code path it serves is already switched
  off in production (issue #1506), and the image is amd64-only.
- Running scrapers locally needed three accommodations, found by running the
  `:docker` specs in this environment:
  - Image pulls and builds in `Morph::DockerUtils` pass
    `"platform" => "linux/amd64"`, because scraper images only exist for
    amd64 and an ARM64 daemon otherwise refuses them.
  - Rosetta writes its AOT cache to `$HOME/.cache` inside the container, and
    herokuish builds with `HOME=/app`, so the build's final
    `mv /tmp/build/.cache /app/.cache` can race a freshly recreated
    `/app/.cache`. `Morph::DockerRunner.compile` recovers from exactly that
    case (and only that case) after an otherwise successful build.
  - Docker Desktop's containerd image store cannot run legacy-builder builds
    `FROM` a tag that was pulled as a manifest list ("no match for platform
    in manifest" at the export step). `make dev-scraper-images` pulls the
    buildstep tags by their amd64 manifest digest instead. Relatedly,
    creating the `morph` scraper network with its fixed 192.168.0.0/16
    subnet fails once other Docker networks occupy that range;
    `make dev-scraper-network` pre-creates it with an auto-allocated subnet.
- `make vagrant-up` remains broken on Apple silicon (VirtualBox with an
  amd64 box) and is out of scope; Ansible provisioning from macOS is
  untested.
