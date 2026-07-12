package backend;

import haxe.Json;
import sys.io.File;
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
        
        if (dateFormat == null) dateFormat = "MM/DD/YYYY";
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
            
            if (output.indexOf("sShortDate") != -1) {
                var lines = output.split("\n");
                for (line in lines) {
                    if (line.indexOf("sShortDate") != -1) {
                        var parts = line.split("REG_SZ");
                        if (parts.length > 1) {
                            dateFormat = StringTools.trim(parts[1]);
                            break;
                        }
                    }
                }
            }
            
            var process2 = new Process("reg", ["query", "HKCU\\Control Panel\\International", "/v", "iTime"]);
            var output2 = process2.stdout.readAll().toString();
            process2.close();
            
            if (output2.indexOf("iTime") != -1) {
                var lines = output2.split("\n");
                for (line in lines) {
                    if (line.indexOf("iTime") != -1) {
                        var parts = line.split("REG_SZ");
                        if (parts.length > 1) {
                            use24HourFormat = (StringTools.trim(parts[1]) == "1");
                            break;
                        }
                    }
                }
            }
        } catch(e:Dynamic) {
            trace("Could not read Windows registry, using defaults: " + e);
        }
    }
    #end
    
    #if linux
    private static function loadLinuxLocaleSettings()
    {
        try {
            var lang = Sys.getEnv("LANG");
            if (lang != null && lang.length > 0) {
                var locale = lang.split(".")[0];
                
                var process = new Process("locale", ["-k", "d_fmt"]);
                var output = process.stdout.readAll().toString();
                process.close();
                
                if (output.indexOf("d_fmt") != -1) {
                    var lines = output.split("\n");
                    for (line in lines) {
                        if (line.indexOf("d_fmt") != -1) {
                            var parts = line.split("=");
                            if (parts.length > 1) {
                                var fmt = StringTools.trim(parts[1]).replace("\"", "");
                                dateFormat = convertLocaleDateFormat(fmt);
                                break;
                            }
                        }
                    }
                }
                
                var process2 = new Process("locale", ["-k", "t_fmt"]);
                var output2 = process2.stdout.readAll().toString();
                process2.close();
                
                if (output2.indexOf("t_fmt") != -1) {
                    var lines = output2.split("\n");
                    for (line in lines) {
                        if (line.indexOf("t_fmt") != -1) {
                            var parts = line.split("=");
                            if (parts.length > 1) {
                                var fmt = StringTools.trim(parts[1]).replace("\"", "");
                                use24HourFormat = (fmt.indexOf("%H") != -1);
                                break;
                            }
                        }
                    }
                }
                
                if (dateFormat == null) {
                    dateFormat = getDefaultDateFormatForLocale(locale);
                }
                
                if (use24HourFormat == null) {
                    use24HourFormat = getDefaultTimeFormatForLocale(locale);
                }
            }
        } catch(e:Dynamic) {
            trace("Could not read Linux locale settings, using defaults: " + e);
        }
    }
    #end
    
    #if mac
    private static function loadMacLocaleSettings()
    {
        try {
            var process = new Process("defaults", ["read", "-g", "AppleLocale"]);
            var locale = process.stdout.readAll().toString().trim();
            process.close();
            
            if (locale.length > 0) {
                var process2 = new Process("defaults", ["read", "-g", "AppleICUDateFormatStrings"]);
                var output2 = process2.stdout.readAll().toString();
                process2.close();
                
                if (output2.indexOf("1") != -1) {
                    var lines = output2.split("\n");
                    for (line in lines) {
                        if (line.indexOf("1") != -1) {
                            var parts = line.split("=");
                            if (parts.length > 1) {
                                var fmt = StringTools.trim(parts[1]).replace("\"", "").replace(";", "");
                                dateFormat = convertLocaleDateFormat(fmt);
                                break;
                            }
                        }
                    }
                }
                
                var process3 = new Process("defaults", ["read", "-g", "AppleICUTimeFormatStrings"]);
                var output3 = process3.stdout.readAll().toString();
                process3.close();
                
                if (output3.indexOf("1") != -1) {
                    var lines = output3.split("\n");
                    for (line in lines) {
                        if (line.indexOf("1") != -1) {
                            var parts = line.split("=");
                            if (parts.length > 1) {
                                var fmt = StringTools.trim(parts[1]).replace("\"", "").replace(";", "");
                                use24HourFormat = (fmt.indexOf("HH") != -1);
                                break;
                            }
                        }
                    }
                }
                
                if (dateFormat == null) {
                    dateFormat = getDefaultDateFormatForLocale(locale);
                }
                
                if (use24HourFormat == null) {
                    use24HourFormat = getDefaultTimeFormatForLocale(locale);
                }
            }
        } catch(e:Dynamic) {
            trace("Could not read macOS settings, using defaults: " + e);
        }
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
            trace("Could not read iOS settings, using defaults: " + e);
        }
    }
    #end
    
    #if android
    private static function loadAndroidLocaleSettings()
    {
        try {
            var lang = Sys.getEnv("LANG");
            if (lang == null || lang == "") {
                lang = Sys.getEnv("LC_ALL");
            }
            if (lang == null || lang == "") {
                lang = Sys.getEnv("LC_TIME");
            }
            if (lang == null || lang == "") {
                lang = Sys.getEnv("LC_MESSAGES");
            }
            
            if (lang != null && lang != "") {
                var localeParts = lang.split(".");
                var localeStr = localeParts[0];
                
                trace("Android locale detected via env: " + localeStr);
                
                dateFormat = getDefaultDateFormatForLocale(localeStr);
                use24HourFormat = getDefaultTimeFormatForLocale(localeStr);
            } else {
                dateFormat = "MM/DD/YYYY";
                use24HourFormat = true;
            }
        } catch(e:Dynamic) {
            trace("Could not detect Android locale via env, using defaults: " + e);
            dateFormat = "MM/DD/YYYY";
            use24HourFormat = true;
        }
    }
    #end
    
    private static function getDefaultDateFormatForLocale(locale:String):String
    {
        if (locale == null) return "MM/DD/YYYY";
        
        if (locale.indexOf("en_US") != -1) {
            return "MM/DD/YYYY";
        } else if (locale.indexOf("en_GB") != -1 || locale.indexOf("en_AU") != -1 || 
                  locale.indexOf("en_CA") != -1 || locale.indexOf("fr_") != -1 ||
                  locale.indexOf("de_") != -1 || locale.indexOf("it_") != -1 ||
                  locale.indexOf("es_") != -1 || locale.indexOf("pt_") != -1 ||
                  locale.indexOf("id_") != -1) {
            return "DD/MM/YYYY";
        } else if (locale.indexOf("ja_") != -1 || locale.indexOf("ko_") != -1 ||
                  locale.indexOf("zh_") != -1) {
            return "YYYY-MM-DD";
        } else if (locale.indexOf("ru_") != -1 || locale.indexOf("pl_") != -1 ||
                  locale.indexOf("cs_") != -1) {
            return "DD.MM.YYYY";
        }
        
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
    
    public static function convertLocaleDateFormat(localeFormat:String):String
    {
        if (localeFormat == null) return "MM/DD/YYYY";
        
        var format = localeFormat;
        format = format.replace("%d", "DD");
        format = format.replace("%m", "MM");
        format = format.replace("%Y", "YYYY");
        format = format.replace("%y", "YY");
        format = format.replace("%e", "D");
        format = format.replace("\"", "").trim();
        
        if (format.indexOf("DD/MM/YYYY") != -1 || format.indexOf("D/M/YYYY") != -1) {
            return "DD/MM/YYYY";
        } else if (format.indexOf("MM/DD/YYYY") != -1 || format.indexOf("M/D/YYYY") != -1) {
            return "MM/DD/YYYY";
        } else if (format.indexOf("YYYY-MM-DD") != -1) {
            return "YYYY-MM-DD";
        } else if (format.indexOf("DD.MM.YYYY") != -1 || format.indexOf("D.M.YYYY") != -1) {
            return "DD.MM.YYYY";
        } else if (format.indexOf("YYYY/MM/DD") != -1) {
            return "YYYY-MM-DD";
        }
        
        return "MM/DD/YYYY";
    }
    
    public static function formatDateTime(date:Date):String
    {
        init();
        
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
        var day = date.getDate();
        var month = date.getMonth() + 1;
        var year = date.getFullYear();
        var hours = date.getHours();
        var minutes = date.getMinutes();
        
        var minutesStr = (minutes < 10) ? "0" + minutes : Std.string(minutes);
        
        var timeStr = "";
        if (use24HourFormat) {
            timeStr = '$hours:$minutesStr';
        } else {
            var amPm = hours >= 12 ? "PM" : "AM";
            var hour12 = hours % 12;
            if (hour12 == 0) hour12 = 12;
            timeStr = '$hour12:$minutesStr $amPm';
        }
        
        var dateStr = "";
        switch (dateFormat.toUpperCase()) {
            case "MM/DD/YYYY":
                dateStr = '$dayName, $monthName $day $year';
            case "DD/MM/YYYY":
                dateStr = '$dayName, $day $monthName $year';
            case "YYYY-MM-DD":
                dateStr = '$dayName, $year-$month-$day';
            case "DD.MM.YYYY":
                dateStr = '$dayName, $day.$month.$year';
            default:
                dateStr = '$dayName, $monthName $day $year';
        }
        
        return '$dateStr - $timeStr';
    }

    // Backwards-compatible wrapper used by older codepaths
    public static function loadDeviceDateTimeSettings():Void
    {
        init();
    }

    // Backwards-compatible name used across the codebase
    public static function formatDateTimeAccordingToDevice(date:Date):String
    {
        return formatDateTime(date);
    }
}
