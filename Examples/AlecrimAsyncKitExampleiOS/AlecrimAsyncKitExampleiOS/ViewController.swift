//
//  ViewController.swift
//  AlecrimAsyncKitExampleiOS
//
//  Created by Vanderlei Martinelli on 2015-08-27.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import UIKit
import AlecrimAsyncKit

class ViewController: UIViewController {
    
    @IBOutlet weak var oneButton: UIButton!
    @IBOutlet weak var twoButton: UIButton!
    @IBOutlet weak var threeButton: UIButton!
    @IBOutlet weak var fourButton: UIButton!
    
    @IBOutlet weak var doneLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var t1: NonFailableTask<Void>!
    var t2: NonFailableTask<Void>!
    var t3: NonFailableTask<Void>!
    var t4: NonFailableTask<Void>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // (oh, Xcode template, if you did not tell me I'll never know... but, from a nib? I thought we were in 2015...)
        
        // OK: the user will have to tap the four buttons, after that an image will be loaded asynchronous
        // and there will be much rejoicing (yaaaaaaaay)
        
        // this example is here to demonstrate that tasks can be finished outside their inner blocks and
        // to exemplify that asynchronous tasks can include interface elements and user actions
        // (maybe it is not a common case, but it is good start for an app "coaching" feature, for example)
        
        self.t1 = async { task in
            // do nothing here, see `oneButtonPressed:` method below
        }
        
        self.t2 = async { task in
            await(self.t1)
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                // interface elements have to be updated on the main thread
                self.twoButton.enabled = true
            }
        }

        self.t3 = async { task in
            await(self.t2)
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.threeButton.enabled = true
            }
        }

        self.t4 = async { task in
            await(self.t3)
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.fourButton.enabled = true
            }
        }
        
        // normally you will have a already created NSOperationQueue and use it
        // or dispatch the closure ("block" is so 2009) to some GCD queue, but here we do not need that
        NSOperationQueue().addOperationWithBlock {
            // we always wait for a task finishing on background
            // (if we do it on main thread, it will block the app
            // [AlecrimAsyncKit has an assertion to prevent that, anyway])
            await(self.asyncDone())

            // to demonstrate delay condition...
            // (even if we do not wait for this task, it will be started after two seconds anyway)
            let _: Task<Void> = async(condition: DelayTaskCondition(timeInterval: 2)) { task in
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.doneLabel.text = "And now for something\ncompletely different..."
                    task.finish() // we have always to tell when the task is finished
                }
            }

            // try to load a cool Minion image...
            do {
                let image = try await(self.asyncLoadImage())
                
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.doneLabel.hidden = true

                    // OK, we can now eat some bananas... finally!
                    self.imageView.image = image
                    self.imageView.hidden = false
                }
            }
            catch {
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.doneLabel.text = "Could not load image. :/"
                }
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        // (someone even put something here?)
    }

}

extension ViewController {
    
    @IBAction func oneButtonPressed(sender: UIButton) {
        sender.hidden = true
        self.t1.finish() // yes, we can finish the task outside its inner block
    }
    
    @IBAction func twoButtonPressed(sender: UIButton) {
        sender.hidden = true
        self.t2.finish()
    }
    
    @IBAction func threeButtonPressed(sender: UIButton) {
        sender.hidden = true
        self.t3.finish()
    }
    
    @IBAction func fourButtonPressed(sender: UIButton) {
        sender.hidden = true
        self.t4.finish()
    }
    
}

extension ViewController {

    func asyncDone() -> NonFailableTask<Void> {
        return async { task in
            await(self.t4)
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.doneLabel.text = "Done!"
                self.doneLabel.hidden = false
                
                // we can finish the task on any thread, even the main thread
                task.finish()
            }
        }
    }

    func asyncLoadImage() -> Task<UIImage> {
        // an observer is not needed to the task finish its job, but to have a network activity indicator at the top would be nice...
        let networkActivityObserver = NetworkActivityTaskObserver(application: UIApplication.sharedApplication())

        // if you replace 10 for 2, for example, the task will be cancelled before it is finished
        let timeoutObserver = TimeoutTaskObserver(timeout: 10)
        
        // here we have the common case where a func returns a task
        // and the task is finished inside its inner block
        return async(observers: [networkActivityObserver, timeoutObserver]) { task in
            // remember that on iOS 9 (and OS X 10.11 El Capitan, My Capitan!) we cannot use "http" anymore because...
            // wibbly wobbly... time-y wimey... stuff!
            guard let imageURL = NSURL(string: "https://wallpapers.wallhaven.cc/wallpapers/full/wallhaven-90081.jpg"),
                  let imageData = NSData(contentsOfURL: imageURL),
                  let image = UIImage(data: imageData)
            else {
                task.finishWithError(NSError(domain: "com.alecrim.AlecrimAsyncKitExampleiOS", code: 1000, userInfo: nil))
                return
            }
            
            NSThread.sleepForTimeInterval(3) // I think we can let them waiting a little more...
            
            // thank you for the image, Minions and wallhaven.cc :-) 
            // (All rights reserved to its owners. Gru?)
            task.finishWithValue(image)
        }
    }
    
}
