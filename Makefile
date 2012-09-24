default: development

development:
	xcodebuild -configuration Development clean
	xcodebuild -target KisMAC -configuration Development
	xcodebuild -configuration Development

release:
	xcodebuild -configuration Release clean
	xcodebuild -target KisMAC -configuration Release
	xcodebuild -target Kismac.dmg -configuration Release

