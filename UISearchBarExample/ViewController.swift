//
//  ViewController.swift
//  UISearchBarExample
//
//  Created by Sergey Kargopolov on 2016-03-13.
//  Copyright © 2016 Sergey Kargopolov. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet weak var mySearchBar: UISearchBar!
    @IBOutlet weak var myTableView: UITableView!
 
    var searchResults = [AnyObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let topLeftButton = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(tableEditButtonTapped))
        
        self.navigationItem.leftBarButtonItem = topLeftButton
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        doSearch("")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return searchResults.count;
    }
 
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let myCell = tableView.dequeueReusableCellWithIdentifier("myCell", forIndexPath: indexPath)
        
        let friendRecord = searchResults[indexPath.row]
        let firstName = friendRecord["first_name"] as! String
        let lastName = friendRecord["last_name"] as! String
        myCell.textLabel?.text = String("\(firstName) \(lastName)")
        
        return myCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        print("Did select is called \(indexPath.row)")
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if editingStyle == UITableViewCellEditingStyle.Delete
        {
            //self.searchResults.removeAtIndex(indexPath.row)
            //tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            doDelete(indexPath)
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle
    {
        if self.myTableView.editing
        {
            return UITableViewCellEditingStyle.Delete
        } else {
            return UITableViewCellEditingStyle.None
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        print("User typed \(searchBar.text) ")
        
        doSearch(searchBar.text!)
    }
    
    func doSearch(searchWord: String)
    {
        // Dismiss the keyboard
        mySearchBar.resignFirstResponder()

        // Create URL
        let myUrl = NSURL(string: "http://localhost/SwiftAppAndMySQL/scripts/searchFriends.php")
        
        // Create HTTP Request
        let request = NSMutableURLRequest(URL:myUrl!);
        request.HTTPMethod = "POST";
        
        let postString = "searchWord=\(searchWord)";
        
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding);
        
        // Execute HTTP Request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data:NSData?, response: NSURLResponse?, error:NSError?) -> Void in
            
            // Run new async task to be able to interact with UI
            dispatch_async(dispatch_get_main_queue()) {
                
                // Check if error took place
                if error != nil
                {
                    // display an alert message
                    self.displayAlertMessage(error!.localizedDescription)
                    return
                }
                
                
                do {
                    
                    // Convert data returned from server to NSDictionary
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? NSDictionary
                    
                    // Cleare old search data and reload table
                    self.searchResults.removeAll(keepCapacity: false)
                    self.myTableView.reloadData()
                    
                    // If friends array is not empty, populate searchResults array
                    if let parseJSON = json {
                        
                        if let friends = parseJSON["friends"] as? [AnyObject]
                        {
                            self.searchResults = friends
                            self.myTableView.reloadData()
                            
                        } else if(parseJSON["message"] != nil)
                        {
                            // if no friends returned, display message returned from server side
                            let errorMessage = parseJSON["message"] as? String
                            
                            if(errorMessage != nil)
                            {
                                // display an alert message
                                self.displayAlertMessage(errorMessage!)
                            }
                        }
                    }
                    
                } catch {
                    print(error);
                }
                
            } // End of dispatch_async
            
            
        }) // End of data task
        
        
        task.resume()
        
    } // end of doSearch() function
    
    func displayAlertMessage(userMessage: String)
    {
        let myAlert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.Alert);
        let okAction =  UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
        myAlert.addAction(okAction);
        self.presentViewController(myAlert, animated: true, completion: nil)
    }
 
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        
        mySearchBar.text = ""
        mySearchBar.resignFirstResponder()
        searchResults.removeAll(keepCapacity: false)
        myTableView.reloadData()
        doSearch("")
    }

    func tableEditButtonTapped()
    {
        if(self.myTableView.editing)
        {
            self.myTableView.setEditing(false, animated: true)
            self.navigationItem.leftBarButtonItem?.title = "Edit"
        } else {
            self.myTableView.setEditing(true, animated: true)
            self.navigationItem.leftBarButtonItem?.title = "Done"
        }
    }
    
    func doDelete(indexPath: NSIndexPath)
    {
        let friendRecord = searchResults[indexPath.row]
        let friendToken = friendRecord["token"] as! String
        
        // Create URL
        let myUrl = NSURL(string: "http://localhost/SwiftAppAndMySQL/scripts/deleteFriend.php")
        
        // Create HTTP Request
        let request = NSMutableURLRequest(URL:myUrl!);
        request.HTTPMethod = "POST";
        
        let postString = "friendToken=\(friendToken)";
        
        request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding);
        
        // Execute HTTP Request
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data:NSData?, response: NSURLResponse?, error:NSError?) -> Void in
            
            // Run new async task to be able to interact with UI
            dispatch_async(dispatch_get_main_queue()) {
                
                // Check if error took place
                if error != nil
                {
                    // display an alert message
                    self.displayAlertMessage(error!.localizedDescription)
                    return
                }
                
                
                do {
                    
                    // Convert data returned from server to NSDictionary
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as? NSDictionary
                    
                    // Remove record from local array
                    self.searchResults.removeAtIndex(indexPath.row)
                    
                    // Delete UITableView Cell
                    self.myTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                    
                    // Reload table
                    self.myTableView.reloadData()
                    
                    // If friends array is not empty, populate searchResults array
                    if let parseJSON = json {
                        
                        if(parseJSON["message"] != nil)
                        {
                            // if message is returned, display message returned from server side
                            let errorMessage = parseJSON["message"] as? String
                            
                            if(errorMessage != nil)
                            {
                                // display an alert message
                                self.displayAlertMessage(errorMessage!)
                            }
                        }
                    }
                    
                } catch {
                    print(error);
                }
                
            } // End of dispatch_async
            
            
        }) // End of data task
        
        
        task.resume()
        
 
    }
    
}

