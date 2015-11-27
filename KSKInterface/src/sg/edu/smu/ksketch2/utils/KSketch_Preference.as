/**
 * Copyright 2010-2015 Singapore Management University
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License, v. 2.0. If a copy of the MPL was
 * not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/**
 * Created by ramvibhakar on 05/06/15.
 */
package sg.edu.smu.ksketch2.utils {
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

public class KSketch_Preference {
    private static var prefsFile:File = File.applicationStorageDirectory;
    //This function creates a preferences xml. Can be used in future to store preferences
    //Currently used to check if user has accepted the license agreement in desktop
    public static function createPreferences():void{
        var configFile:File = prefsFile.resolvePath("preferences.xml");
        if(!configFile.exists) {
            var configXML:XML = new XML("<?xml version='1.0' encoding='utf-8' ?><config />");
            var fileStream:FileStream = new FileStream();
            fileStream.open(configFile,FileMode.WRITE);
            fileStream.writeUTFBytes(configXML);
            fileStream.close();
        }
    }
    public static function isPrefsAvailable() {
        var configFile:File = prefsFile.resolvePath("preferences.xml");
        return configFile.exists;
    }
}
}
