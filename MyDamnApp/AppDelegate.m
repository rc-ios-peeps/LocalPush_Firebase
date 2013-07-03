//
//  AppDelegate.m
//  MyDamnApp
//
//  Created by Raul Ramirez on 7/3/13.
//  Copyright (c) 2013 huahcoding. All rights reserved.
//

#import "AppDelegate.h"
#import <Firebase/Firebase.h>

@interface ToDoItem : NSObject  {
     NSInteger year;
    NSInteger month;
    NSInteger day;
    NSInteger hour;
    NSInteger minute;
    NSInteger second;
    NSString *eventName;
}

@property (nonatomic, readwrite) NSInteger year;
@property (nonatomic, readwrite) NSInteger month;
@property (nonatomic, readwrite) NSInteger day;
@property (nonatomic, readwrite) NSInteger hour;
@property (nonatomic, readwrite) NSInteger minute;
@property (nonatomic, readwrite) NSInteger second;
@property (nonatomic, copy) NSString *eventName;
@end

@implementation ToDoItem
@synthesize year, month, day, hour, minute, second, eventName;
@end

//@interface AppDelegate : NSObject {
//    UIWindow *window;
//    
//}


@implementation AppDelegate
@synthesize window;

//@property (nonatomic, strong) UIBackgroundTaskIdentifier *bgTask;

#define ToDoItemKey @"EVENTKEY1"
#define MessageTitleKey @"MSGKEY1"
UIBackgroundTaskIdentifier bgTask;
int x;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{   
    Firebase* f = [[Firebase alloc] initWithUrl:@"https://fuse-demo.firebaseio.com/data"];
//    f set
    // Read data and react to changes
    [f observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"%@ -> %@", snapshot.name, snapshot.value);
//        x++;
//        if(x==1){
//            return;
//        }
        NSError *e = nil;
//        NSDictionary *JSON =
//        [NSJSONSerialization JSONObjectWithData: [snapshot.value dataUsingEncoding:NSUTF8StringEncoding]
//                                        options: NSJSONReadingMutableContainers
//                                          error: &e];
        NSString *val=@"A new message has arrived";
        val = [snapshot.value valueForKey:@"TicketReference"];
//        if (!JSON) {
//            NSLog(@"Error parsing JSON: %@", e);
//        } else {
//            val = [JSON valueForKey:@"TicketReference"];
//        }
        UILocalNotification *localNotif = [launchOptions
                                           objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        
        if (localNotif) {
            NSString *itemName = [localNotif.userInfo objectForKey:ToDoItemKey];
            //  [viewController displayItem:itemName]; // custom method
            application.applicationIconBadgeNumber = localNotif.applicationIconBadgeNumber-1;
            NSLog(@"has localNotif %@",itemName);
        }
        else {
            
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            NSDate *now = [NSDate date];
            NSLog(@"now is %@",now);
            NSDate *scheduled = [now dateByAddingTimeInterval:0] ; //get x minute after
            NSCalendar *calendar = [NSCalendar currentCalendar];
            
            unsigned int unitFlags = NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit;
            NSDateComponents *comp = [calendar components:unitFlags fromDate:scheduled];
            
            NSLog(@"scheduled is %@",scheduled);
            
            ToDoItem *todoitem = [[ToDoItem alloc] init];
            
            todoitem.day = [comp day];
            todoitem.month = [comp month];
            todoitem.year = [comp year];
            todoitem.hour = [comp hour];
            todoitem.minute = [comp minute];
            todoitem.eventName = val;
            
            [self scheduleNotificationWithItem:todoitem interval:1];
            NSLog(@"scheduleNotificationWithItem");
            
            
        }

        
        
    }];
        [window makeKeyAndVisible];
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notif {
    NSLog(@"application: didReceiveLocalNotification:");
    NSString *itemName = [notif.userInfo objectForKey:ToDoItemKey];
    NSString *messageTitle = [notif.userInfo objectForKey:MessageTitleKey];
    // [viewController displayItem:itemName]; // custom method
    [self _showAlert:itemName withTitle:messageTitle];
    NSLog(@"Receive Local Notification while the app is still running...");
    NSLog(@"current notification is %@",notif);
    application.applicationIconBadgeNumber = notif.applicationIconBadgeNumber-1;
    
}

- (void) _showAlert:(NSString*)pushmessage withTitle:(NSString*)title
{
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:pushmessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"Application entered background state.");
    // UIBackgroundTaskIdentifier bgTask is instance variable
    // UIInvalidBackgroundTask has been renamed to UIBackgroundTaskInvalid
    NSAssert(bgTask == UIBackgroundTaskInvalid, nil);
    
    bgTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        });
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        while ([application backgroundTimeRemaining] > 1.0) {
            NSString *friend = [self checkForIncomingChat];
            if (friend) {
                UILocalNotification *localNotif = [[UILocalNotification alloc] init];
                if (localNotif) {
                    localNotif.alertBody = [NSString stringWithFormat:
                                            NSLocalizedString(@"%@ has a message for you.", nil), friend];
                    localNotif.alertAction = NSLocalizedString(@"Read Msg", nil);
                    localNotif.soundName = @"alarmsound.caf";
                    localNotif.applicationIconBadgeNumber = 1;
                    NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Your Background Task works",ToDoItemKey, @"Message from javacom", MessageTitleKey, nil];
                    localNotif.userInfo = infoDict;
                    [application presentLocalNotificationNow:localNotif];
                    friend = nil;
                    break;
                }
            }
        }
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });
}


- (NSString *) checkForIncomingChat {
    return @"javacom";
};


- (void)scheduleNotificationWithItem:(ToDoItem *)item interval:(int)minutesBefore {
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSDateComponents *dateComps = [[NSDateComponents alloc] init];
    [dateComps setDay:item.day];
    [dateComps setMonth:item.month];
    [dateComps setYear:item.year];
    [dateComps setHour:item.hour];
    [dateComps setMinute:item.minute];
    NSDate *itemDate = [calendar dateFromComponents:dateComps];
    
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    if (localNotif == nil)
        return;
    localNotif.fireDate = [itemDate dateByAddingTimeInterval:-(minutesBefore*60)];
    NSLog(@"fireDate is %@",localNotif.fireDate);
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
    
    localNotif.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ in %i minutes.", nil),
                            item.eventName, minutesBefore];
    localNotif.alertAction = NSLocalizedString(@"View Details", nil);
    
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    localNotif.applicationIconBadgeNumber = 1;
    //  NSDictionary *infoDict = [NSDictionary dictionaryWithObject:item.eventName forKey:ToDoItemKey];
    NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:item.eventName,ToDoItemKey, @"Push Notification received while running", MessageTitleKey, nil];
    localNotif.userInfo = infoDict;
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    NSLog(@"scheduledLocalNotifications are %@", [[UIApplication sharedApplication] scheduledLocalNotifications]);
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
