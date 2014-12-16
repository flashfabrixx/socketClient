#import "CoreDataAgent.h"
#import "Post.h"
#import "Post+Data.h"
#import "Post+Network.h"

@implementation Post (Data)

#pragma mark - Local Operations

+ (instancetype)initPostWithData:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    Post *post = [NSEntityDescription insertNewObjectForEntityForName:self.entityName inManagedObjectContext:context];
    post.postId = [dictionary valueForKey:@"_id"];
    post.createdAt = [dictionary valueForKey:@"createdAt"];
    post.hasBeenCreated = @1;
    post.hasBeenEdited = @1;
    post.hasBeenDeleted = @0;
    post.message = [dictionary valueForKey:@"message"];
    post.updatedAt = [dictionary valueForKey:@"updatedAt"];
    post.deletedAt = [dictionary valueForKey:@"deletedAt"];

    // Set default values when creating local object
    if (!post.postId) {
        post.postId = [[NSUUID UUID] UUIDString];
    }
    if (!post.createdAt) {
        post.createdAt = [self unixTimestamp];
    }
    if (!post.updatedAt) {
        post.updatedAt = [self unixTimestamp];
    }
    if (!post.deletedAt || [post.deletedAt isEqualToNumber:@0]) {
        post.deletedAt = nil;
    }
    NSLog(@"initPostWithData finished with data: %@", post);
    return post;
}

+ (BOOL)findAndCreatePostWithData:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    // Check if deletedAt property is set. If yes, ignore object locally.
    NSNumber *deletedTimestamp = [dictionary valueForKey:@"deletedAt"];
    if (deletedTimestamp != nil && ![deletedTimestamp isEqualToNumber:@0]) {
        // Prevent findAndUpdate process by returning YES
        NSLog(@"Post deleted on server. Deleting post locally.");
        [self findAndDeletePostWithData:dictionary inContext:context];
        return YES;
    } else {
        NSString *remotePostId = [dictionary valueForKey:@"_id"];
        NSArray *results = [context executeFetchRequest:[self postFetchRequestForId:remotePostId] error:nil];
        
        if (results.count == 0) {
            Post *newPost = [self initPostWithData:dictionary inContext:context];
            [self resetFlags:newPost];
            [[CoreDataAgent sharedInstance] saveContext];
            return YES;
        }
    }
    return NO;
}

+ (BOOL)findAndUpdatePostWithData:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    // Check if deletedAt property is set. If yes, delete object locally.
    NSNumber *deletedTimestamp = [dictionary valueForKey:@"deletedAt"];
    if (deletedTimestamp != nil && ![deletedTimestamp isEqualToNumber:@0]) {
        NSLog(@"Post deleted on server. Deleting post locally.");
        [self findAndDeletePostWithData:dictionary inContext:context];
        return YES;
    } else {
        NSString *remotePostId = [dictionary valueForKey:@"_id"];
        NSArray *results = [context executeFetchRequest:[self postFetchRequestForId:remotePostId] error:nil];
        
        if (results.count == 1) {
            Post *existingPost = [results firstObject];

            // Check if local object is edited and updatedAt timestamp is newer than received remote object.
            // If local object is newer, send update to server; else update local object.

            BOOL hasBeenEdited = [existingPost.hasBeenEdited isEqualToNumber:@1];
            BOOL hasBeenDeleted = [existingPost.hasBeenDeleted isEqualToNumber:@1];
            BOOL localIsNewer = existingPost.updatedAt > [dictionary valueForKey:@"updatedAt"];
            
            if (hasBeenEdited && localIsNewer && !hasBeenDeleted) {
                NSLog(@"Local post newer than received item, uploading local post.");
                [Post updatePost:existingPost isOfflineSync:NO inContext:context];
            } else {
                NSLog(@"Local post is older, updating local post.");
                existingPost.message = [dictionary valueForKey:@"message"];
                existingPost.updatedAt = [dictionary valueForKey:@"updatedAt"];
                [self resetFlags:existingPost];
                [[CoreDataAgent sharedInstance] saveContext];
                return YES;
            }
        }
    }
    return NO;
}

+ (BOOL)findAndDeletePostWithData:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context
{
    NSString *remotePostId = [dictionary valueForKey:@"_id"];
    NSArray *results = [context executeFetchRequest:[self postFetchRequestForId:remotePostId] error:nil];
    
    if (results.count == 1) {
        Post *existingPost = [results firstObject];
        [context deleteObject:existingPost];
        [[CoreDataAgent sharedInstance] saveContext];
        return YES;
    }
    return NO;
}

#pragma mark - Remote Operations

+ (void)addPost:(Post *)post inContext:(NSManagedObjectContext *)context
{
    // Set flags for offline sync
    post.hasBeenCreated = @1;
    post.hasBeenEdited = @1;

    [Post addPostOnServer:[self parameterFromPost:post] completion:^(NSDictionary *result, NSError *error) {
        if (error) {
            NSLog(@"Error adding post %@ with error: %@", post, [error userInfo]);
        } else {
            [Post resetFlags:post];
        }
        [[CoreDataAgent sharedInstance] saveContext];
    }];
}

+ (void)updatePost:(Post *)post isOfflineSync:(BOOL)offline inContext:(NSManagedObjectContext *)context
{
    // Set flags for offline sync
    post.hasBeenEdited = @1;
    
    // Set timestamp and prevent overwriting of updatedAt
    // timestamp when performing offline sync
    if (!offline) {
        post.updatedAt = [self unixTimestamp];
    }

    [Post updatePostOnServer:[self parameterFromPost:post] completion:^(NSDictionary *result, NSError *error) {
        if (error) {
            NSLog(@"Error updating post %@ with error: %@", post, [error userInfo]);
        } else {
            [Post resetFlags:post];
        }
        [[CoreDataAgent sharedInstance] saveContext];
    }];
}

+ (void)deletePost:(Post *)post isOfflineSync:(BOOL)offline inContext:(NSManagedObjectContext *)context
{
    // Set local values
    post.hasBeenEdited = @1;
    post.hasBeenDeleted = @1;
    
    // Set timestamp and prevent overwriting of updatedAt
    // timestamp when performing offline sync
    if (!offline) {
        post.updatedAt = [self unixTimestamp];
        post.deletedAt = [self unixTimestamp];
    }

    [Post deletePostOnServer:[self parameterFromPost:post] completion:^(NSDictionary *result, NSError *error) {
        if (error) {
            NSLog(@"Error deleting post %@ with error: %@", post, [error userInfo]);
        } else {
            NSLog(@"Deleted post with response: %@", result);
            [context deleteObject:post];
        }
        [[CoreDataAgent sharedInstance] saveContext];
    }];
}

#pragma mark - Offline Sync

/// Returns NSFetchRequest to find Post by given _id
+ (NSFetchRequest *)postFetchRequestForId:(NSString *)postId
{
    NSAssert(postId, @"PostId must not be nil.");
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Post"];
    request.predicate = [NSPredicate predicateWithFormat:@"postId = %@", postId];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"postId" ascending:YES]];
    return request;
}


+ (void)performOfflineSyncInContext:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Post"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"postId" ascending:YES]];
    
    request.predicate = [NSPredicate predicateWithFormat:@"hasBeenCreated == %@", @1];
    NSArray *added = [context executeFetchRequest:request error:&error];
    
    request.predicate = [NSPredicate predicateWithFormat:@"hasBeenCreated == %@ && hasBeenEdited = %@", @0, @1];
    NSArray *edited = [context executeFetchRequest:request error:&error];
    
    request.predicate = [NSPredicate predicateWithFormat:@"hasBeenDeleted == %@", @1];
    NSArray *deleted = [context executeFetchRequest:request error:&error];
    
    [added enumerateObjectsUsingBlock:^(Post *post, NSUInteger idx, BOOL *stop) {
        [Post addPost:post inContext:context];
    }];
    [edited enumerateObjectsUsingBlock:^(Post *post, NSUInteger idx, BOOL *stop) {
        [Post updatePost:post isOfflineSync:YES inContext:context];
    }];
    [deleted enumerateObjectsUsingBlock:^(Post *post, NSUInteger idx, BOOL *stop) {
        [Post deletePost:post isOfflineSync:YES inContext:context];
    }];
    
    if (error) {
        NSLog(@"Error fetching objects for offline sync: %@", [error userInfo]);
    }
}

#pragma mark - Helper

+ (instancetype)resetFlags:(Post *)post
{
    post.hasBeenCreated = @0;
    post.hasBeenEdited = @0;
    post.hasBeenDeleted = @0;
    return post;
}

/// Returns unix timestamp for current NSDate
+ (NSNumber *)unixTimestamp {
    return @([[NSDate date] timeIntervalSince1970]);
}

/// Transforms NSManagedObject Post to NSArray for network operations
+ (NSArray *)parameterFromPost:(Post *)post
{
    NSArray *parameters;
    if (post.deletedAt) {
        parameters = @[@{@"_id": post.postId,
                         @"message": post.message,
                         @"createdAt": post.createdAt,
                         @"updatedAt": post.updatedAt,
                         @"deletedAt": post.deletedAt}];
    } else {
        parameters = @[@{@"_id": post.postId,
                         @"message": post.message,
                         @"createdAt": post.createdAt,
                         @"updatedAt": post.updatedAt}];
    }
    return parameters;
}

+ (NSString *)entityName {
    return @"Post";
}

@end
