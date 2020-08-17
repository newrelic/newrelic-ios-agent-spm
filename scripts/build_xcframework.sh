#!/usr/bin/env bash
xcodebuild -create-xcframework \
	-framework build/iphoneos/Agent_iOS.framework \
	-framework build/iphonesimulator/Agent_iOS.framework \
	-framework build/appletvsimulator/Agent_tvos.framework/ \
	-framework build/appletvos/Agent_tvos.framework \
	-framework build/macosx/Agent_iOS.framework 	\
	-output build/Agent.xcframework