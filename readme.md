GWShortcutRecorder is a single file NSView subclass that handles recording shortcuts. It passes messages to it's delegate with the keyCode and modifier flags.

It's default appearance looks like a standard NSButton. You can cusomize a few settings, or subclass it and override some drawing methods to completely change how it looks.

There's a demo in this repo:


	#import "AppDelegate.h"

	@implementation AppDelegate

	- (void) applicationDidFinishLaunching:(NSNotification *) aNotification {
		self.recorder1.delegate = self;
		self.recorder2.delegate = self;
		
		//set some custom labels and color
		self.recorder2.defaultLabel = @"Click to record";
		self.recorder2.waitingForKeysLabel = @"Type something";
		self.recorder2.snapBackButtonTint = [NSColor purpleColor];
		self.recorder2.clearButtonTint = [NSColor blueColor];
		
		//manually set keyboard shortcut
		[self.recorder2 setKeyCode:14 andModifierFlags:NSCommandKeyMask|NSShiftKeyMask|NSAlternateKeyMask];
	}

	- (void) shortcutRecorder:(GWShortcutRecorder *) recorder didClearFlags:(NSEventModifierFlags) flags andKeyCode:(unsigned short) keycode {
		NSLog(@"clear: keyCode: %u, flags:%lu",keycode,flags);
	}

	- (void) shortcutRecorder:(GWShortcutRecorder *) recorder setFlags:(NSEventModifierFlags) flags andKeyCode:(unsigned short) keycode {
		NSLog(@"set: keyCode: %u, flags:%lu",keycode,flags);
	}

	@end

![Screenshot](http://gngrwzrd.com/downloads/gwshortcutrecorder.png)
    