## Swift script used to upload a builds symbols to New Relic.
### Intended to be run from a Xcode build phase.

 1. In Xcode, select your project in the navigator, then click on the application target.
 2. Select the Build Phases tab in the settings editor.
 3. Click the + icon above Target Dependencies and choose New Run Script Build Phase.
 4. Add the following lines of code to the new phase, pasting in the
     application token as "APP_TOKEN" from your New Relic dashboard for the app in question.
 
```
    SCRIPT=`/usr/bin/find "${SRCROOT}/../.." -name run-symbol-tool | head -n 1`
    /bin/sh "${SCRIPT}" "APP_TOKEN"
```

Optional:

Note: A few environment variables can be set to modify the behavior of the map or dSYM uploader.
- DSYM_UPLOAD_URL: Host URL to use when uploading to New Relic. default: "https://mobile-symbol-upload.newrelic.com"
- NEWRELIC_SYMBOL_ENDPOINT: Symbol endpoint. default: "map"
- NEWRELIC_DSYM_ENDPOINT: Dsym endpoint. default: "symbol"
- NEWRELIC_SYMBOL_POST_KEY: Symbol Post Key used in Curl. default: "upload"
- NEWRELIC_DSYM_POST_KEY: Dsym Post Key used in Curl. default: "dsym"

Add "--debug" after last line of script to enable debug logs in the output `upload_dsym_results.log` file.

```
    SCRIPT=`/usr/bin/find "${SRCROOT}/../.." -name run-symbol-tool | head -n 1`
    /bin/sh "${SCRIPT}" "APP_TOKEN" --debug
```

DSYM_UPLOAD_URL - define this environment variable above run script to override the New Relic server hostname


```
export DSYM_UPLOAD_URL="https://staging-mobile-symbol-upload.newrelic.com"
```

Repeat this line for each Env Var you'd like to set.

```
export NEWRELIC_SYMBOL_ENDPOINT="map2"
```


- Due to limitations with Swift scripting run-symbol-tool.swift is one file.
   Main script contents are in start() func. Helper functions are categorized at the end.
- Script will first attempt to convert each dSYM into NR map files, 
   then it will combine map files into zip file and upload to New Relic.
   If conversion isn't possible or zipped map files upload fails the dSYMs are uploaded to New Relic.