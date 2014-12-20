#import <ObjectiveDDP/ObjectiveDDP.h>
#import <ObjectiveDDP/MeteorClient.h>

#import "CoreDataAgent.h"
#import "MeteorAgent.h"
#import "Post.h"
#import "Post+Data.h"

static MeteorAgent *sharedInstance = nil;
static NSString *const kMeteorLocalURLString = @"ws://localhost:3000/websocket";
static NSString *const kMeteorLocalNetworkURLString = @"ws://imac.local:3000/websocket";

@implementation MeteorAgent

+ (MeteorAgent*)sharedInstance
{
    static dispatch_once_t once;
    static MeteorAgent *sharedInstance;    
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

/// Create MeteorClient and connect to server.
- (void)initMeteorClient
{
    self.meteorClient = [[MeteorClient alloc] initWithDDPVersion:@"1"];
    [self.meteorClient addSubscription:@"posts"];
    
    ObjectiveDDP *objectiveDDP = [[ObjectiveDDP alloc] initWithURLString:kMeteorLocalNetworkURLString delegate:self.meteorClient];
    self.meteorClient.ddp = objectiveDDP;
    [self.meteorClient.ddp connectWebSocket];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportConnectionReady) name:MeteorClientConnectionReadyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivePostsAddedUpdate:) name:@"posts_added" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivePostsChangeUpdate:) name:@"posts_changed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivePostsRemovedUpdate:) name:@"posts_removed" object:nil];
}

#pragma mark - Helper

- (NSString *)stringFromAuthState
{
    AuthState state = [[MeteorAgent sharedInstance] meteorClient].authState;
    switch (state) {
        case AuthStateNoAuth:
            return @"No authentication used";
            break;
        case AuthStateLoggingIn:
            return @"Logging in";
            break;
        case AuthStateLoggedIn:
            return @"Logged in";
            break;
        case AuthStateLoggedOut:
            return @"Logged out";
            break;
        default:
            break;
    }
}

#pragma mark - Notifications

/// Resumes session and starts offline sync process after connection has been established
- (void)reportConnectionReady
{
    NSString *sessionToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"sessionToken"];
    if (sessionToken && sessionToken.length > 5) {
        if (self.meteorClient.authState != AuthStateLoggedIn) {
            // If user isn't logged in, resume session by using latest session token
            [self.meteorClient logonWithUserParameters:@{@"resume": sessionToken }
                                      responseCallback:^(NSDictionary *response, NSError *error) {
                if (error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"bounsj.objectiveddp.loginFailed" object:[error userInfo]];
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"bounsj.objectiveddp.loggedIn" object:response];
                    [self saveConnectionCredentials:response];
                }
            }];
        } else if (self.meteorClient.authState == AuthStateLoggedIn) {
            // Starts offline sync process after connection has been established and user is logged in
            [Post performOfflineSyncInContext:[[CoreDataAgent sharedInstance] managedObjectContext]];
        }
    }
}

#pragma mark - Data Import Handling

/**
 *  Find and create new Post from remote object. If object is already present,
 *  update existing object with new data.
 *
 *  @param notification     NSNotification containing NSDictionary with object data
 */
- (void)didReceivePostsAddedUpdate:(NSNotification *)notification
{
    //NSLog(@"didReceivePostsAddedUpdate called with object: %@", [notification userInfo]);
    NSManagedObjectContext *context = [[CoreDataAgent sharedInstance] managedObjectContext];
    if (![Post findAndCreatePostWithData:[notification userInfo] inContext:context]) {
        [Post findAndUpdatePostWithData:[notification userInfo] inContext:context];
    }
    [[CoreDataAgent sharedInstance] saveContext:context];
}

/**
 *  Find and update Post with data from remote object.
 *
 *  @param notification     NSNotification containing NSDictionary with object data
 */
- (void)didReceivePostsChangeUpdate:(NSNotification *)notification
{    
    //NSLog(@"didReceivePostsChangeUpdate called with object: %@", [notification userInfo]);
    NSManagedObjectContext *context = [[CoreDataAgent sharedInstance] managedObjectContext];
    if (![Post findAndUpdatePostWithData:[notification userInfo] inContext:context]) {
        NSLog(@"Error updating object.");
    }
    [[CoreDataAgent sharedInstance] saveContext:context];
}

/**
 *  Find and remove Post with given _id from remote object.
 *
 *  @param notification     NSNotification containing NSDictionary with object data
 */
- (void)didReceivePostsRemovedUpdate:(NSNotification *)notification
{
    //NSLog(@"didReceivePostsRemovedUpdate called with object: %@", [notification userInfo]);
    NSManagedObjectContext *context = [[CoreDataAgent sharedInstance] managedObjectContext];
    if (![Post findAndDeletePostWithData:[notification userInfo] inContext:context]) {
        NSLog(@"Object not found.");
    } else {
        [[CoreDataAgent sharedInstance] saveContext:context];
    }
}

#pragma mark - Connection Credentials

/**
 *  Saves connection details (userId, sessionToken, sessionValidUntil) in NSUserDefaults for later use.
 *
 *  @param dictionary NSDictionary
 */
- (void)saveConnectionCredentials:(NSDictionary *)dictionary
{
    NSString *userId = [[MeteorAgent sharedInstance] meteorClient].userId;
    NSString *sessionToken = [[MeteorAgent sharedInstance] meteorClient].sessionToken;
    NSString *sessionValidUntil = [dictionary valueForKeyPath:@"result.tokenExpires.$date"];
    
    [[NSUserDefaults standardUserDefaults] setValue:userId forKey:@"userId"];
    [[NSUserDefaults standardUserDefaults] setValue:sessionToken forKey:@"sessionToken"];
    [[NSUserDefaults standardUserDefaults] setValue:sessionValidUntil forKey:@"sessionValidUntil"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/// Delete credentials from NSUserDefaults after user logged out
- (void)resetConnectionCredentials
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userId"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sessionToken"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sessionValidUntil"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
