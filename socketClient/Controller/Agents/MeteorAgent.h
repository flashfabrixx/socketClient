#import <Foundation/Foundation.h>
#import <ObjectiveDDP/MeteorClient.h>

@interface MeteorAgent : NSObject

@property (nonatomic, strong) MeteorClient *meteorClient;

+ (id)sharedInstance;

- (void)initMeteorClient;
- (NSString *)stringFromAuthState;
- (void)saveConnectionCredentials:(NSDictionary *)dictionary;
- (void)resetConnectionCredentials;

@end
