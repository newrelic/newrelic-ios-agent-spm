[![Community Project header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Community_Project.png)](https://opensource.newrelic.com/oss-category/#community-project)

# NewRelicAgent

New Relic's mobile monitoring capabilities help you gain deeper visibility into how to analyze your iOS application performance and troubleshoot crashes. You can also examine HTTP and other network performance for unexpected lag, which will in turn help you collaborate more efficiently with your backend teams.

## Installation
1. Select **File > Swift Packages > Add Package Dependency...**.
2. Add the Github URL of the Package file:
  
  ```
  https://github.com/newrelic/newrelic-ios-sdk
  ```
  
>If you receive an `artifact of binary target 'NewRelic' failed extraction: The operation couldn’t be completed. (TSCBasic.StringError error 1.)` error when extracting the package, please close Xcode, delete the Derrived Data folder, re-open Xcode, and try again.
  
3. Select the NewRelic package product, select your target, and select Finish.
4. In your `AppDelegate.swift` file, add this call as the first line of `applicationDidFinishLaunchWithOptions`, replacing `APP_TOKEN` with your [application token](/docs/mobile-apps/viewing-your-application-token):

   ```
   NewRelic.start(withApplicationToken:"<var>APP_TOKEN</var>")
   ```
   To ensure proper instrumentation, you must call the agent on the first line of `didFinishLaunchingWithOptions()`, and run the agent on the main thread. Starting the call later, on a background thread, or asynchronously can cause unexpected or unstable behavior.

5. Add a build script to your target's **Build Phases**. Ensure the new build script is the very last build script. Then paste the following, replacing `APP_TOKEN` with your [application token](/docs/mobile-apps/viewing-your-application-token):

   ```
   SCRIPT=`/usr/bin/find "${SRCROOT}" -name newrelic_postbuild.sh | head -n 1`
   /bin/sh "${SCRIPT}" "<var>APP_TOKEN</var>"
   ```
6. Clean and build your app, then run it in the simulator or other device.


## Getting Started
If you have not created a Mobile Application:

* Click "Add more" in the top right,
* name your application, and
* download the New Relic agent for your platform and follow the instructions.
* You can also select the “Add more data” option from the user menu in the upper right corner of the top navigation, then the iOS button to access the installation page.

If you have previously created a Mobile Application:

* Click the name of your mobile app,
* choose Installation from the Settings section in the left nav, and
* download the New Relic agent for your platform and follow the instructions.

## Support

New Relic hosts and moderates an online forum where customers can interact with New Relic employees as well as other customers to get help and share best practices. Like all official New Relic open source projects, there's a related Community topic in the New Relic Explorers Hub. You can find this project's topic/threads here:

>Add the url for the support thread here: discuss.newrelic.com

**A note about vulnerabilities**

As noted in our [security policy](../../security/policy), New Relic is committed to the privacy and security of our customers and their data. We believe that providing coordinated disclosure by security researchers and engaging with the security community are important means to achieve our security goals.

If you believe you have found a security vulnerability in this project or any of New Relic's products or websites, we welcome and greatly appreciate you reporting it to New Relic through [HackerOne](https://hackerone.com/newrelic).

## License
[Project Name] is licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.
>[If applicable: The [project name] also uses source code from third-party libraries. You can find full details on which libraries are used and the terms under which they are licensed in the third-party notices document.]
