#import <UIKit/UIKit.h>
#import <ObjectiveDDP/ObjectiveDDP.h>
#import <ObjectiveDDP/MeteorClient.h>

@class MeteorClient;

@interface AppDelegate : UIResponder
<UIApplicationDelegate>

@property (nonatomic, strong) MeteorClient *meteorClient;
@property (nonatomic, weak) id<DDPAuthDelegate> authDelegate;

@property (strong, nonatomic) UIWindow *window;

@end

