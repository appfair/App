



# Tidal Zone

<img height="50" src="{{ site.github.repository_url }}/releases/latest/download/{{ site.github.owner_name }}.png" /> Tidal Zone is an app that show the current tide near you.


This page was last updated at {{ "now" | date: "%Y-%m-%d %H:%M" }}.

Installation:

  1. Launch [appfair://app/{{ site.github.owner_name }}](appfair://app/{{ site.github.owner_name }}) using the [App Fair](https://www.app-fair.app).
  2. Run: `brew install appfair/app/{{ site.github.owner_name | slugify }}`
  3.  Download: [{{ site.github.owner_name }}-macOS.zip]({{ site.github.repository_url }}/releases/latest/download/{{ site.github.owner_name }}-macOS.zip)


iOS Builds:

Download: [{{ site.github.owner_name }}-iOS.ipa]({{ site.github.repository_url }}/releases/latest/download/{{ site.github.owner_name }}-iOS.ipa)


## Variables:

```
api_url: {{ site.github.api_url }}
help_url: {{ site.github.help_url }}
environment: {{ site.github.environment }}
pages_env: {{ site.github.pages_env }}
public_repositories: {{ site.github.public_repositories }}
organization_members: {{ site.github.organization_members }}
build_revision: {{ site.github.build_revision }}
project_title: {{ site.github.project_title }}
project_tagline: {{ site.github.project_tagline }}
owner_name: {{ site.github.owner_name }}
owner_url: {{ site.github.owner_url }}
owner_gravatar_url: {{ site.github.owner_gravatar_url }}
repository_url: {{ site.github.repository_url }}
repository_nwo: {{ site.github.repository_nwo }}
repository_name: {{ site.github.repository_name }}
zip_url: {{ site.github.zip_url }}
tar_url: {{ site.github.tar_url }}
clone_url: {{ site.github.clone_url }}
releases_url: {{ site.github.releases_url }}
issues_url: {{ site.github.issues_url }}
wiki_url: {{ site.github.wiki_url }}
language: {{ site.github.language }}
is_user_page: {{ site.github.is_user_page }}
is_project_page: {{ site.github.is_project_page }}
show_downloads: {{ site.github.show_downloads }}
url: {{ site.github.url }}
baseurl: {{ site.github.baseurl }}
contributors: {{ site.github.contributors }}
releases: {{ site.github.releases }}
latest_release: {{ site.github.latest_release }}
private: {{ site.github.private }}
license: {{ site.github.license }}
 key: {{ site.github.license.key }}
 name: {{ site.github.license.name }}
 spdx_id: {{ site.github.license.spdx_id }}
 url: {{ site.github.license.url }}
source: {{ site.github.source }}
 branch: {{ site.github.source.branch }}
 path: {{ site.github.source.path }}
```

## Latest Release:

```
{{ site.github.latest_release | jsonify }}
```

## All `site.github`:

```
{{ site.github | jsonify }}
```



