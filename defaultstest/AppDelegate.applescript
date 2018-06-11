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
	
	property theTableServerName : "" --bound to server name column in table
	property theTableServerURL : "" --bound to server url column in table
	property theTableServerAPIKey : "" --bound to server API Key column in table
	property theServerTableControllerArray : {} --bound to content of the server table controller, not used
	
	property theTestDefaults: "" --not currently used
	property theSettingsList: {} --what will be the list of records we pull from the prefs file
	property theSettingsExist : "" --are there any settings already there?
	property theServerList : {} --list used to load the table
	property theDefaultsExist : "" --are there currently settings?
	
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
		set my theDefaultsExist to theDefaults's boolForKey:"hasDefaults"
		--current application's NSLog("theDefaultsExist: %@", my theDefaultsExist)
		
		my theSettingsList's addObjectsFromArray:theTempArray --copy all the data from theTempArray into theSettingList, which keeps the
		--latter mutable
		if not my theDefaultsExist then
			display dialog "there are no default settings written at launch"
		end if
		my loadServerTable:(missing value) --load existing data into the server table.
	end applicationWillFinishLaunching_
	
	on loadServerTable:sender --push the saved server array into a table
		set my theServerList to {} --blank out the list for next use
		repeat with x from 1 to count of my theSettingsList --iterate through the settings list to build the record we'll use here
			set theItem to item x of my theSettingsList as record
			set the end of my theServerList to {theTableServerName:serverName of theItem,theTableServerURL:serverURL of theItem,theTableServerAPIKey:serverAPIKey of theItem} --DON'T use "my" here, it really hates it.
		end repeat
		my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of that
		--array controller
		my theServerTableController's addObjects:my theServerList --shove all that data in theServerList into the array controller
		set my theDefaultsExist to theDefaults's boolForKey:"hasDefaults" --grab current state for this every time this function runs
		set my theServerList to {} --blank out the list for next use
	end loadServerTable:
	
	on saveSettings:sender --
		set theTempURL to my theServerURL as text  --Create a temp text version
		set theLastChar to last character of theTempURL --get the last character of the URL
		if theLastChar is "/" then --if it's a trailing "/"
			set theTempURL to text 1 thru -2 of theTempURL --trim the last character of the string
			set my theServerURL to current application's NSString's stringWithString:theTempURL --rewrite theServerURL. As it turns out,
			--you have to use the current application's NSString's stringWithString for this, NOT theServerURL's stringWithString. Beats me
			--scoping maybe? <shrug>
		end if
		set my theServerURL to my theServerURL's stringByAppendingString:"/nagiosxi/api/v1/system/user?apikey=" --NSSTring append
		set thePrefsRecord to {serverName:my theServerName,serverURL:my theServerURL,serverAPIKey:my theServerAPIKey} --build the record
		my theSettingsList's addObject:thePrefsRecord --add the record to the end of the settings list
		set my theDefaultsExist to true --since we're writing a setting, we want to set this correctly.
		theDefaults's setObject:my theSettingsList forKey:"serverSettingsList" --write the new settings list to defaults
		theDefaults's setBool:my theDefaultsExist forKey:"hasDefaults" --setting hasDefaults to true (1)
		my loadServerTable:(missing value) --reload table with new data
		set my theServerURL to ""
		set my theServerName to ""
		set my theServerAPIKey to ""
	end saveSettings:
	
	on getSettings:sender --re-read data from the defaults file
		my theSettingsList's removeAllObjects() -- blank out theSettingsList since we're reloading it. The () IS IMPORTANT
		set theTempArray to current application's NSArray's arrayWithArray:(theDefaults's arrayForKey:"serverSettingsList") --since we're
		--re-reading from the disk, we have to do the temp NSArray --> NSMutableArray dance again.
		my theSettingsList's addObjectsFromArray:theTempArray --reload our NSMutableArray so it doesn't get coerced to NSArray
		set my theDefaultsExist to theDefaults's boolForKey:"hasDefaults" --pull the "do we even have default settings" flag
		my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of that
		my loadServerTable:(missing value) --reload table with read data
	end getSettings:
	
	on clearSettings:sender
		theDefaults's removeObjectForKey:"serverSettingsList" --blank out defaults plist on disk
		theDefaults's removeObjectForKey:"hasDefaults" --blank out the hasDefaults key, that is now false (0). Well, actually, it's nonexistent
		--but really, that's the same thing for our needs. We can fix this later if we want.
		my theSettingsList's removeAllObjects() -- blank out theSettingsList since we're reloading it. The () IS IMPORTANT
		my loadServerTable:(missing value) --reload table with read data, in this case, the table should be blank
	end clearSettings
	
	on deleteServer:sender
		set theTestIndex to my theServerTable's selectedRow() --get the index of the currently selected row from the table
		my theSettingsList's removeObjectAtIndex:theTestIndex --delete that from theSettingsList. Since the table is built from theSettingsSlist,
		--this is somewhat dicey, but safe given that we immediately rebuild the table AND the prefs on clicking the button.
		--if we want to delete multiple servers, this will need to be changed.
		
		--reload the server table in the UI. We do this first so the user can see their actions have taken.
		my loadServerTable:(missing value)
		
		--write the new prefs to disk. We really should warn the user that this is not undoable.
		--first, test to make sure the prefs aren't zero length
		set theSettingsListLength to my theSettingsList's |count|() --get number of entries in the array.
		--we need to do this before we act on writing things to disk.
		if theSettingsListLength = 0 then --if the list is empty (we just deleted the last thing) then we'll call clear settings and save time
			--since that's what clear settings does, if you think about it
			my clearSettings:(missing value) --this handles explicitly clearing the defaults AND hasDefaults for us.
		else
			--so we have entries in the array, let's write that to disk
			set my theDefaultsExist to true --if we're in this stage of the if, there's at least one row in theSettingsList,
			--so we want to make sure theDefaultsExist is correct.
			theDefaults's setObject:my theSettingsList forKey:"serverSettingsList" --write the new settings list to defaults
			theDefaults's setBool:my theDefaultsExist forKey:"hasDefaults" --setting hasDefaults to true (1), this way we avoid the
			--"but I thought it was okay" problem. We don't think we know what hasDefaults is on exit, we KNOW

			
		end if
		my loadServerTable:(missing value) -- regardless of the if statement tree, we want to do this for both. if this ever gets really big
		--we'll change this behavior, but it would have to get pretty damned big to be a problem.
		
	end deleteServer:
	
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits
		return current application's NSTerminateNow
	end applicationShouldTerminate_
	
	on applicationShouldTerminateAfterLastWindowClosed:sender
		return true --quit when window is closed
	end applicationShouldTerminateAfterLastWindowClosed:
	
end script
