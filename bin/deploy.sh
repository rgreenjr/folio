#!/bin/sh

cd ~/code/folio

# build archive
xcodebuild -scheme Deployment archive

# cd to archive
cd ~/Library/Developer/Xcode/Archives/
cd "`ls -1t | head -1`"
cd "`ls -1t | head -1`"
cd Products/Users/rgreen/Applications

# delete bad symbolic links
rm Folio.app/Contents/Frameworks/MacRuby.framework/Headers
rm Folio.app/Contents/Frameworks/MacRuby.framework/MacRuby
rm Folio.app/Contents/Frameworks/MacRuby.framework/Resources
rm Folio.app/Contents/Frameworks/MacRuby.framework/Versions/0.10/Headers

# sign archive
codesign -f -s "3rd Party Mac Developer Application: Ron Green" Folio.app/
