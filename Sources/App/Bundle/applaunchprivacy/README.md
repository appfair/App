
This folder contains the source code for the App Fair's
App Launch Privacy tool, which enables launching applications
without telemetry being sent to third-party servers.

The tool can be run as a user with write access to /etc/hosts
with the command:

```
$ sudo swift run applaunchprivacy enable
```

Or it can be compiled to an executable and have the setuid bit
placed on it in order to be run without elevated privileges:

```
$ swift build -c release --arch arm64 --arch x86_64 
$ sudo /usr/sbin/chown root ./.build/apple/Products/Release/applaunchprivacy
$ sudo /bin/chmod 4750 ./.build/apple/Products/Release/applaunchprivacy
```

See the comments in main.swift for more details.

