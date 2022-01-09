---
layout: page
---

{% assign appname = site.github.owner_name %}


<img height="50" width="50" src="{{ site.github.repository_url }}/releases/latest/download/{{ site.github.owner_name }}.png" /> {{ appname }} is an app.

## Links:

  * [Discussions: {{ site.github.repository_url }}/discussions]({{ site.github.repository_url }}/discussions)
  * [Issues: {{ site.github.repository_url }}/issues]({{ site.github.repository_url }}/issues)

This page was last updated at {{ "now" | date: "%Y-%m-%d %H:%M" }}.

Installation:

  1. Launch [appfair://app/{{ appname }}](appfair://app/{{ site.github.owner_name }}) using the [App Fair](https://www.app-fair.app).
  2. Run: `brew install appfair/app/{{ site.github.owner_name | slugify }}`
  3.  Download: [{{ site.github.owner_name }}-macOS.zip]({{ site.github.repository_url }}/releases/latest/download/{{ site.github.owner_name }}-macOS.zip)


