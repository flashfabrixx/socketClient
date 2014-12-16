#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface ListViewController : UITableViewController
<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;

- (IBAction)addButtonPressed:(id)sender;

@end
