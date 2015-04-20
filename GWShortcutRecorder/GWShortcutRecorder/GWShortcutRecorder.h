
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

//the current keycode and modifier flags
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

//whether the tab key can be a part of the shortcut, or has its standard behaviour of moving focus from the field. Default = YES.
@property (nonatomic) BOOL captureTabKey;

//whether or not a single key can be captured without modifier flags.
@property (nonatomic) BOOL requiresModifierFlags;

//get a string like "W" for a keyCode.
+ (NSString *) stringForRawKeyCode:(unsigned short) keyCode;

//set the keyCode and modifierFlags.
- (void) setKeyCode:(NSInteger) keyCode andModifierFlags:(NSEventModifierFlags) modifierFlags;

//resets and clears keycode and modifier flags.
- (void) clear;

@end
