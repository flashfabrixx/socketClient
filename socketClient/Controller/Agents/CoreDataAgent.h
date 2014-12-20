#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataAgent : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (id)sharedInstance;
- (NSURL *)applicationDocumentsDirectory;

- (void)saveContext:(NSManagedObjectContext *)context;
- (void)resetContext:(NSManagedObjectContext *)context;

@end
