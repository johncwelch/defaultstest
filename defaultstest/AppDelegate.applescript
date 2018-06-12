--
--  AppDelegate.applescript
--  defaults test
--
--  Created by John Welch on 6/7/18.
--  Copyright © 2018 John Welch. All rights reserved.

    --many, many, HUGE THANKS to Shane Stanley, MacScripter.net, Chris Nebel and many other people on twitter for helping me get this.
    --this is just a thing I wrote so I could test basic server management for the Nagios REST API. It doesn't *do* anything with Nagios
    --but I needed to learn how to do defaults. If you're managing truly large numbers of servers, this is not optimal, but for my needs,
    --~ten servers, it's jes' peachy.

    --yes, I am aware I could probably do what I want by manipulating the array controller directly, but this is a good first start.
    --this is why we have forks in source control management :-P
    --that's the next thing i'm doing with this.
--

script AppDelegate
    property parent : class "NSObject"
    --FOR THE LOVE OF GOD, REMEMBER TO MAKE SURE THE ONLY THING IN A TABLE COLUMN IS THE COLUMN NAME AND THE TEXT CELL,
    --THAT TABLE CELL VIEW SHIT WILL MAKE YOU CRAZY
    
    -- IBOutlets
    property theWindow : missing value --referenceing outlet for the main window
    property theDefaults : missing value --referencing outlet for our NSDefaults object
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
    property theSettingsExist : "" --are there any settings already there?
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
        --current application's NSLog("theDefaultsExist: %@", my theDefaultsExist) --this is just here for when I need it elsewhere, I can
        --copy/paste easier
        
        my theSettingsList's addObjectsFromArray:theTempArray --copy all the data from theTempArray into theSettingList, which keeps the
        --latter mutable
        if not my theDefaultsExist then
            display dialog "there are no default settings existing at launch" --my version of a first run warning. Slick, ain't it.
        end if
        my loadServerTable:(missing value) --load existing data into the server table.
        tell my theServerTable to setDoubleAction:"deleteServer:" --this ties a doubleclick in the server to deleting that server.
    end applicationWillFinishLaunching_
    
    on loadServerTable:sender --push the saved server array theSettingsList into an array controller that runs a table
        my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of that
        --array controller
        my theServerTableController's addObjects:my theSettingsList --shove the current contents of theSettingsList into the array controller
        set my theDefaultsExist to theDefaults's boolForKey:"hasDefaults" --grab current state for this every time this function runs
    end loadServerTable:
    
    on saveSettings:sender --this saves the info the user typed in, and gloms the nagios api URL onto the end. Saves time.
        set theTempURL to my theServerURL as text  --Create a temp text version --I did this all AppleScript style, because it works
        --and I was able to get it done faster this way. It may not execute as fast, but given the data sizes we're talking about,
        --I doubt it's a problem on anything faster than a IIsi
        
        set theLastChar to last character of theTempURL --get the last character of the URL
        
        if theLastChar is "/" then --if it's a trailing "/"
            set theTempURL to text 1 thru -2 of theTempURL --trim the last character of the string
            set my theServerURL to current application's NSString's stringWithString:theTempURL --rewrite theServerURL. As it turns out,
            --you have to use the current application's NSString's stringWithString for this, NOT theServerURL's stringWithString. Beats me
            --scoping maybe? <shrug>
        end if
        
        set my theServerURL to my theServerURL's stringByAppendingString:"/nagiosxi/api/v1/system/user?apikey=" --NSSTring append
        --this has the side benefit of showing up in the text box, so the user has a nice visual feedback outside of the table
        --for about .something seconds.
        
        set thePrefsRecord to {theTableServerName:my theServerName,theTableServerURL:my theServerURL,theTableServerAPIKey:my theServerAPIKey} --build the record
        
        my theSettingsList's addObject:thePrefsRecord --add the record to the end of the settings list
        
        set my theDefaultsExist to true --since we're writing a setting, we want to set this correctly.
        
        theDefaults's setObject:my theSettingsList forKey:"serverSettingsList" --write the new settings list to defaults
        theDefaults's setBool:my theDefaultsExist forKey:"hasDefaults" --setting hasDefaults to true (1)
        
        my loadServerTable:(missing value) --reload the server table function call. There's some cleanup that we'd have to dupe if we did it here
        --anyway, so there's no point in not doing this
    
        set my theServerURL to "" --if you don't want the text fields to clear, delete/comment out these last three lines
        set my theServerName to ""
        set my theServerAPIKey to ""
    end saveSettings:
    
    on getSettings:sender --re-read ALL data from the defaults file
        my theSettingsList's removeAllObjects() -- blank out theSettingsList since we're reloading it. The () IS IMPORTANT
        set theTempArray to current application's NSArray's arrayWithArray:(theDefaults's arrayForKey:"serverSettingsList") --since we're
        --re-reading from the disk, we have to do the temp NSArray --> NSMutableArray dance again.
        my theSettingsList's addObjectsFromArray:theTempArray --reload our NSMutableArray so it doesn't get coerced to NSArray
        set my theDefaultsExist to theDefaults's boolForKey:"hasDefaults" --pull the "do we even have default settings" flag
        my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of that
        my theServerTableController's addObjects:my theSettingsList --shove the current contents of thePrefsRecord into the array controller
        --my loadServerTable:(missing value) --reload table with read data
    end getSettings:
    
    on clearSettings:sender
        theDefaults's removeObjectForKey:"serverSettingsList" --blank out defaults plist on disk
        theDefaults's removeObjectForKey:"hasDefaults" --blank out the hasDefaults key, that is now false (0). Well, actually, it's nonexistent
        --but really, that's the same thing for our needs. We can fix this later if we want.
        my theSettingsList's removeAllObjects() -- blank out theSettingsList. The () IS IMPORTANT
        my theServerTableController's removeObjects:(theServerTableController's arrangedObjects()) --blow out contents of that
        --array controller here, rather than rerunning the loadserver function just to load an empty list
    end clearSettings
    
	on deleteServer:sender
		my theServerTableController's remove:(theServerTableController's selectedObjects()) --deletes the selected row right out of the controller
		--my god, this was so easy once I doped it out
		my theSettingsList's removeAllObjects() --blow out theSettingsList
		my theSettingsList's addObjectsFromArray:(theServerTableController's arrangedObjects()) --rebuild it from theServerTableController
		--this way, at least in here, theServerTableController and theSettingsList are ALWAYS in sync and that's IMPORTANT.

		--current application's NSLog("remaining objects in theServerTableController: %@", my theServerTableController's arrangedObjects())

	   set theServerTableControllerObjectCount to my theServerTableController's arrangedObjects()'s |count|() --get number of objects left in
        --the controller
	   --log theServerTableControllerObjectCount as text

	   if theServerTableControllerObjectCount = 0 then --if the list is empty (we just deleted the last thing) then we'll call clear settings and
		   --save time since that's what clear settings does, if you think about it
		   my clearSettings:(missing value) --this handles explicitly clearing the defaults AND hasDefaults for us.
		   --technically that may not be necessary, but this way we KNOW.

	   else --so we have entries in the array, let's write that to disk
		   --what's interesting is that we already have theServerTableController and theSettingsList in the desired state, so this gets SIMPLE
		   set my theDefaultsExist to true --since we're writing a setting, we want to set this correctly.

		   theDefaults's setObject:my theSettingsList forKey:"serverSettingsList" --write the new settings list to defaults
		   theDefaults's setBool:my theDefaultsExist forKey:"hasDefaults" --setting hasDefaults to true (1), this way we avoid the
		   --"but I thought it was okay" problem. We don't think we know what hasDefaults is on exit, we KNOW
	   end if
    end deleteServer:
    
    on applicationShouldTerminate_(sender)
        -- Insert code here to do any housekeeping before your application quits
        return current application's NSTerminateNow
    end applicationShouldTerminate_
    
    on applicationShouldTerminateAfterLastWindowClosed:sender
        return true --quit when window is closed
    end applicationShouldTerminateAfterLastWindowClosed:
    
end script
