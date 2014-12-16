#import <Foundation/Foundation.h>
#import <ObjectiveDDP/ObjectiveDDP.h>
#import <ObjectiveDDP/MeteorClient.h>

@interface MeteorAgent : NSObject

@property (nonatomic, strong) MeteorClient *meteorClient;
@property (nonatomic, strong) ObjectiveDDP *objectiveDDP;

+ (id)sharedInstance;
- (void)initMeteorClient;
- (void)connectMeteorClient;

@end
