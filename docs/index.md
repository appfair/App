---
layout: page
---

{% assign appname = site.github.owner_name %}


<img height="50" width="50" src="{{ site.github.repository_url }}/releases/latest/download/{{ site.github.owner_name }}.png" /> Tidal Zone is an app that show the current tide near you.

## Links:

  * [Discussions: {{ site.github.repository_url }}/discussions]({{ site.github.repository_url }}/discussions)
  * [Issues: {{ site.github.repository_url }}/issues]({{ site.github.repository_url }}/issues)

This page was last updated at {{ "now" | date: "%Y-%m-%d %H:%M" }}.

Installation:

  1. Launch [appfair://app/{{ appname }}](appfair://app/{{ site.github.owner_name }}) using the [App Fair](https://www.app-fair.app).
  2. Run: `brew install appfair/app/{{ site.github.owner_name | slugify }}`
  3.  Download: [{{ site.github.owner_name }}-macOS.zip]({{ site.github.repository_url }}/releases/latest/download/{{ site.github.owner_name }}-macOS.zip)


iOS Builds:

Download: [{{ site.github.owner_name }}-iOS.ipa]({{ site.github.repository_url }}/releases/latest/download/{{ site.github.owner_name }}-iOS.ipa)


Latest Release Assets:

{% for asset in site.github.latest_release.assets %}
  * [{{ asset.name }} ({{ asset.size }})]({{ asset.browser_download_url }})
{% else %}
  This app does not yet have any releases.
{% endfor %}


<!-- render the platform screenshots -->

{% assign assetnames = site.github.latest_release.assets | map: 'name' %}

## Asset Names:

{% for assetname in assetnames %}
- {{ assetname }}
{% endfor %}


{% assign platforms = 'mac,ios' | split: ',' %}

{% assign macname = appname | append '-macOS.zip' %}
{% assign macrelease = assetnames contains macname %}
{% assign iosname = appname | append '-iOS.ipa' %}
{% assign iosrelease = assetnames contains iosname %}

## Platform iOS: {{ iosrelease }} {{ iosname }}
## Platform macOS: {{ macrelease }} {{ macname }}

{% for platform in platforms %}

## Platform: {{ platform }}

{% for asset in site.github.latest_release.assets %}
{% if asset.name contains "screenshot-{{ platform }}-" and asset.name contains ".png" %}
<img src="{{ asset.browser_download_url }}" />
{% endif %}

{% endfor %} <!-- asset -->

{% endfor %} <!-- platforms -->

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

E.g.:

```json
{
  "url": "https://api.github.com/repos/Tidal-Zone/App/releases/56670343",
  "assets_url": "https://api.github.com/repos/Tidal-Zone/App/releases/56670343/assets",
  "upload_url": "https://uploads.github.com/repos/Tidal-Zone/App/releases/56670343/assets{?name,label}",
  "html_url": "https://github.com/Tidal-Zone/App/releases/tag/0.0.2",
  "id": 56670343,
  "author": {
    "login": "github-actions[bot]",
    "id": 41898282,
    "node_id": "MDM6Qm90NDE4OTgyODI=",
    "avatar_url": "https://avatars.githubusercontent.com/in/15368?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/github-actions%5Bbot%5D",
    "html_url": "https://github.com/apps/github-actions",
    "followers_url": "https://api.github.com/users/github-actions%5Bbot%5D/followers",
    "following_url": "https://api.github.com/users/github-actions%5Bbot%5D/following{/other_user}",
    "gists_url": "https://api.github.com/users/github-actions%5Bbot%5D/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/github-actions%5Bbot%5D/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/github-actions%5Bbot%5D/subscriptions",
    "organizations_url": "https://api.github.com/users/github-actions%5Bbot%5D/orgs",
    "repos_url": "https://api.github.com/users/github-actions%5Bbot%5D/repos",
    "events_url": "https://api.github.com/users/github-actions%5Bbot%5D/events{/privacy}",
    "received_events_url": "https://api.github.com/users/github-actions%5Bbot%5D/received_events",
    "type": "Bot",
    "site_admin": false
  },
  "node_id": "RE_kwDOGpPaZ84DYLiH",
  "tag_name": "0.0.2",
  "target_commitish": "main",
  "name": "",
  "draft": false,
  "prerelease": false,
  "created_at": "2022-01-08 20:14:11 UTC",
  "published_at": "2022-01-08 20:27:20 UTC",
  "assets": [
    {
      "url": "https://api.github.com/repos/Tidal-Zone/App/releases/assets/53505987",
      "id": 53505987,
      "node_id": "RA_kwDOGpPaZ84DMG_D",
      "name": "Info.plist",
      "label": "",
      "content_type": "application/octet-stream",
      "state": "uploaded",
      "size": 2271,
      "download_count": 0,
      "created_at": "2022-01-08 20:27:21 UTC",
      "updated_at": "2022-01-08 20:27:22 UTC",
      "browser_download_url": "https://github.com/Tidal-Zone/App/releases/download/0.0.2/Info.plist"
    },
    {
      "url": "https://api.github.com/repos/Tidal-Zone/App/releases/assets/53505990",
      "id": 53505990,
      "node_id": "RA_kwDOGpPaZ84DMG_G",
      "name": "LICENSE.txt",
      "label": "",
      "content_type": "text/plain; charset=utf-8",
      "state": "uploaded",
      "size": 34523,
      "download_count": 0,
      "created_at": "2022-01-08 20:27:21 UTC",
      "updated_at": "2022-01-08 20:27:21 UTC",
      "browser_download_url": "https://github.com/Tidal-Zone/App/releases/download/0.0.2/LICENSE.txt"
    },
    {
      "url": "https://api.github.com/repos/Tidal-Zone/App/releases/assets/53505989",
      "id": 53505989,
      "node_id": "RA_kwDOGpPaZ84DMG_F",
      "name": "Package.resolved",
      "label": "",
      "content_type": "application/octet-stream",
      "state": "uploaded",
      "size": 311,
      "download_count": 0,
      "created_at": "2022-01-08 20:27:21 UTC",
      "updated_at": "2022-01-08 20:27:22 UTC",
      "browser_download_url": "https://github.com/Tidal-Zone/App/releases/download/0.0.2/Package.resolved"
    },
    {
      "url": "https://api.github.com/repos/Tidal-Zone/App/releases/assets/53505986",
      "id": 53505986,
      "node_id": "RA_kwDOGpPaZ84DMG_C",
      "name": "README.md",
      "label": "",
      "content_type": "application/octet-stream",
      "state": "uploaded",
      "size": 4331,
      "download_count": 0,
      "created_at": "2022-01-08 20:27:21 UTC",
      "updated_at": "2022-01-08 20:27:21 UTC",
      "browser_download_url": "https://github.com/Tidal-Zone/App/releases/download/0.0.2/README.md"
    },
    {
      "url": "https://api.github.com/repos/Tidal-Zone/App/releases/assets/53505988",
      "id": 53505988,
      "node_id": "RA_kwDOGpPaZ84DMG_E",
      "name": "Sandbox.entitlements",
      "label": "",
      "content_type": "application/octet-stream",
      "state": "uploaded",
      "size": 1212,
      "download_count": 0,
      "created_at": "2022-01-08 20:27:21 UTC",
      "updated_at": "2022-01-08 20:27:21 UTC",
      "browser_download_url": "https://github.com/Tidal-Zone/App/releases/download/0.0.2/Sandbox.entitlements"
    },
    {
      "url": "https://api.github.com/repos/Tidal-Zone/App/releases/assets/53505991",
      "id": 53505991,
      "node_id": "RA_kwDOGpPaZ84DMG_H",
      "name": "Tidal-Zone-iOS.ipa",
      "label": "",
      "content_type": "application/octet-stream",
      "state": "uploaded",
      "size": 6013456,
      "download_count": 1,
      "created_at": "2022-01-08 20:27:22 UTC",
      "updated_at": "2022-01-08 20:27:23 UTC",
      "browser_download_url": "https://github.com/Tidal-Zone/App/releases/download/0.0.2/Tidal-Zone-iOS.ipa"
    },
    {
      "url": "https://api.github.com/repos/Tidal-Zone/App/releases/assets/53505993",
      "id": 53505993,
      "node_id": "RA_kwDOGpPaZ84DMG_J",
      "name": "Tidal-Zone-macOS.zip",
      "label": "",
      "content_type": "application/zip",
      "state": "uploaded",
      "size": 2412680,
      "download_count": 5,
      "created_at": "2022-01-08 20:27:22 UTC",
      "updated_at": "2022-01-08 20:27:23 UTC",
      "browser_download_url": "https://github.com/Tidal-Zone/App/releases/download/0.0.2/Tidal-Zone-macOS.zip"
    },
    {
      "url": "https://api.github.com/repos/Tidal-Zone/App/releases/assets/53505994",
      "id": 53505994,
      "node_id": "RA_kwDOGpPaZ84DMG_K",
      "name": "Tidal-Zone.png",
      "label": "",
      "content_type": "image/png",
      "state": "uploaded",
      "size": 30111,
      "download_count": 25,
      "created_at": "2022-01-08 20:27:22 UTC",
      "updated_at": "2022-01-08 20:27:22 UTC",
      "browser_download_url": "https://github.com/Tidal-Zone/App/releases/download/0.0.2/Tidal-Zone.png"
    }
  ],
  "tarball_url": "https://api.github.com/repos/Tidal-Zone/App/tarball/0.0.2",
  "zipball_url": "https://api.github.com/repos/Tidal-Zone/App/zipball/0.0.2",
  "body": "Release 0.0.2"
}
```


## All `site.github`:

```
{{ site.github | jsonify }}
```



