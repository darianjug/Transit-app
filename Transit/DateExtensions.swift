//
//  DateExtensions.swift
//  Transit
//
//  Created by Darian Jug on 06/05/16.
//  Copyright © 2016 Darian Jug. All rights reserved.
//

import UIKit

extension String {
    func parseDate(format: String) -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = NSTimeZone.systemTimeZone()
        dateFormatter.locale = NSLocale.systemLocale()
        dateFormatter.formatterBehavior = NSDateFormatterBehavior.BehaviorDefault
        let date = dateFormatter.dateFromString(self)
        return date
    }
}

extension NSDate {
    func dateComponents(unitFlags: NSCalendarUnit) -> NSDateComponents {
        let calendar = NSCalendar.currentCalendar()
        return calendar.components(unitFlags, fromDate: self)
    }
}

func + (left: NSDate, right: NSDateComponents) -> NSDate? {
    let calendar = NSCalendar.currentCalendar()
    return calendar.dateByAddingComponents(right, toDate: left, options: [])
}

func < (left: NSDate, right: NSDate) -> Bool {
    return left.timeIntervalSince1970 < right.timeIntervalSince1970
}

func <= (left: NSDate, right: NSDate) -> Bool {
    return left.timeIntervalSince1970 <= right.timeIntervalSince1970
}

func > (left: NSDate, right: NSDate) -> Bool {
    return left.timeIntervalSince1970 > right.timeIntervalSince1970
}

func >= (left: NSDate, right: NSDate) -> Bool {
    return left.timeIntervalSince1970 >= right.timeIntervalSince1970
}

func == (left: NSDate, right: NSDate) -> Bool {
    return left.timeIntervalSince1970 == right.timeIntervalSince1970
}

extension NSDateComponents {
    convenience init(value: Int, forComponent: NSCalendarUnit) {
        self.init()
        self.setValue(value, forComponent: forComponent)
    }
    
    var inFuture: NSDate? {
        get {
            let calendar = NSCalendar.currentCalendar()
            return calendar.dateFromComponents(self)
        }
    }
}

extension NSDateFormatter {
    convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
    }
}

extension NSDate {
    private struct DateFormatters {
        static let DayNameFormatter: NSDateFormatter = NSDateFormatter(dateFormat: "EEEE")
    }
    
    class func fromISO8601(ISO8601: String) -> NSDate? {
        let ISO8601Formatter: NSDateFormatter = NSDateFormatter()
        let ISO8601DateFormat: String = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        ISO8601Formatter.dateFormat = ISO8601DateFormat
        
        let posix: NSLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        ISO8601Formatter.locale = posix
        let date = ISO8601Formatter.dateFromString(ISO8601)
        
        if date == nil {
            return nil
        }
        
        return date
    }
    
    var ISO8601: String {
        get {
            let ISO8601Formatter: NSDateFormatter = NSDateFormatter()
            let ISO8601DateFormat: String = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            ISO8601Formatter.dateFormat = ISO8601DateFormat
            
            let posix: NSLocale = NSLocale(localeIdentifier: "en_US_POSIX")
            ISO8601Formatter.locale = posix
            return ISO8601Formatter.stringFromDate(self)
        }
    }
    
    func toString(format: String) -> String {
        let dateFormate: NSDateFormatter = NSDateFormatter()
        dateFormate.dateFormat = format
        return dateFormate.stringFromDate(self)
    }
    
    var hour: Int {
        get {
            return hours
        }
    }
    
    var hours: Int {
        let calendar = NSCalendar.currentCalendar()
        return calendar.component([.Hour], fromDate: self)
    }
    
    var dayName: String {
        return NSDate.DateFormatters.DayNameFormatter.stringFromDate(self)
    }
    
    var distanceToNowInWords: String {
        let distance = round(NSDate().timeIntervalSinceReferenceDate - self.timeIntervalSinceReferenceDate)
        let minutes = abs(round(distance/60))
        let hours = abs(round(((distance+99)/3600)))
        let days = abs(round((distance+800)/(60*60*24)))
        
        let output = NSMutableString()
        
        if distance < 0 {
            output.appendString("in ")
        }
        
        switch abs(distance) {
        case 0:
            output.appendString("just now")
        case 1:
            output.appendString("a second")
        case 2...59:
            output.appendFormat("%0.0f seconds", abs(distance))
        case 60...119:
            output.appendString("a minute")
        case 120...3540:
            output.appendFormat("%0.0f minutes", minutes)
        case 3541...7100:
            output.appendString("an hour")
        case 7101...82800:
            output.appendFormat("%0.0f hours", hours)
        case 82801...172000:
            output.appendString("a day")
        case 172001...518400:
            output.appendFormat("%0.0f days", days)
        case 518400...1036800:
            output.appendString("a week")
        default:
            output.appendString("sometime")
        }
        
        if distance >= 0 {
            output.appendString(" ago")
        }
        
        return String(output)
    }
    
    var inToday: NSDate {
        get {
            let calendar: NSCalendar! = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            let dateComponents = calendar.components([.Day, .Month, .Year, .Hour, .Minute, .Second, .TimeZone, .Era], fromDate: self)
            let today = NSDate()
            let todayComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year], fromDate: today)
            dateComponents.setValue(todayComponents.valueForComponent(.Day), forComponent: .Day)
            dateComponents.setValue(todayComponents.valueForComponent(.Month), forComponent: .Month)
            dateComponents.setValue(todayComponents.valueForComponent(.Year), forComponent: .Year)
            
            return calendar.dateFromComponents(dateComponents)!
        }
    }
    
    class var midnight: NSDate {
        let calendar: NSCalendar! = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let now = NSDate()
        return calendar.dateBySettingHour(0, minute: 0, second: 0, ofDate: now, options: NSCalendarOptions.MatchFirst)!
    }
    
    var secondsSinceMidnight: NSTimeInterval {
        let midnight = NSDate.midnight
        let diffrence = self.timeIntervalSinceReferenceDate - midnight.timeIntervalSinceReferenceDate
        return diffrence
    }
}

extension Int {
    var second:  NSTimeInterval { return NSTimeInterval(self) }
    var seconds: NSTimeInterval { return NSTimeInterval(self) }
    var minute:  NSTimeInterval { return NSTimeInterval(self * 60) }
    var minutes: NSTimeInterval { return NSTimeInterval(self * 60) }
    var hour:    NSTimeInterval { return NSTimeInterval(self * 3600) }
    var hours:   NSTimeInterval { return NSTimeInterval(self * 3600) }
}

extension Double {
    var second:  NSTimeInterval { return self }
    var seconds: NSTimeInterval { return self }
    var minute:  NSTimeInterval { return self * 60 }
    var minutes: NSTimeInterval { return self * 60 }
    var hour:    NSTimeInterval { return self * 3600 }
    var hours:   NSTimeInterval { return self * 3600 }
}