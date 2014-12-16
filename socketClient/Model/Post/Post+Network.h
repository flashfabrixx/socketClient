#import "Post.h"

@interface Post (Network)

/**
 *  Performs network request to add new Post to server.
 *
 *  @param data         NSDictionary with object data
 *  @param callback     Callback with response and error objects
 */
+ (void)addPostOnServer:(NSArray *)data completion:(void (^)(NSDictionary *result, NSError *error))callback;


/**
 *  Performs network request to add new Post to server.
 *
 *  @param data         NSDictionary with object data
 *  @param callback     Callback with response and error objects
 */
+ (void)updatePostOnServer:(NSArray *)data completion:(void (^)(NSDictionary *result, NSError *error))callback;

/**
 *  Performs network request to add new Post to server.
 *
 *  @param data         NSDictionary with object data
 *  @param callback     Callback with response and error objects
 */
+ (void)deletePostOnServer:(NSArray *)data completion:(void (^)(NSDictionary *result, NSError *error))callback;

@end
