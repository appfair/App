## App Fair Integrate-Release Pull Request

This Pull Request acts as a signal to initiate the
[App Fair Integrate-Release process](https://www.appfair.net/#the-integrate-pull-request).
Creating or updating the PR will build a new release of
your App fork.

The title of your Pull Request must be of the form:
`app.App-Org v1.2.3`,
where `app.App-Org` is the `CFBundleIdentifier` 
and the version is the `CFBundleShortVersionString`
in your `Info.plist` metadata file.

Note that these integration Pull Requests will not be 
merged into the base /App/ repository.

You can leave open a PR and just update it in order to
initiate a new release.
Subsequent releases must increment the version both in the
`Info.plist` and in the PR title.

In the event you would like to propose changes to the underlying
`/App/` scaffold, please instead make a pull request against the
[Fair scaffold](https://github.com/appfair/Fair/tree/main/Sources/FairCore/Bundle/Scaffold/default),
which is the canonical source of the contents of this repostory.


