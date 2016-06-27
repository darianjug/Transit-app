//
//  SchedulesViewController.swift
//  Transit
//
//  Created by Darian Jug on 23/05/16.
//  Copyright © 2016 Darian Jug. All rights reserved.
//

import UIKit

import Realm

class SchedulesViewController: UITableViewController {
    var line: Line?
    var schedules: [Schedule] = []
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        loadData()
    }
    
    func loadData() {
        schedules = []
        line?.schedules.forEach({ (schedule) in
            schedules.append(schedule)
        })
    }
    
    func reload() {
        loadData()
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let viewController = segue.destinationViewController as? ScheduleItemsViewController {
            let selectedIndexPath = self.tableView!.indexPathForSelectedRow!
            viewController.schedule = schedules[selectedIndexPath.row]
        } else if let rootViewController = segue.destinationViewController as? UINavigationController {
            if let viewController = rootViewController.viewControllers.first as? NewScheduleViewController {
                viewController.line = line
                viewController.schedulesViewController = self
            }
        }
    }
}

extension SchedulesViewController {
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let schedule = self.schedules[indexPath.row]
            
            let realm = try! Realm()
            
            try! realm.write {
                realm.delete(schedule)
            }
            
            self.schedules.removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
}

extension SchedulesViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.schedules.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ScheduleItemCell")!
        let schedule = self.schedules[indexPath.row]
        
        var rawDaysOfWeek = Set(schedule.daysOfWeek.flatMap {$0.rawDayOfWeek}.sort())
        
        let weekDays    = Set([0,1,2,3,4])
        let weekendDays = Set([5,6])
        
        var titleComponents: [String] = []
        
        var containsWeekdays = false
        if weekDays.isSubsetOf(rawDaysOfWeek) {
            titleComponents.append("weekdays")
            rawDaysOfWeek = rawDaysOfWeek.subtract(weekDays)
            containsWeekdays = true
        }
        
        var containsWeekend = false
        if weekendDays.isSubsetOf(rawDaysOfWeek) {
            titleComponents.append("weekend")
            rawDaysOfWeek = rawDaysOfWeek.subtract(weekendDays)
            containsWeekend = true
        }
        
        let daysOfWeek = rawDaysOfWeek.flatMap {WeekDay(rawValue: $0)}
        
        print(daysOfWeek)
        print(daysOfWeek.sort {$0.rawValue < $1.rawValue})
        
        let names: [String] = daysOfWeek.sort {$0.rawValue < $1.rawValue}.flatMap { (dayOfWeek) in
            switch dayOfWeek {
            case .Monday:
                return "Monday"
            case .Tuesday:
                return "Tuesday"
            case .Wednesday:
                return "Wednesday"
            case .Thursday:
                return "Thursday"
            case .Friday:
                return "Friday"
            case .Saturday:
                return "Saturday"
            case .Sunday:
                return "Sunday"
            }
        }
        
        names.forEach { (name) in
            titleComponents.append(name)
        }
        
        if containsWeekdays && containsWeekend {
            titleComponents = ["whole week"]
        }
        
        if let first = titleComponents.first {
            titleComponents[0] = first.capitalizedString
        }
        
        cell.textLabel?.text = titleComponents.joinWithSeparator(", ")
        
        return cell
    }
}

import Eureka
import RealmSwift

class NewScheduleViewController : FormViewController {
    var line: Line?
    var schedulesViewController: SchedulesViewController?
    
    func dismissAndReloadParent() {
        schedulesViewController?.reload()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        dismissAndReloadParent()
    }
    
    @IBAction func save(sender: AnyObject) {
        // Get the default Realm
        let realm = try! Realm()
        
        let values = self.form.values()
        
        let formWeekDays = values["weekDays"] as! Set<WeekDay>
        
        let scheduleDaysOfWeek:[ScheduleDaysOfWeek] = formWeekDays.map { (weekDay) in
            let dayOfWeek = ScheduleDaysOfWeek()
            dayOfWeek.rawDayOfWeek = weekDay.rawValue
            return dayOfWeek
        }
        
        let schedule = Schedule()
        
        try! realm.write {
            scheduleDaysOfWeek.forEach({ (scheduleDayOfWeek) in
                realm.add(scheduleDayOfWeek)
                schedule.daysOfWeek.append(scheduleDayOfWeek)
            })
            
            realm.add(schedule)
            
            line!.schedules.append(schedule)
        }
        
        dismissAndReloadParent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ Section()
            <<< WeekDayRow("weekDays") {
                $0.value = []
        }
    }
}
