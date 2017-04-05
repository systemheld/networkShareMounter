# NetworkShareMounter

This is a yet another tool to mount network shares. It's supposed to be started by a LaunchAgent on every network change (for automatically remounting) and on start (= on login). Even if the mount was not successfull (e.g. if the Mac is in a remote location without connection to your file servers) no GUI will be displayed and your users are not distracted. Therefore, it is recommended to have a Kerberos Ticket or mounted those shares once manually and saving the password in the keychain. Network shares are fetched from a configurable NSUserDefaults domain - you may set this via MDM oder Script. Here you may use `%USERNAME%` - which will be replaced with the username of the running user. Additionally, if a `SMBHome` attribute for the running user is present, this share will also be mounted. This is the case when the Mac is bound to Active Directioy and the `HomeDirectory` LDAP attribute is set. You may also set this attribute locally if you want:

```sh
dscl . create /Users/<yourusername> SMBHome \\home.your.domain\<yourusername>
```

If you don't want to set the array of shares to mount with MDM, you may use a command like this:

```sh
defaults write <your defaultsdomain> networkShares -array "smb://filer.your.domain/share" "smb://filer2.your.domain/home/Another Share/foobar" "smb://home.your.domain/%USERNAME%"
```

The simplest way though is an MDM with a payload of type `com.apple.ManagedClient.preferences` like this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>networkShares</key>
	<array>
		<string>smb://filer.your.domain/share</string>
		<string>smb://filer2.your.domain/home/Another Share/foobar</string>
		<string>smb://home.your.domain/%USERNAME%</string>
	</array>
</dict>
</plist>
```

You definitely want to change the installation directory, so go to **Build Settings** - **Deployment** - **Installation Directory** and change that for your needs! Logically also change that path in the LaunchAgent Plist, too.

