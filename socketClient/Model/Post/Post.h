#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Post : NSManagedObject

@property (nonatomic, retain) NSNumber * createdAt;
@property (nonatomic, retain) NSNumber * hasBeenCreated;
@property (nonatomic, retain) NSNumber * hasBeenDeleted;
@property (nonatomic, retain) NSNumber * hasBeenEdited;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * postId;
@property (nonatomic, retain) NSNumber * updatedAt;
@property (nonatomic, retain) NSNumber * deletedAt;

@end
