//
//  ViewController.swift
//  Transit
//
//  Created by Darian Jug on 06/05/16.
//  Copyright © 2016 Darian Jug. All rights reserved.
//

import UIKit

import RealmSwift

class Line: Object {
    dynamic var name = ""
    let schedules = List<Schedule>()
}

class Schedule: Object {
    let daysOfWeek = List<ScheduleDaysOfWeek>()
    let scheduleItems = List<ScheduleItem>()
}

class ScheduleDaysOfWeek: Object {
    dynamic var rawDayOfWeek: Int = 0
}

class ScheduleItem: Object {
    var timeIntervalSinceMidnight: NSTimeInterval?
    dynamic var time: NSDate?
}

class LinesViewController: UITableViewController {
    var lines: [Line]? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "Lines"
        
        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        loadData()
    }
    
    func loadData() {
        // Get the default Realm
        let realm = try! Realm()
        
        self.lines = realm.objects(Line).map{$0}
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
        if let viewController = segue.destinationViewController as? SchedulesViewController {
            let selectedIndexPath = self.tableView!.indexPathForSelectedRow!
            viewController.line = lines![selectedIndexPath.row]
        } else if let rootViewController = segue.destinationViewController as? UINavigationController {
            if let viewController = rootViewController.viewControllers.first as? NewLineViewController {
                viewController.linesViewController = self
            }
        }
    }
}


extension LinesViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lines?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LineCell")!
        let line = lines![indexPath.row]
        cell.textLabel?.text = line.name
        return cell
    }
}

extension LinesViewController {
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let line = self.lines![indexPath.row]
            
            let realm = try! Realm()
            
            try! realm.write {
                realm.delete(line)
            }
            
            self.lines!.removeAtIndex(indexPath.row)
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
}

import Eureka

class NewLineViewController : FormViewController {
    var linesViewController: LinesViewController?
    
    func dismissAndReloadParent() {
        linesViewController!.reload()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        dismissAndReloadParent()
    }
    
    @IBAction func save(sender: AnyObject) {
        // Get the default Realm
        let realm = try! Realm()
        
        let values = self.form.values()
        let name = values["name"] as? String
        
        let line = Line()
        line.name = name!
        
        try! realm.write {
            realm.add(line)
        }
        
        dismissAndReloadParent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ Section()
            <<< TextRow("name") {
                $0.title = "Name"
        }
    }
}

