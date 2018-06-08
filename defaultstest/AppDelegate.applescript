--
--  AppDelegate.applescript
--  defaults test
--
--  Created by John Welch on 6/7/18.
--  Copyright © 2018 John Welch. All rights reserved.
--

script AppDelegate
	property parent : class "NSObject"
	--FOR THE LOVE OF GOD, REMEMBER TO MAKE SURE THE ONLY THING IN A TABLE COLUMN IS THE COLUMN NAME AND THE TEXT CELL,
	--THAT TABLE CELL VIEW SHIT WILL MAKE YOU CRAZY
	
	-- IBOutlets
	property theWindow : missing value
	property theDefaults : missing value
	property theSettingsController : missing value -- server defaults array referencing outlet
	property theServerTable : missing value --table view referencing outlet
	property theServerTableController : missing value --server table array controller referencing outlet
	

	
	property theServerName : "" --bound to server name text field
	property theServerURL : "" --bound to server URL text field
	property theServerAPIKey : "" --bound to server API Key text field
	
	property theTableServerName : ""
	property theTableServerURL : ""
	property theTableServerAPIKey : ""
	property theServerTableControllerArray : {}
	
	property theTestDefaults: ""
	property theSettingsList: {} --what will be the list of records we pull from the prefs file
	property theServerList : {} --list used to load the table
	
	--this next line is only here to show how to clear out defaults if you're using a shared defautls controller
	--current application's NSUserDefaultsController's sharedUserDefaultsController()'s revertToInitialValues: initialDefaults
	
	on applicationWillFinishLaunching_(aNotification)
		set theDefaults to current application's NSUserDefaults's standardUserDefaults() --make theDefaults the container
		--for defaults operations
		theDefaults's registerDefaults:{serverSettingsList:""} --sets up "serverSettingsList" as a valid defaults key
		--of the keys used in the defaults
		set my theSettingsList to current application's NSMutableArray's arrayWithCapacity:1 --initialize the internal array
		--we use for this
		set theTempArray to current application's NSArray's arrayWithArray:(theDefaults's arrayForKey:"serverSettingsList") --we do this because
		--NSDefaults arrayForKey coerces NSMutableArray to NSArray, which is annoying
		my theSettingsList's addObjectsFromArray:theTempArray --copy all the data from theTempArray into theSettingList, which keeps the
		--latter mutable
		--set my theSettingsList to theDefaults's arrayForKey:"serverSettingsList" --load the settings list (important for array controller)
		--set x to my theSettingsController's selectedObjects()'s firstObject() --this grabs the initial record
		my loadServerTable:(missing value) --load existing data into the server table.
	end applicationWillFinishLaunching_
	
	on loadServerTable:sender
		set my theServerList to {} --blank out the list for next use
		--current application's NSLog("theServerList at start ot loadServer: %@", my theServerList)
		repeat with x from 1 to count of my theSettingsList
			set theItem to item x of my theSettingsList as record
			set the end of my theServerList to {theTableServerName:serverName of theItem,theTableServerURL:serverURL of theItem,theTableServerAPIKey:serverAPIKey of theItem} --DON'T use "my" here, it really hates it.
		end repeat
		my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of that
		--array controller
		my theServerTableController's addObjects:my theServerList --shove all that data in theServerList into the array controller
		set my theServerList to {} --blank out the list for next use
	end loadServerTable:
	
	on saveSettings:sender
		set thePrefsRecord to {serverName:my theServerName,serverURL:my theServerURL,serverAPIKey:my theServerAPIKey} --build the record
		my theSettingsList's addObject:thePrefsRecord --add the record to the end of the settings list
		theDefaults's setObject:my theSettingsList forKey:"serverSettingsList" --write the new settings list to defaults
		my loadServerTable:(missing value) --reload table with new data
	end saveSettings:
	
	on getSettings:sender --re-read data from the defaults file
		my theSettingsList's removeAllObjects() -- blank out theSettingsList since we're reloading it. The () IS IMPORTANT
		set theTempArray to current application's NSArray's arrayWithArray:(theDefaults's arrayForKey:"serverSettingsList")
		my theSettingsList's addObjectsFromArray:theTempArray
		my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of that
		my loadServerTable:(missing value) --reload table with read data
	end getSettings:
	
	on clearSettings:sender
		--theDefaults's removeObjectForKey:"serverName"
		--theDefaults's removeObjectForKey:"serverURL"
		--theDefaults's removeObjectForKey:"serverAPIKey"
		theDefaults's removeObjectForKey:"serverSettingsList" --blank out defaults plist on disk
		my theSettingsList's removeAllObjects() -- blank out theSettingsList since we're reloading it. The () IS IMPORTANT
		my loadServerTable:(missing value) --reload table with read data, in this case, the table should be blank
	end clearSettings
	
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits
		return current application's NSTerminateNow
	end applicationShouldTerminate_
	
	on applicationShouldTerminateAfterLastWindowClosed:sender
		return true
	end applicationShouldTerminateAfterLastWindowClosed:
	
end script
