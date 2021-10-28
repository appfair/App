This is an App Fair Integrate-Release Pull Request.
It acts as a signat to initiate the workflow that
validates and publishes the release of your forked app.

Creating or updating the PR will validate and publish 
your App fork release if the following conditions are met:

1. The title of your Pull Request must be: `app.App-Name`.
   It must match `CFBundleIdentifier` in `Info.plist`.

2. Artifacts must exist for the semantic release tag version.
   It must match `CFBundleShortVersionString` in `Info.plist`.

This PR will be automatically closed upon completion.
Subsequent releases of the app can be published with a new PR.

For more information, see: 

    https://www.appfair.net/#integration-release-pull-requests

