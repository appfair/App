<p align="center">
<a alt="Download the App Fair app for macOS 12" href="https://appfair.app"><img alt="The App Fair icon" align="center" style="height: 20vh;" src="https://appfair.net/appfair-icon.svg" /></a>
</p>
<p align="center">
   <a href="https://discord.gg/ZrnGQP6p3d">
    <img alt="Discord Server" src="https://img.shields.io/discord/959553736450142268?color=7489d5&logo=discord&logoColor=ffffff" />
  </a>
  <img alt="Status: Development" src="https://img.shields.io/static/v1?label=Status&message=Development+(beta)&color=violet">
  <a href="https://hosted.weblate.org/projects/appfair/app-fair/">
   <img alt="Weblate project translated" src="https://img.shields.io/weblate/progress/appfair?color=cyan">
  </a>
  <img alt="Licensed under the AGPL 3.0" src="https://img.shields.io/static/v1?label=License&message=AGPL+3.0&color=forestgreen">
</p>

# The App Fair


**App Fair.app** is a tool for macOS 12 that
provides the ability to browse, search for, download,
install, and update apps from a selection of appsource catalogs
and Homebrew cask repositories.

For more information, and to download the app,
visit the home page at [appfair.app](https://www.appfair.app).
To learn more about the appfair.net process for building and
publishing apps, visit [appfair.net](https://www.appfair.net).

## Description

The App Fair app enables users to search, browse, install, and update
applications from a free and unlimited online catalog.

## Installation

The latest release can be downloaded from the homepage
at [appfair.app](https://www.appfair.app), or from
the [GitHub releases](https://github.com/App-Fair/App/releases)
page.

Alternatively,
[Homebrew](https://brew.sh/) users can install 
App Fair directly with the command:

```shell
$ brew install appfair/app/app-fair
```

## Development

The App Fair.app is built and maintained using the
[appfair.net](https://www.appfair.net) system.

### Translations

Translators are invited to help translate the App Fair strings into
their local language.
We use the "Weblate" translation interface to enable
translation contirbutions without needing to use
source control management directly.

Start contributing by going to:
[hosted.weblate.org/projects/appfair/app-fair](https://hosted.weblate.org/projects/appfair/app-fair/#translations).

### Internal Notes

App Fair.app is built and distributed as a (mostly) standard
appfair.net app. One difference is that updates to the App Fair.app
itself are automatically downloaded and installed when
a new release is created when older clients next launch or refresh their
catalogs.

Another difference from its peer appfair.net apps
in that it is **not** sandboxed.
This is unfortunately necessary in order 
to allow the process to install other apps.

The final major difference is that App Fair.app
is signed and notarized, which is not otherwise a
requirement for appfair.net apps.
