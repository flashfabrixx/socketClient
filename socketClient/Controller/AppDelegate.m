#import "AppDelegate.h"
#import "CoreDataAgent.h"
#import "MeteorAgent.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [CoreDataAgent sharedInstance];
    [[MeteorAgent sharedInstance] initMeteorClient];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[CoreDataAgent sharedInstance] saveContext];
}

@end
