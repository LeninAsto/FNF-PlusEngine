package backend;

import sys.io.Process;
import sys.FileSystem;

class LocaleUtils
{
    public static var use24HourFormat:Null<Bool> = true;
    public static var dateFormat:String = "MM/DD/YYYY";
    
    private static var initialized:Bool = false;
    
    public static function init()
    {
        if (initialized) return;
        
        #if windows
        loadWindowsLocaleSettings();
        #elseif linux
        loadLinuxLocaleSettings();
        #elseif mac
        loadMacLocaleSettings();
        #elseif ios
        loadIOSLocaleSettings();
        #elseif android
        loadAndroidLocaleSettings();
        #end
        
        if (dateFormat == null || dateFormat == "") dateFormat = "MM/DD/YYYY";
        if (use24HourFormat == null) use24HourFormat = true;
        
        initialized = true;
    }
    
    #if windows
    private static function loadWindowsLocaleSettings()
    {
        try {
            var process = new Process("reg", ["query", "HKCU\\Control Panel\\International", "/v", "sShortDate"]);
            var output = process.stdout.readAll().toString();
            process.close();

            var regex = ~/sShortDate\s+REG_SZ\s+(.+)/i;
            if (regex.match(output)) {
                var raw = StringTools.trim(regex.matched(1));
                dateFormat = convertWindowsDateFormat(raw);
            }

            var process2 = new Process("reg", ["query", "HKCU\\Control Panel\\International", "/v", "iTime"]);
            var output2 = process2.stdout.readAll().toString();
            process2.close();
            
            var regex2 = ~/iTime\s+REG_SZ\s+(.+)/i;
            if (regex2.match(output2)) {
                var raw = StringTools.trim(regex2.matched(1));
                use24HourFormat = (raw == "1");
            }
        } catch(e:Dynamic) {
            trace("Windows registry read failed: " + e);
        }
    }
    
    private static function convertWindowsDateFormat(winFormat:String):String
    {
        var fmt = winFormat;
        fmt = ~/[M]+/g.replace(fmt, "MM");
        fmt = ~/[d]+/g.replace(fmt, "DD");
        fmt = ~/[y]+/g.replace(fmt, "YYYY");

        if (fmt.indexOf("MM/DD/YYYY") != -1) return "MM/DD/YYYY";
        if (fmt.indexOf("DD/MM/YYYY") != -1) return "DD/MM/YYYY";
        if (fmt.indexOf("YYYY/MM/DD") != -1 || fmt.indexOf("YYYY-MM-DD") != -1) return "YYYY-MM-DD";
        if (fmt.indexOf("DD.MM.YYYY") != -1) return "DD.MM.YYYY";
        return "MM/DD/YYYY";
    }
    #end
    
    #if linux
    private static function loadLinuxLocaleSettings()
    {
        try {
            var locale = Sys.getEnv("LC_ALL");
            if (locale == null || locale == "") locale = Sys.getEnv("LC_TIME");
            if (locale == null || locale == "") locale = Sys.getEnv("LANG");
            if (locale != null) {
                locale = locale.split(".")[0];
            }

            try {
                var process = new Process("locale", ["-k", "d_fmt"]);
                var output = process.stdout.readAll().toString();
                process.close();
                
                var regex = ~/d_fmt\s*=\s*"([^"]+)"/;
                if (regex.match(output)) {
                    var fmt = regex.matched(1);
                    dateFormat = convertLinuxDateFormat(fmt);
                }
            } catch(e:Dynamic) {}

            try {
                var process2 = new Process("locale", ["-k", "t_fmt"]);
                var output2 = process2.stdout.readAll().toString();
                process2.close();
                
                var regex2 = ~/t_fmt\s*=\s*"([^"]+)"/;
                if (regex2.match(output2)) {
                    var fmt = regex2.matched(1);
                    use24HourFormat = (fmt.indexOf("%H") != -1);
                }
            } catch(e:Dynamic) {}

            if (dateFormat == null && locale != null) {
                dateFormat = getDefaultDateFormatForLocale(locale);
            }
            if (use24HourFormat == null && locale != null) {
                use24HourFormat = getDefaultTimeFormatForLocale(locale);
            }
        } catch(e:Dynamic) {
            trace("Linux locale detection failed: " + e);
        }
    }
    
    private static function convertLinuxDateFormat(linuxFormat:String):String
    {
        var fmt = linuxFormat;
        fmt = ~/%d/g.replace(fmt, "DD");
        fmt = ~/%m/g.replace(fmt, "MM");
        fmt = ~/%Y/g.replace(fmt, "YYYY");
        fmt = ~/%y/g.replace(fmt, "YY");
        fmt = ~/%e/g.replace(fmt, "D");
        fmt = fmt.replace("\"", "").trim();
        
        if (fmt.indexOf("DD/MM/YYYY") != -1) return "DD/MM/YYYY";
        if (fmt.indexOf("MM/DD/YYYY") != -1) return "MM/DD/YYYY";
        if (fmt.indexOf("YYYY-MM-DD") != -1 || fmt.indexOf("YYYY/MM/DD") != -1) return "YYYY-MM-DD";
        if (fmt.indexOf("DD.MM.YYYY") != -1) return "DD.MM.YYYY";
        return "MM/DD/YYYY";
    }
    #end
    
    #if mac
    private static function loadMacLocaleSettings()
    {
        try {
            var process = new Process("defaults", ["read", "-g", "AppleLocale"]);
            var locale = process.stdout.readAll().toString().trim();
            process.close();

            try {
                var process2 = new Process("defaults", ["read", "-g", "AppleICUDateFormatStrings"]);
                var output2 = process2.stdout.readAll().toString();
                process2.close();

                var regex = ~/1\s*=\s*"([^"]+)"/;
                if (regex.match(output2)) {
                    var fmt = regex.matched(1);
                    dateFormat = convertMacDateFormat(fmt);
                }
            } catch(e:Dynamic) {}

            try {
                var process3 = new Process("defaults", ["read", "-g", "AppleICUTimeFormatStrings"]);
                var output3 = process3.stdout.readAll().toString();
                process3.close();
                
                var regex2 = ~/1\s*=\s*"([^"]+)"/;
                if (regex2.match(output3)) {
                    var fmt = regex2.matched(1);
                    use24HourFormat = (fmt.indexOf("H") != -1);
                }
            } catch(e:Dynamic) {}
            
            if (dateFormat == null && locale != null && locale.length > 0) {
                dateFormat = getDefaultDateFormatForLocale(locale);
            }
            if (use24HourFormat == null && locale != null && locale.length > 0) {
                use24HourFormat = getDefaultTimeFormatForLocale(locale);
            }
        } catch(e:Dynamic) {
            trace("macOS defaults read failed: " + e);
        }
    }
    
    private static function convertMacDateFormat(macFormat:String):String
    {
        var fmt = macFormat;
        fmt = ~/M{1,2}/g.replace(fmt, "MM");
        fmt = ~/d{1,2}/g.replace(fmt, "DD");
        fmt = ~/y{4}/g.replace(fmt, "YYYY");
        fmt = ~/y{2}/g.replace(fmt, "YY");
        fmt = fmt.replace("\"", "").trim();
        
        if (fmt.indexOf("MM/DD/YYYY") != -1) return "MM/DD/YYYY";
        if (fmt.indexOf("DD/MM/YYYY") != -1) return "DD/MM/YYYY";
        if (fmt.indexOf("YYYY-MM-DD") != -1 || fmt.indexOf("YYYY/MM/DD") != -1) return "YYYY-MM-DD";
        if (fmt.indexOf("DD.MM.YYYY") != -1) return "DD.MM.YYYY";
        return "MM/DD/YYYY";
    }
    #end
    
    #if ios
    private static function loadIOSLocaleSettings()
    {
        try {
            var lang = Sys.getEnv("AppleLanguages");
            if (lang != null && lang.length > 0) {
                var locale = lang.split(",")[0].replace("\"", "").replace("[", "").replace("]", "");
                dateFormat = getDefaultDateFormatForLocale(locale);
                use24HourFormat = getDefaultTimeFormatForLocale(locale);
            }
        } catch(e:Dynamic) {
            trace("iOS settings read failed: " + e);
        }
    }
    #end
    
    #if android
    private static function loadAndroidLocaleSettings()
    {
        try {
            var locale = Sys.getEnv("LANG");
            if (locale == null || locale == "") locale = Sys.getEnv("LC_ALL");
            if (locale == null || locale == "") locale = Sys.getEnv("LC_TIME");
            if (locale != null && locale != "") {
                locale = locale.split(".")[0];
                dateFormat = getDefaultDateFormatForLocale(locale);
                use24HourFormat = getDefaultTimeFormatForLocale(locale);
            }
        } catch(e:Dynamic) {
            trace("Android locale detection failed: " + e);
        }
    }
    #end

    private static function getDefaultDateFormatForLocale(locale:String):String
    {
        if (locale == null) return "MM/DD/YYYY";
        if (locale.indexOf("en_US") != -1) return "MM/DD/YYYY";
        if (locale.indexOf("en_GB") != -1 || locale.indexOf("en_AU") != -1 ||
            locale.indexOf("en_CA") != -1 || locale.indexOf("fr_") != -1 ||
            locale.indexOf("de_") != -1 || locale.indexOf("it_") != -1 ||
            locale.indexOf("es_") != -1 || locale.indexOf("pt_") != -1 ||
            locale.indexOf("id_") != -1) return "DD/MM/YYYY";
        if (locale.indexOf("ja_") != -1 || locale.indexOf("ko_") != -1 ||
            locale.indexOf("zh_") != -1) return "YYYY-MM-DD";
        if (locale.indexOf("ru_") != -1 || locale.indexOf("pl_") != -1 ||
            locale.indexOf("cs_") != -1) return "DD.MM.YYYY";
        return "MM/DD/YYYY";
    }
    
    private static function getDefaultTimeFormatForLocale(locale:String):Bool
    {
        if (locale == null) return true;
        if (locale.indexOf("en_US") != -1 || locale.indexOf("en_CA") != -1 ||
            locale.indexOf("en_PH") != -1 || locale.indexOf("en_IN") != -1) {
            return false;
        }
        return true;
    }

    public static function formatDateTime(date:Date):String
    {
        init();

        var dt = DateTime.make(date.getFullYear(), date.getMonth() + 1, date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds());
        
        var tz = Timezone.local();

        var dayNames = [
            Language.getPhrase("day_sunday", "Sunday"),
            Language.getPhrase("day_monday", "Monday"),
            Language.getPhrase("day_tuesday", "Tuesday"),
            Language.getPhrase("day_wednesday", "Wednesday"),
            Language.getPhrase("day_thursday", "Thursday"),
            Language.getPhrase("day_friday", "Friday"),
            Language.getPhrase("day_saturday", "Saturday")
        ];
        var monthNames = [
            Language.getPhrase("month_january", "January"),
            Language.getPhrase("month_february", "February"),
            Language.getPhrase("month_march", "March"),
            Language.getPhrase("month_april", "April"),
            Language.getPhrase("month_may", "May"),
            Language.getPhrase("month_june", "June"),
            Language.getPhrase("month_july", "July"),
            Language.getPhrase("month_august", "August"),
            Language.getPhrase("month_september", "September"),
            Language.getPhrase("month_october", "October"),
            Language.getPhrase("month_november", "November"),
            Language.getPhrase("month_december", "December")
        ];
        
        var dayName = dayNames[date.getDay()];
        var monthName = monthNames[date.getMonth()];
        var day = dt.getDate();
        var month = dt.getMonth();
        var year = dt.getYear();

        var datePart = "";
        switch (dateFormat.toUpperCase()) {
            case "MM/DD/YYYY":
                datePart = '$dayName, $monthName $day $year';
            case "DD/MM/YYYY":
                datePart = '$dayName, $day $monthName $year';
            case "YYYY-MM-DD":
                datePart = '$dayName, $year-$month-$day';
            case "DD.MM.YYYY":
                datePart = '$dayName, $day.$month.$year';
            default:
                datePart = '$dayName, $monthName $day $year';
        }

        var timeFormat = use24HourFormat ? "%H:%M" : "%I:%M %p";
        var timePart = tz.format(dt, timeFormat);
        
        return '$datePart - $timePart';
    }
    
    public static function loadDeviceDateTimeSettings():Void { init(); }
    public static function formatDateTimeAccordingToDevice(date:Date):String { return formatDateTime(date); }
}