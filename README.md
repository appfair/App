# This Is Your App

This project contains the shell of an [App Fair](https://www.appfair.net) app,
which is an application distribution platform for native SwiftUI applications.
Fork this project to use as the basis for your own app, 
then submit a PR to have it automatically built and distributed
through the [App Fair.app catalog browser for macOS](https://www.appfair.net).

The only requirement to distribute your app is a 
[free GitHub account](https://github.com/signup) with an
[associated `.edu` e-mail address](https://github.com/settings/profile), 
as well as an idea for a fun or useful app.

To get started building your own app using only your web browser:

1. Create a [new free GitHub Organization](https://github.com/account/organizations/new?plan=team_free). 
   The organization's name will uniquely identify your app and 
   should consist of two short words (no numbers) separated by a single hyphen.
   For example: "Cookie-Time"
2. [Fork the appfair/App repository](https://github.com/appfair/App/fork) 
   into your new "App-Name" organization. 
   An app-org can only contain a single app that is named "App" (literally). 
   It must be publicly accessible at `github.com/App-Name/App.git`
3. Update your App settings: enable Issues and Discussions for 
   your `App-Name/App` fork. 
   Issues & Discussions are required to remain active to facilitate
   communication channels between the developer and end-users of the app. 
4. [Edit Info.plist](../../edit/main/Info.plist) and update 
   the `CFBundleName` to be "App Org" (the app name with a space) 
   and `CFBundleIdentifier` to be "app.App-Name".
5. [Edit Sources/App/AppContainer.swift](../../edit/main/Sources/App/AppContainer.swift) 
   and add some code to your app!
6. [Create a Pull Request](../../compare) with your changes, and submit 
   the PR to the base `/appfair/App/` repository. 
   The PR itself must remain open for as long as the app is to be available.
   Updating the PR is the mechanism for triggering 
   the [App Fair actions](https://github.com/appfair/App/actions) 
   that validates and builds your release and updates the App Fair catalog.
7. [Edit this README.md](../../edit/main/README.md) file to
   describe and document your app. 

Your successful release build will shortly become available in 
the [App Fair](https://www.appfair.net) catalog browser application.

Download, share and enjoy!
