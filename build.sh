#!/bin/bash

xcodebuild install

pkgbuild --root "/tmp/networkShareMounter.dst/" \
--identifier "de.uni-erlangen.rrze.networkShareMounter" \
--version "1.0" \
--install-location "/" \
--sign "Developer ID Installer: Universitaet Erlangen-Nuernberg RRZE (C8F68RFW4L)" \
"/tmp/networkShareMounter.pkg"

rm -rf /tmp/networkShareMounter.dst


