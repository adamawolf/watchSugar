# watchSugar

An Apple Watch Extension for viewing your Dexcom Share blood sugars values on your watch face.

## How to get started developing

1. Clone repo.
2. Run ```git update-index --assume-unchanged Definitions.h```
3. Install Cocoapods if you haven't already: ```sudo gem install cocoapods```
4. Install dependencies using Cocoapods: ```pod install```

watchSugar uses [Objective Clean](http://objclean.com/) to enforce a conistent syntax. Please install that app and fix all style warnings before sending a pull request.

## A Note About Dexcom Application IDs

In order to authenticate a user's Dexcom Share account with Dexcom's backend a valid Dexcom Application ID is needed. Application IDs are not provided in this repository and must be obtained manually.

Once you have the Dexcom Application ID you wish to use set it in Definitions.h. Please be mindful of step 2. above, if you wish to send me a pull request. You'll know your Dexcom Application ID is functioning as expected when the on-device Login flow is successful.
