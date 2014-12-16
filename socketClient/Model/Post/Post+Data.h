#import "Post.h"

@interface Post (Data)

/**
 *  Create a new Post with given remote data or local entered data. Will set default values
 *  for createdAt, updatedAt, deletedAt and set an unique ID.
 *
 *  @param dictionary   NSDictionary with object data
 *  @param context      NSManagedObjectContext for current thread
 *
 *  @return post        NSManagedObject of the new Post
 */
+ (instancetype)initPostWithData:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

/**
 *  Finds existing Post by _id. If deletedAt property is set, Post will be deleted locally.
 *  If not, the remove object will be inserted in the NSManagedObjectContext.
 *
 *  @param dictionary   NSDictionary with object data
 *  @param context      NSManagedObjectContext for current thread
 *  @return             BOOL YES, if data has been added. NO, if not.
 */
+ (BOOL)findAndCreatePostWithData:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

/**
 *  Finds existing Post by _id. If deletedAt property is set, Post will be deleted locally. If local Post
 *  is newer than remove Post, the local Post will be sent to the server.
 *
 *  @param dictionary   NSDictionary with object data
 *  @param context      NSManagedObjectContext for current thread
 *  @return BOOL        YES, if data has been updated. NO, if not.
 */
+ (BOOL)findAndUpdatePostWithData:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

/**
 *  Finds existing Post by _id. If Post is found, delete it locally.
 *
 *  @param dictionary   NSDictionary with object data
 *  @param context      NSManagedObjectContext for current thread
 *  @return BOOL        YES, if data has been updated. NO, if not.
 */
+ (BOOL)findAndDeletePostWithData:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;



/**
 *  Set flags for Post object and prepare network request to add Post to server.
 *
 *  @param post     NSManagedObject Current post object
 *  @param context  NSManagedObjectContext for current thread
 */
+ (void)addPost:(Post *)post inContext:(NSManagedObjectContext *)context;


/**
 *  Set flags for Post object and prepare network request to update Post to server.
 *
 *  @param post     NSManagedObject Current post object
 *  @param offline  BOOL YES, if called from offline sync (will prevent updating timestamp), else NO.
 *  @param context  NSManagedObjectContext for current thread
 */
+ (void)updatePost:(Post *)post isOfflineSync:(BOOL)offline inContext:(NSManagedObjectContext *)context;

/**
 *  Set flags for Post object and prepare network request to delete Post to server.
 *
 *  @param post     NSManagedObject Current post object
 *  @param offline  BOOL YES, if called from offline sync (will prevent updating timestamp), else NO.
 *  @param context  NSManagedObjectContext for current thread
 */
+ (void)deletePost:(Post *)post isOfflineSync:(BOOL)offline inContext:(NSManagedObjectContext *)context;

/**
 *  Performs offline sync by scanning for Posts with hasBeenCreated, hasBeenEdited and
 *  hasBeenDeleted flags set and will upload found objects to the server.
 *
 *  @param context  NSManagedObjectContext for current thread
 */
+ (void)performOfflineSyncInContext:(NSManagedObjectContext *)context;



/**
 *  Resets flags for Post object to be ignored by offline sync.
 *
 *  @param post     NSManagedOBject Current post object
 *  @return post    NSManagedObject of updated Post
 */
+ (instancetype)resetFlags:(Post *)post;

@end
