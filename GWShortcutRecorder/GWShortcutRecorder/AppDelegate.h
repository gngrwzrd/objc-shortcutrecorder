
#import <Cocoa/Cocoa.h>
#import "GWShortcutRecorder.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,GWShortcutRecorderDelegate>
@property (weak) IBOutlet NSWindow * window;
@property (weak) IBOutlet GWShortcutRecorder * recorder1;
@property (weak) IBOutlet GWShortcutRecorder * recorder2;
@end
