
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@class GWShortcutRecorder;

//delegate to notify of clear/set keyboard shortcut
@protocol GWShortcutRecorderDelegate <NSObject>
- (void) shortcutRecorder:(GWShortcutRecorder *) recorder didClearFlags:(NSEventModifierFlags) flags andKeyCode:(unsigned short) keycode;
- (void) shortcutRecorder:(GWShortcutRecorder *) recorder setFlags:(NSEventModifierFlags) flags andKeyCode:(unsigned short) keycode;
@end

@interface GWShortcutRecorder : NSView
@property (weak) NSObject <GWShortcutRecorderDelegate> * delegate;
@property (readonly) NSEventModifierFlags modifierFlags;
@property (readonly) NSInteger keyCode;

//optionally alter these to change the titles / appearance of some elements.
@property (nonatomic) NSString * defaultLabel;
@property (nonatomic) NSDictionary * defaultAttributes;
@property (nonatomic) NSString * waitingForKeysLabel;
@property (nonatomic) NSDictionary * waitingForKeysAttributes;
@property (nonatomic) NSColor * snapBackButtonTint;
@property (nonatomic) NSColor * clearButtonTint;
@property (nonatomic) NSColor * mouseDownTintAdjustment;

//set the keyCode and modifierFlags.
- (void) setKeyCode:(NSInteger) keyCode andModifierFlags:(NSEventModifierFlags) modifierFlags;

@end
