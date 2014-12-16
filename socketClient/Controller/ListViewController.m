// Libs
#import <ObjectiveDDP/MeteorClient.h>

// Controller
#import "ListViewController.h"

// Data Handler
#import "CoreDataAgent.h"
#import "MeteorAgent.h"
#import "Post.h"
#import "Post+Data.h"

@implementation ListViewController
{
    NSDateFormatter *dateFormatter;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.statusLabel.text = @"Connecting …";

    self.context = [[CoreDataAgent sharedInstance] managedObjectContext];
    self.fetchedResultsController = [self fetchedResultsController];
    self.fetchedResultsController.delegate = self;
    [self.tableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportConnection) name:MeteorClientDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportConnectionReady) name:MeteorClientConnectionReadyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportDisconnection) name:MeteorClientDidDisconnectNotification object:nil];
}

#pragma mark | Connection

- (void)reportConnection {
    NSLog(@"[CONNECTION] Connecting to server");
    self.statusLabel.text = @"Connecting …";
    self.statusLabel.textColor = [UIColor colorWithRed:0.969 green:0.792 blue:0.094 alpha:1.000];
}

- (void)reportConnectionReady {
    NSLog(@"[CONNECTION] Connected to server");
    self.statusLabel.text = @"Connected";
    self.statusLabel.textColor = [UIColor colorWithRed:0.153 green:0.682 blue:0.376 alpha:1.000];
}

- (void)reportDisconnection {
    NSLog(@"[CONNECTION] No connection to server available");
    self.statusLabel.text = @"Not connected";
    self.statusLabel.textColor = [UIColor redColor];
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) return _fetchedResultsController;
    _fetchedResultsController = [self newFetchedResultsController];
    return _fetchedResultsController;
}

/**
 *  Returns new NSFetchedResultsController containing all non deleted posts.
 *  @return NSFetchedResultsController
 */
- (NSFetchedResultsController *)newFetchedResultsController
{
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] init];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(deletedAt == %@) || (deletedAt == nil)", @0];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:YES]];
    
    frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                              managedObjectContext:self.context
                                                sectionNameKeyPath:nil
                                                         cacheName:nil];
    frc.delegate = self;

    NSError *error = nil;
    if (![frc performFetch:&error]) {
        NSLog(@"Error fetching posts: %@", [error userInfo]);
    } else {
        return frc;
    }
    return nil;
}

#pragma mark - Table view
#pragma mark | Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[[self fetchedResultsController] sections] objectAtIndex:(NSUInteger)section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostCell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Post *selectedPost = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [Post deletePost:selectedPost isOfflineSync:NO inContext:self.context];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *selectedPost = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    [self showUpdatePostAlertWithPost:selectedPost];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark | Cell

/**
 *  Set UITableViewCell with content of Post for given NSIndexPath.
 *
 *  @param cell      Cell with identifier "PostCell"
 *  @param indexPath Current index path from table view
 */
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Post *currentPost = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    cell.textLabel.text = currentPost.message;
    cell.detailTextLabel.text = [self stringFromUnixTimestamp:currentPost.updatedAt];

    // Mark new/edit posts which will be sent via offline sync
    if ([currentPost.hasBeenCreated isEqualToNumber:@1] || [currentPost.hasBeenEdited isEqualToNumber:@1]) {
        cell.textLabel.alpha = .5;
        cell.detailTextLabel.alpha = .5;
    } else {
        cell.textLabel.alpha = 1;
        cell.detailTextLabel.alpha = 1;
    }
}

/**
 *  Convert given NSNumber timestamp into NSString for current user location.
 *
 *  @param timestamp NSNumber timestamp
 *  @return NSString Converted timestamp (Date: ShortStyle, Time: MediumStyle)
 */
- (NSString *)stringFromUnixTimestamp:(NSNumber *)timestamp
{
    double timestampval = [timestamp doubleValue];
    NSTimeInterval convertedTimestamp = (NSTimeInterval)timestampval;
    NSDate *newTimestamp = [NSDate dateWithTimeIntervalSince1970:convertedTimestamp];
    
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale currentLocale];
        dateFormatter.timeZone = [NSTimeZone systemTimeZone];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    }
    return [dateFormatter stringFromDate:newTimestamp];
}

#pragma mark | Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)sectionType
{
    switch(sectionType) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)sectionType
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(sectionType) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - Actions

- (IBAction)addButtonPressed:(id)sender {
    [self showNewPostAlert];
}

#pragma mark - Alerts

/**
 *  Shows UIAlertController (type: Alert) with UITextField to create new post.
 */
- (void)showNewPostAlert
{
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"Add Post"
                                        message:@"Enter the title of the new post."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Title of the post";
    }];
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    [alertController addAction:cancelButton];
    
    UIAlertAction *sendButton = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textfield = alertController.textFields.firstObject;
        Post *newPost = [Post initPostWithData:@{@"message" : textfield.text} inContext:self.context];
        [Post addPost:newPost inContext:self.context];
        [textfield resignFirstResponder];
    }];
    [alertController addAction:sendButton];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

/**
 *  Shows UIAlertController (type: Alert) with UITextField to update post.
 *  @param post Existing Post object
 */
- (void)showUpdatePostAlertWithPost:(Post *)post
{
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:@"Update Post"
                                        message:@"Update the title of the post."
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Title of post";
        textField.text = post.message;
    }];
    
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDestructive handler:nil];
    UIAlertAction *sendButton = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textfield = alertController.textFields.firstObject;        
        post.message = textfield.text;
        [Post updatePost:post isOfflineSync:NO inContext:self.context];
    }];
    [alertController addAction:cancelButton];
    [alertController addAction:sendButton];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
