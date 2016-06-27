//
//  ScheduleItemsViewController.swift
//  Transit
//
//  Created by Darian Jug on 06/05/16.
//  Copyright © 2016 Darian Jug. All rights reserved.
//

import UIKit


class ScheduleItemsViewController: UITableViewController {
    var schedule: Schedule?
    var scheduleItems: [ScheduleItem]?
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        loadData()
    }
    
    func loadData() {
        self.scheduleItems = schedule?.scheduleItems.map({ (scheduleItem) in
            scheduleItem.timeIntervalSinceMidnight = scheduleItem.time!.inToday.secondsSinceMidnight
            return scheduleItem
        }).sort({ (scheduleItemA, scheduleItemB) -> Bool in
            return scheduleItemA.timeIntervalSinceMidnight ?? 0 < scheduleItemB.timeIntervalSinceMidnight ?? 0
        })
    }
    
    func reload() {
        loadData()
        self.tableView.reloadData()
    }
    
    func update() {
        let visibleIndexPaths = self.tableView.indexPathsForVisibleRows
        
        for (index, cell) in self.tableView.visibleCells.enumerate() {
            let indexPath = visibleIndexPaths![index]
            let scheduleItem = self.scheduleItems![indexPath.row]
            updateCellPreview(cell, scheduleItem: scheduleItem)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let rootViewController = segue.destinationViewController as? UINavigationController {
            if let viewController = rootViewController.viewControllers.first as? MultipleNewScheduleItemViewController {
                viewController.schedule = schedule
                viewController.scheduleItemsViewController = self
            }
        }
    }
    
    func updateCellPreview(cell: UITableViewCell, scheduleItem: ScheduleItem) {
        let inTodayScheduleItemTime = scheduleItem.time!.inToday
        cell.textLabel!.text = "\(inTodayScheduleItemTime.distanceToNowInWords)"
        
        if inTodayScheduleItemTime < NSDate() {
            cell.textLabel!.textColor = UIColor.grayColor()
            cell.detailTextLabel!.textColor = UIColor.grayColor()
        } else {
            cell.textLabel!.textColor = UIColor.blackColor()
            cell.detailTextLabel!.textColor = UIColor.blackColor()
        }
    }
}

extension ScheduleItemsViewController {
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let scheduleItem = self.scheduleItems![indexPath.row]
            
            let realm = try! Realm()
            
            try! realm.write {
                realm.delete(scheduleItem)
            }
            
            self.scheduleItems!.removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
}

extension ScheduleItemsViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.scheduleItems!.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ScheduleItemCell")!
        let scheduleItem = self.scheduleItems![indexPath.row]
        
        cell.detailTextLabel!.text = "\(scheduleItem.time!.toString("HH:mm"))"
        
        updateCellPreview(cell, scheduleItem: scheduleItem)
        
        return cell
    }
}

import Eureka
import RealmSwift

class NewScheduleItemViewController : FormViewController {
    var schedule: Schedule?
    var scheduleItemsViewController: ScheduleItemsViewController?
    
    func dismissAndReloadParent() {
        scheduleItemsViewController?.reload()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        dismissAndReloadParent()
    }
    
    @IBAction func save(sender: AnyObject) {
        // Get the default Realm
        let realm = try! Realm()
        
        let values = self.form.values()
        let time = values["time"] as? NSDate
        
        let scheduleItem = ScheduleItem()
        scheduleItem.time = time
        
        try! realm.write {
            schedule!.scheduleItems.append(scheduleItem)
            realm.add(scheduleItem)
        }
        
        dismissAndReloadParent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ Section()
            <<< TimeRow("time") {
                $0.title = "Time"
                $0.value = NSDate()
        }
    }
}

extension String {
    func regex (pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions(rawValue: 0))
            let nsstr = self as NSString
            let all = NSRange(location: 0, length: nsstr.length)
            var matches : [String] = [String]()
            regex.enumerateMatchesInString(self, options: NSMatchingOptions(rawValue: 0), range: all) {
                (result : NSTextCheckingResult?, _, _) in
                if let r = result {
                    let result = nsstr.substringWithRange(r.range) as String
                    matches.append(result)
                }
            }
            return matches
        } catch {
            return [String]()
        }
    }
}

class MultipleNewScheduleItemViewController : FormViewController {
    var schedule: Schedule?
    var scheduleItemsViewController: ScheduleItemsViewController?
    
    func dismissAndReloadParent() {
        scheduleItemsViewController?.reload()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        dismissAndReloadParent()
    }
    
    @IBAction func save(sender: AnyObject) {
        // Get the default Realm
        let realm = try! Realm()
        
        let values = self.form.values()
        
        let timesString = values["times"] as! String
        
        let result = timesString.regex("(([0-9][0-9]):([0-9][0-9]):?([0-9][0-9])?)")
        
        let times: [NSDate] = result.flatMap { (string) in
            let segmentsCount = string.characters.split{$0 == ":"}.count
            
            let offsetHours     = values["offsetHours"] as! Double
            let offsetMinutes   = values["offsetMinutes"] as! Double
            let offsetSeconds   = values["offsetSeconds"] as! Double
            
            var date: NSDate?
            if segmentsCount == 2 {
                date = string.parseDate("HH:mm")
            } else if segmentsCount == 3 {
                date = string.parseDate("HH:mm:ss")
            } else {
                date = nil
            }
            
            date = date?.dateByAddingTimeInterval(offsetHours.hours + offsetMinutes.minutes + offsetSeconds.seconds)
            
            return date
        }
        
        let items = times.map { (date) -> ScheduleItem in
            let scheduleItem = ScheduleItem()
            scheduleItem.time = date
            return scheduleItem
        }
        
        try! realm.write {
            items.forEach({ (item) in
                schedule!.scheduleItems.append(item)
                realm.add(item)
            })
        }
        
        dismissAndReloadParent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ Section()
            <<< TextAreaRow("times") {
                $0.title = "Times"
                $0.placeholder = "12:00,13:15,14:30..."
        }
        
        form +++ Section("Offsetting")
            <<< SwitchRow() {
                $0.title = "Enabled"
                $0.value = true
            }
            <<< SegmentedRow<String>() { $0.options = ["Add", "Remove"] }
            <<< DecimalRow("offsetHours") {
                $0.title = "Hours"
                $0.value = 0.0
            }
            <<< DecimalRow("offsetMinutes") {
                $0.title = "Minutes"
                $0.value = 0.0
        }
            <<< DecimalRow("offsetSeconds") {
                $0.title = "Seconds"
                $0.value = 0.0
        }
    }
}