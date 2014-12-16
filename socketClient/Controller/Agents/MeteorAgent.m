#import <ObjectiveDDP/ObjectiveDDP.h>
#import <ObjectiveDDP/MeteorClient.h>

#import "CoreDataAgent.h"
#import "MeteorAgent.h"
#import "Post.h"
#import "Post+Data.h"

static MeteorAgent *sharedInstance = nil;
static NSString *const kMeteorLocalURLString = @"ws://localhost:3000/websocket";
static NSString *const kMeteorLocalNetworkURLString = @"ws://yourHostname:3000/websocket";

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
    
    self.objectiveDDP = [[ObjectiveDDP alloc] initWithURLString:kMeteorLocalURLString delegate:self.meteorClient];
    self.meteorClient.ddp = self.objectiveDDP;
    [self.meteorClient.ddp connectWebSocket];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportConnectionReady) name:MeteorClientConnectionReadyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivePostsAddedUpdate:) name:@"posts_added" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivePostsChangeUpdate:) name:@"posts_changed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceivePostsRemovedUpdate:) name:@"posts_removed" object:nil];
}

/// Reconnect to server after connection has been closed.
- (void)connectMeteorClient
{
    NSAssert(self.meteorClient, @"MeteorClient must not be nil.");
    if (self.meteorClient.ddp.webSocket.readyState == SR_CLOSED) {
        [self initMeteorClient];
    }
}

#pragma mark | Connection

/// Starts offline sync process after connection has been established
- (void)reportConnectionReady {
    [Post performOfflineSyncInContext:[[CoreDataAgent sharedInstance] managedObjectContext]];
}

#pragma mark | Posts

/**
 *  Find and create new Post from remote object. If object is already present,
 *  update existing object with new data.
 *
 *  @param notification     NSNotification containing NSDictionary with object data
 */
- (void)didReceivePostsAddedUpdate:(NSNotification *)notification
{
    NSLog(@"didReceivePostsAddedUpdate called with object: %@", [notification userInfo]);
    NSManagedObjectContext *context = [[CoreDataAgent sharedInstance] managedObjectContext];
    if (![Post findAndCreatePostWithData:[notification userInfo] inContext:context]) {
        [Post findAndUpdatePostWithData:[notification userInfo] inContext:context];
    }
    [[CoreDataAgent sharedInstance] saveContext];
}

/**
 *  Find and update Post with data from remote object.
 *
 *  @param notification     NSNotification containing NSDictionary with object data
 */
- (void)didReceivePostsChangeUpdate:(NSNotification *)notification
{    
    NSLog(@"didReceivePostsChangeUpdate called with object: %@", [notification userInfo]);
    NSManagedObjectContext *context = [[CoreDataAgent sharedInstance] managedObjectContext];
    if (![Post findAndUpdatePostWithData:[notification userInfo] inContext:context]) {
        NSLog(@"Error updating object.");
    } else {
        NSLog(@"Updated object.");
    }
    [[CoreDataAgent sharedInstance] saveContext];
}

/**
 *  Find and remove Post with given _id from remote object.
 *
 *  @param notification     NSNotification containing NSDictionary with object data
 */
- (void)didReceivePostsRemovedUpdate:(NSNotification *)notification
{
    NSLog(@"didReceivePostsRemovedUpdate called with object: %@", [notification userInfo]);
    NSManagedObjectContext *context = [[CoreDataAgent sharedInstance] managedObjectContext];
    if (![Post findAndDeletePostWithData:[notification userInfo] inContext:context]) {
        NSLog(@"Object not found.");
    } else {
        NSLog(@"Removed object.");
        [[CoreDataAgent sharedInstance] saveContext];
    }
}

@end
