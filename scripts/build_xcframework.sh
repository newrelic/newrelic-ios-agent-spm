#!/usr/bin/env bash -x
xcodebuild -create-xcframework \
	-framework build/iphoneos/NewRelic.framework \
	-framework build/iphonesimulator/NewRelic.framework \
	-framework build/appletvsimulator/NewRelic.framework/ \
	-framework build/appletvos/NewRelic.framework \
	-framework build/macosx/NewRelic.framework 	\
	-output build/NewRelic.xcframework


cp -r dsym-upload-tools/ build/NewRelic.xcframework/Resources/