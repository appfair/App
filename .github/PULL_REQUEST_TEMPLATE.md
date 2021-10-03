## App Fair Integrate-Release Pull Request

This Pull Request acts as a signal to initiate the
[App Fair Integrate-Release process](https://www.appfair.net/#the-integrate-pull-request).
Creating or updating the PR will build a new release of
your App fork.

The title of your Pull Request must be of the form:
`app.App-Name`,
where `app.App-Name` is the `CFBundleIdentifier` 
in your `Info.plist` metadata file.

Note that these integration Pull Requests will never be 
merged into the base /App/ repository.
They are simply triggers to initiate the app integration process
at [/appfair/App/actions](https://github.com/appfair/App/actions).


You can leave open a PR and just update it in order to
initiate a new release.
Subsequent releases must increment the version both in the
`Info.plist` and in the PR title.

For more information, see the documentation at
[https://www.appfair.net](https://www.appfair.net).
