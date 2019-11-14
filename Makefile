Release.xcarchive:
	xcodebuild -workspace BeoplayRemoteGUI.xcodeproj/project.xcworkspace -scheme BeoplayRemoteGUI clean archive -configuration Release -archivePath Release.xcarchive
release: Release.xcarchive
release-unsigned-zip:
	xcodebuild -workspace BeoplayRemoteGUI.xcodeproj/project.xcworkspace -scheme BeoplayRemoteGUI clean archive -configuration Release -archivePath Release.xcarchive DEVELOPMENT_TEAM="" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
	mv Release.xcarchive/Products/Applications/BeoplayRemoteGUI.app .
	zip -r BeoplayRemoteGUI BeoplayRemoteGUI.app
clean:
	rm -rf Release.xcarchive
uninstall:
	rm -rf /Applications/BeoplayRemoteGUI.app
install: uninstall release
	cp -rp Release.xcarchive/Products/Applications/BeoplayRemoteGUI.app /Applications
