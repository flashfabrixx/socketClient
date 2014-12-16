#import "MeteorAgent.h"
#import "Post.h"
#import "Post+Data.h"
#import "Post+Network.h"

@implementation Post (Network)

+ (void)addPostOnServer:(NSArray *)data completion:(void (^)(NSDictionary *result, NSError *error))callback
{
    [[[MeteorAgent sharedInstance] meteorClient] callMethodName:@"addPost"
                                                     parameters:data
                                               responseCallback:^(NSDictionary *response, NSError *error) {
                                                   callback(response, error);
                                               }];
}

+ (void)updatePostOnServer:(NSArray *)data completion:(void (^)(NSDictionary *result, NSError *error))callback
{
    [[[MeteorAgent sharedInstance] meteorClient] callMethodName:@"editPost"
                                                     parameters:data
                                               responseCallback:^(NSDictionary *response, NSError *error) {
                                                   callback(response, error);
                                               }];
}

+ (void)deletePostOnServer:(NSArray *)data completion:(void (^)(NSDictionary *result, NSError *error))callback
{
    [[[MeteorAgent sharedInstance] meteorClient] callMethodName:@"deletePost"
                                                     parameters:data
                                               responseCallback:^(NSDictionary *response, NSError *error) {
                                                   callback(response, error);
                                               }];
}

@end
