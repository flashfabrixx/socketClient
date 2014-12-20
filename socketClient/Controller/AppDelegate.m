#import "ObjectiveDDP.h"
#import <ObjectiveDDP/ObjectiveDDP.h>
#import <ObjectiveDDP/MeteorClient.h>
#import <CommonCrypto/CommonDigest.h>

#import "AppDelegate.h"
#import "CoreDataAgent.h"
#import "MeteorAgent.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [CoreDataAgent sharedInstance];
    [[MeteorAgent sharedInstance] initMeteorClient];
    
    // Show account or main storyboard depending on existing session token from old sessions
    UIStoryboard *storyboard = [UIStoryboard new];
    NSString *sessionToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"sessionToken"];
    if (sessionToken && sessionToken.length > 5) {
        storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    } else {
        storyboard = [UIStoryboard storyboardWithName:@"Account" bundle:[NSBundle mainBundle]];
    }    
    self.window.rootViewController = [storyboard instantiateInitialViewController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[CoreDataAgent sharedInstance] saveContext:[[CoreDataAgent sharedInstance] managedObjectContext]];
}

@end
