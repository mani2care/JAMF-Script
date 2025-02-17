# CiscoSecureClient-choices.xml-Composer-Jamf
This repo is for installing Cisco Secure Client, with a choices.xml, assembled with Composer, deploying via JAMF Pro.

1. Create a folder under `/private/tmp/`, using the name of your package (e.g. `org.foo.cisco-secure-client`)
2. Copy the Cisco DMG (e.g. `cisco-secure-client-macos-5.1.6.103-predeploy-k9.dmg`) file, and your your `choices.xml`, into that directory.
3. Drag your package folder (e.g. `org.foo.cisco-secure-client`) to Composer.
4. Replace supplied `postinstall` file with the one in this repo.
5. In Composer, **Build As Package**.

## Resources
* [Rich Trouton: Working with Apple pkgs](https://gist.github.com/rtrouton/002034a14e9d8f4f5b32cd4b0998bc01).
* [JAMF: Adding a Postflight Script to a Package Source](https://learn.jamf.com/en-US/bundle/composer-user-guide-current/page/Adding_a_Postflight_Script_to_a_Package_Source.html)
* [JAMF Idea: Specify ChoiceChangesXML for pkg install within policy](https://ideas.jamf.com/ideas/JN-I-17689)
* [Cisco: Customize macOS Installation of Cisco Secure Client](https://docs.umbrella.com/deployment-umbrella/docs/customize-macos-installation-of-cisco-secure-client)
  - Section 1.
  - Section 2.
  - Take care to note, you *do* need to have an entry for each functional module.
    * [MacAdmins Slack](https://macadmins.slack.com/archives/C0QPT3X1T/p1728446524307819?thread_ts=1725042278.515829&cid=C0QPT3X1T)
```
<dict>
	<key>attributeSetting</key>
	<integer>1</integer>
	<key>choiceAttribute</key>
	<string>selected</string>
	<key>choiceIdentifier</key>
	<string>choice_anyconnect_vpn</string>
</dict>
<dict>
	<key>attributeSetting</key>
	<integer>0</integer>
	<key>choiceAttribute</key>
	<string>selected</string>
	<key>choiceIdentifier</key>
	<string>choice_fireamp</string>
</dict>
```
## Thanks
Many thanks to the Macadmins Slack for ideas, assistance, and sympathy.

