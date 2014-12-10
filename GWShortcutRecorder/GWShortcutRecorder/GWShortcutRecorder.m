
#import "GWShortcutRecorder.h"

@interface GWShortcutRecorder ()
@property BOOL isRecording;
@property BOOL mouseDownInClear;
@property BOOL mouseDownInSnapBack;
@property (readwrite) NSEventModifierFlags modifierFlags;
@property (readwrite) NSInteger keyCode;
@property NSMutableString * mutableLabel;
@property NSMutableString * previousMutableLabel;
@property NSEventModifierFlags previousModifierFlags;
@property NSInteger previousKeyCode;
@property NSImage * clearImage;
@property NSImage * clearImageTinted;
@property NSImage * snapBackImage;
@property NSImage * snapBackImageTinted;
@end

@implementation GWShortcutRecorder

+ (NSString *) stringForRawKeyCode:(unsigned short) keyCode {
	TISInputSourceRef tisSource = TISCopyCurrentASCIICapableKeyboardInputSource();
	CFDataRef layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
	CFRelease(tisSource);
	const UCKeyboardLayout * keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
	static const UniCharCount MaxLength = 255;
	UniCharCount actualLength = 0;
	UniChar chars[MaxLength] = {0};
	UInt32 deadKeyState = 0;
	__unused OSStatus err = UCKeyTranslate(keyLayout,keyCode,kUCKeyActionDisplay,0,LMGetKbdType(),kUCKeyTranslateNoDeadKeysBit,&deadKeyState,sizeof(chars)/sizeof(UniChar),&actualLength,chars);
	return [[NSString stringWithCharacters:chars length:actualLength] uppercaseString];
}

- (id) initWithCoder:(NSCoder *) coder {
	self = [super initWithCoder:coder];
	[self defaultInit];
	return self;
}

- (id) initWithFrame:(NSRect) frameRect {
	self = [super initWithFrame:frameRect];
	[self defaultInit];
	return self;
}

- (void) defaultInit {
	self.modifierFlags = 0;
	self.previousModifierFlags = 0;
	self.keyCode = -1;
	self.previousKeyCode = -1;
	self.defaultLabel = @"Click to record shortcut";
	self.waitingForKeysLabel = @"Type shortcut";
        self.captureTabKey = YES;
	_snapBackButtonTint = [NSColor orangeColor];
	_clearButtonTint = [NSColor colorWithRed:.5 green:.5 blue:.5 alpha:1];
	_mouseDownTintAdjustment = [NSColor colorWithRed:0 green:0 blue:0 alpha:.2];
	self.defaultAttributes = @{NSFontAttributeName:[NSFont systemFontOfSize:[NSFont systemFontSize]]};
	self.waitingForKeysAttributes = @{
		NSFontAttributeName:[NSFont systemFontOfSize:[NSFont systemFontSize]],
		NSForegroundColorAttributeName:[NSColor grayColor]
	};
	[self tintSnapBackImage];
	[self tintClearImage];
}

- (void) tintSnapBackImage {
	//set first tint image.
	self.snapBackImage = [[NSImage imageNamed:NSImageNameInvalidDataFreestandingTemplate] copy];
	self.snapBackImage.size = NSMakeSize(12,12);
	[self.snapBackImage lockFocus];
	[self.snapBackButtonTint set];
	NSRect imageRect2 = {NSZeroPoint,[self.snapBackImage size]};
	NSRectFillUsingOperation(imageRect2,NSCompositeSourceAtop);
	[self.snapBackImage unlockFocus];
	
	if(self.mouseDownTintAdjustment) {
		//set another tinted image with a bit darker tint.
		self.snapBackImageTinted = [[NSImage imageNamed:NSImageNameInvalidDataFreestandingTemplate] copy];
		self.snapBackImageTinted.size = NSMakeSize(12,12);
		[self.snapBackImageTinted lockFocus];
		NSRect imageRect3 = {NSZeroPoint,[self.snapBackImage size]};
		[self.snapBackButtonTint set];
		NSRectFillUsingOperation(imageRect3,NSCompositeSourceAtop);
		[self.mouseDownTintAdjustment set];
		NSRectFillUsingOperation(imageRect3,NSCompositeSourceAtop);
		[self.snapBackImageTinted unlockFocus];
	}
}

- (void) tintClearImage {
	//set first tint image.
	self.clearImage = [[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate] copy];
	self.clearImage.size = NSMakeSize(12,12);
	[self.clearImage lockFocus];
	[self.clearButtonTint set];
	NSRect imageRect = {NSZeroPoint,[self.clearImage size]};
	NSRectFillUsingOperation(imageRect,NSCompositeSourceAtop);
	[self.clearImage unlockFocus];
	
	if(self.mouseDownTintAdjustment) {
		//set another tinted image with a bit darker tint.
		self.clearImageTinted = [[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate] copy];
		self.clearImageTinted.size = NSMakeSize(12,12);
		[self.clearImageTinted lockFocus];
		NSRect imageRect3 = {NSZeroPoint,[self.clearImageTinted size]};
		[self.clearButtonTint set];
		NSRectFillUsingOperation(imageRect3,NSCompositeSourceAtop);
		[self.mouseDownTintAdjustment set];
		NSRectFillUsingOperation(imageRect3,NSCompositeSourceAtop);
		[self.clearImageTinted unlockFocus];
	}
}

- (void) clear; {
	self.modifierFlags = 0;
	self.previousModifierFlags = 0;
	self.keyCode = -1;
	self.previousKeyCode = -1;
	self.mutableLabel = [NSMutableString stringWithString:@""];
	self.previousMutableLabel = [NSMutableString stringWithString:@""];
	[self setNeedsDisplay:TRUE];
}

- (void) setDefaultLabel:(NSString *) defaultLabel {
	_defaultLabel = defaultLabel;
	[self setNeedsDisplay:TRUE];
}

- (void) setDefaultAttributes:(NSDictionary *) defaultAttributes {
	_defaultAttributes = defaultAttributes;
	[self setNeedsDisplay:TRUE];
}

- (void) setWaitingForKeysLabel:(NSString *) waitingForKeysLabel {
	_waitingForKeysLabel = waitingForKeysLabel;
	[self setNeedsDisplay:TRUE];
}

- (void) setWaitingForKeysAttributes:(NSDictionary *) waitingForKeysAttributes {
	_waitingForKeysAttributes = waitingForKeysAttributes;
	[self setNeedsDisplay:TRUE];
}

- (void) setSnapBackButtonTint:(NSColor *) snapBackTint {
	_snapBackButtonTint = snapBackTint;
	[self tintSnapBackImage];
	[self setNeedsDisplay:TRUE];
}

- (void) setClearButtonTint:(NSColor *) clearTint {
	_clearButtonTint = clearTint;
	[self tintClearImage];
	[self setNeedsDisplay:TRUE];
}

- (void) setMouseDownTintAdjustment:(NSColor *)mouseDownTintAdjustment {
	_mouseDownTintAdjustment = mouseDownTintAdjustment;
	[self tintClearImage];
	[self tintSnapBackImage];
	[self setNeedsDisplay:TRUE];
}

- (void) setKeyCode:(NSInteger) keyCode andModifierFlags:(NSEventModifierFlags) modifierFlags; {
	self.modifierFlags = modifierFlags;
	self.keyCode = keyCode;
	self.mutableLabel = [[NSMutableString alloc] initWithString:[self stringFromKeyCode:keyCode andModifierFlags:modifierFlags]];
	[self setNeedsDisplay:TRUE];
}

- (void) centerRect:(NSRect *) rect inRect:(NSRect) containerRect {
	rect->origin.x = (containerRect.size.width - rect->size.width) / 2;
	rect->origin.y = (containerRect.size.height - rect->size.height) / 2;
}

- (void) pushKeyboardShortcut {
	if(self.isRecording) {
		return;
	}
	
	if(self.keyCode > -1 || self.modifierFlags > 0) {
		if(self.delegate && [self.delegate conformsToProtocol:@protocol(GWShortcutRecorderDelegate)]) {
			[self.delegate shortcutRecorder:self didClearFlags:self.modifierFlags andKeyCode:self.keyCode];
		}
	}
	
	self.previousModifierFlags = self.modifierFlags;
	self.previousKeyCode = self.keyCode;
	self.previousMutableLabel = self.mutableLabel;
	self.modifierFlags = 0;
	self.keyCode = -1;
	self.mutableLabel = [NSMutableString string];
}

- (void) popKeyboardShortcut {
	if(self.previousModifierFlags == 0 && self.previousKeyCode == -1) {
		self.modifierFlags = 0;
		self.keyCode = -1;
		self.mutableLabel = [NSMutableString string];
	} else {
		self.modifierFlags = self.previousModifierFlags;
		self.keyCode = self.previousKeyCode;
		self.mutableLabel = self.previousMutableLabel;
		
		if(self.delegate && [self.delegate conformsToProtocol:@protocol(GWShortcutRecorderDelegate)]) {
			[self.delegate shortcutRecorder:self setFlags:self.modifierFlags andKeyCode:self.keyCode];
		}
		
		self.previousModifierFlags = 0;
		self.previousKeyCode = -1;
		self.previousMutableLabel = [NSMutableString string];
	}
}

- (void) clearKeyboardShortcut {
	if(self.delegate && [self.delegate conformsToProtocol:@protocol(GWShortcutRecorderDelegate)]) {
		[self.delegate shortcutRecorder:self didClearFlags:self.modifierFlags andKeyCode:self.keyCode];
	}
	self.previousModifierFlags = 0;
	self.previousKeyCode = -1;
	self.previousMutableLabel = nil;
	self.modifierFlags = 0;
	self.keyCode = -1;
	self.mutableLabel = [NSMutableString string];
}

- (NSString *) stringFromKeyCode:(unsigned short) keyCode andModifierFlags:(NSEventModifierFlags) modifierFlags {
	NSMutableString * stringValue = [[NSMutableString alloc] init];
	
	if(modifierFlags & NSControlKeyMask) {
		[stringValue appendFormat:@"%C",(unichar)kControlUnicode];
	}
	
	if(modifierFlags & NSAlternateKeyMask) {
		[stringValue appendFormat:@"%C",(unichar)kOptionUnicode];
	}
	
	if(modifierFlags & NSShiftKeyMask) {
		[stringValue appendFormat:@"%C",(unichar)kShiftUnicode];
	}
	
	if(modifierFlags & NSCommandKeyMask) {
		[stringValue appendFormat:@"%C",(unichar)kCommandUnicode];
	}
	
	NSString * raw = @"";
	
	switch (keyCode) {
		case kVK_F1:
			[stringValue appendString:@"F1"];
			break;
		case kVK_F2:
			[stringValue appendString:@"F2"];
			break;
		case kVK_F3:
			[stringValue appendString:@"F3"];
			break;
		case kVK_F4:
			[stringValue appendString:@"F4"];
			break;
		case kVK_F5:
			[stringValue appendString:@"F5"];
			break;
		case kVK_F6:
			[stringValue appendString:@"F6"];
			break;
		case kVK_F7:
			[stringValue appendString:@"F7"];
			break;
		case kVK_F8:
			[stringValue appendString:@"F8"];
			break;
		case kVK_F9:
			[stringValue appendString:@"F9"];
			break;
		case kVK_F10:
			[stringValue appendString:@"F10"];
			break;
		case kVK_F11:
			[stringValue appendString:@"F11"];
			break;
		case kVK_F12:
			[stringValue appendString:@"F12"];
			break;
		case kVK_F13:
			[stringValue appendString:@"F13"];
			break;
		case kVK_F14:
			[stringValue appendString:@"F14"];
			break;
		case kVK_F15:
			[stringValue appendString:@"F15"];
			break;
		case kVK_F16:
			[stringValue appendString:@"F16"];
			break;
		case kVK_F17:
			[stringValue appendString:@"F17"];
			break;
		case kVK_F18:
			[stringValue appendString:@"F18"];
			break;
		case kVK_F19:
			[stringValue appendString:@"F19"];
			break;
		case kVK_F20:
			[stringValue appendString:@"F20"];
			break;
		case kVK_ANSI_KeypadClear:
			[stringValue appendFormat:@"%C",0x2327];
			break;
		case kVK_ANSI_KeypadEnter:
			[stringValue appendFormat:@"%C",0x2305];
			break;
		case kVK_Delete:
			[stringValue appendFormat:@"%C",0x232B];
			break;
		case kVK_DownArrow:
			[stringValue appendFormat:@"%C",0x2193];
			break;
		case kVK_End:
			[stringValue appendFormat:@"%C",0x2198];
			break;
		case kVK_Escape:
			[stringValue appendFormat:@"%C",0x238B];
			break;
		case kVK_ForwardDelete:
			[stringValue appendFormat:@"%C",0x2326];
			break;
		case kVK_Help:
			[stringValue appendString:@"?⃝"];
			break;
		case kVK_Home:
			[stringValue appendFormat:@"%C",0x2196];
			break;
		case kVK_LeftArrow:
			[stringValue appendFormat:@"%C",0x2190];
			break;
		case kVK_PageDown:
			[stringValue appendFormat:@"%C",0x2190];
			break;
		case kVK_PageUp:
			[stringValue appendFormat:@"%C",0x21DE];
			break;
		case kVK_Space:
			[stringValue appendFormat:@"%@",@"Space"];
			break;
		case kVK_Return:
			[stringValue appendFormat:@"%C",0x21A9];
			break;
		case kVK_RightArrow:
			[stringValue appendFormat:@"%C",0x2192];
			break;
		case kVK_Tab:
			[stringValue appendFormat:@"%C",0x21E5];
			break;
		case kVK_UpArrow:
			[stringValue appendFormat:@"%C",0x2191];
			break;
		default:
			raw = [GWShortcutRecorder stringForRawKeyCode:keyCode];
			[stringValue appendString:raw];
			break;
	}
	
	return stringValue;
}

- (void) flagsChanged:(NSEvent *) theEvent {
	if(!self.isRecording) {
		return;
	}
	
	NSEventModifierFlags flags = 0;
	self.mutableLabel = [NSMutableString string];
	
	if(theEvent.modifierFlags & NSControlKeyMask) {
		flags |= NSControlKeyMask;
		[self.mutableLabel appendString:@"⌃"];
	}
	
	if(theEvent.modifierFlags & NSAlternateKeyMask) {
		flags |= NSAlternateKeyMask;
		[self.mutableLabel appendString:@"⌥"];
	}
	
	if(theEvent.modifierFlags & NSShiftKeyMask) {
		flags |= NSShiftKeyMask;
		[self.mutableLabel appendString:@"⇧"];
	}
	
	if(theEvent.modifierFlags & NSCommandKeyMask) {
		flags |= NSCommandKeyMask;
		[self.mutableLabel appendString:@"⌘"];
	}
	
	self.modifierFlags = flags;
	
	[self setNeedsDisplay:TRUE];
}

- (BOOL) performKeyEquivalent:(NSEvent *) theEvent {
	if(self.window.firstResponder != self) {
		return FALSE;
	}
	
	if(!self.isRecording && theEvent.keyCode == 51) { //delete
		self.isRecording = FALSE;
		[self clearKeyboardShortcut];
		[self setNeedsDisplay:TRUE];
		return TRUE;
	}
	
	if(self.isRecording && theEvent.keyCode == 53) { //escape
		self.isRecording = FALSE;
		[self popKeyboardShortcut];
		[self setNeedsDisplay:TRUE];
		return TRUE;
	}
	
	if(!self.isRecording && theEvent.keyCode == 49) { //space
		[self pushKeyboardShortcut];
		self.isRecording = TRUE;
		[self setNeedsDisplay:TRUE];
		return TRUE;
	}
	
        if (!self.captureTabKey) {
                	if(self.isRecording && theEvent.keyCode == 48) { //tab
                		self.isRecording = FALSE;
                		[self popKeyboardShortcut];
                		[self setNeedsDisplay:TRUE];
                		return TRUE;
                	}
        }
	
	if(self.isRecording) {
		if(self.modifierFlags < 1) {
			NSBeep();
			self.isRecording = FALSE;
			[self popKeyboardShortcut];
			[self setNeedsDisplay:TRUE];
			return false;
		}
		NSString * displayValue = [self stringFromKeyCode:theEvent.keyCode andModifierFlags:theEvent.modifierFlags];
		self.mutableLabel = [[NSMutableString alloc] initWithString:displayValue];
		self.keyCode = theEvent.keyCode;
		self.isRecording = FALSE;
		[self setNeedsDisplay:TRUE];
		if(self.delegate && [self.delegate conformsToProtocol:@protocol(GWShortcutRecorderDelegate)]) {
			[self.delegate shortcutRecorder:self setFlags:self.modifierFlags andKeyCode:self.keyCode];
		}
		return TRUE;
	}
	
	return FALSE;
}

- (void) keyDown:(NSEvent *) theEvent {
	//NSLog(@"keyCode: %d, modifiers:%lu",theEvent.keyCode,theEvent.modifierFlags);
	if(![self performKeyEquivalent:theEvent]) {
		[super keyDown:theEvent];
	}
}

- (BOOL) isMouseInClearButton:(NSPoint) pointInView {
	if([self clearButtonVisible] && NSPointInRect(pointInView,[self clearButtonRect])) {
		return TRUE;
	}
	return FALSE;
}

- (BOOL) isMouseInSnapBackButton:(NSPoint) pointInView {
	if([self snapBackButtonVisible] && NSPointInRect(pointInView,[self snapBackButtonRect])) {
		return TRUE;
	}
	return FALSE;
}

- (void) mouseDown:(NSEvent *) theEvent {
	[super mouseDown:theEvent];
	
	if(self.window.firstResponder != self) {
		[self.window makeFirstResponder:self];
	}
	
	NSPoint pointInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
	
	if([self isMouseInClearButton:pointInView]) {
		self.mouseDownInClear = TRUE;
		[self setNeedsDisplay:TRUE];
		return;
	}
	
	if([self isMouseInSnapBackButton:pointInView]) {
		self.mouseDownInSnapBack = TRUE;
		[self setNeedsDisplay:TRUE];
		return;
	}
	
	[self pushKeyboardShortcut];
	self.isRecording = TRUE;
	[self setNeedsDisplay:TRUE];
}

- (void) mouseUp:(NSEvent *) theEvent {
	NSPoint pointInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
	
	if(self.mouseDownInClear && [self isMouseInClearButton:pointInView]) {
		self.mouseDownInClear = FALSE;
		self.isRecording = FALSE;
		[self clearKeyboardShortcut];
	}
	
	if(self.mouseDownInSnapBack && [self isMouseInSnapBackButton:pointInView]) {
		self.mouseDownInSnapBack = FALSE;
		self.isRecording = FALSE;
		[self popKeyboardShortcut];
	}
	
	self.mouseDownInSnapBack = FALSE;
	self.mouseDownInClear = FALSE;
	[self setNeedsDisplay:TRUE];
}

- (BOOL) acceptsFirstResponder {
	[self setKeyboardFocusRingNeedsDisplayInRect:self.bounds];
	return [super resignFirstResponder];
}

- (BOOL) resignFirstResponder {
	self.isRecording = FALSE;
	[self setNeedsDisplay:TRUE];
	return TRUE;
}

- (BOOL) becomeFirstResponder {
	[self setKeyboardFocusRingNeedsDisplayInRect:self.bounds];
	return [super becomeFirstResponder];
}

- (BOOL) canBecomeKeyView {
	return TRUE;
}

- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent {
	return TRUE;
}

- (BOOL) needsPanelToBecomeKey {
	return YES;
}

- (BOOL) isFlipped {
	return YES;
}

- (NSMutableAttributedString *) labelToDraw {
	NSMutableAttributedString * label = nil;
	if(self.mutableLabel.length > 0) {
		label = [[NSMutableAttributedString alloc] initWithString:self.mutableLabel attributes:self.defaultAttributes];
	}
	else if(self.isRecording && self.mutableLabel.length == 0) {
		label = [[NSMutableAttributedString alloc] initWithString:self.waitingForKeysLabel attributes:self.waitingForKeysAttributes];
	}
	else if(!self.isRecording && self.mutableLabel.length == 0) {
		label = [[NSMutableAttributedString alloc] initWithString:self.defaultLabel attributes:self.defaultAttributes];
	}
	return label;
}

- (NSRect) rectForLabel {
	NSMutableAttributedString * labelToDraw = [self labelToDraw];
	NSRect rect = [labelToDraw boundingRectWithSize:self.bounds.size options:0];
	return rect;
}

- (NSRect) innerRect {
	NSRect bounds = self.bounds;
	bounds.size.height -= 3;
	return bounds;
}

- (void) drawBackground {
	NSRect bounds = self.bounds;
	NSRect shorterBounds = NSMakeRect(bounds.origin.x,bounds.origin.y,bounds.size.width,bounds.size.height-(1/self.window.backingScaleFactor));
	NSRect insetRect = NSInsetRect(shorterBounds,(1/self.window.backingScaleFactor),(1/self.window.backingScaleFactor));
	NSColor * gray = nil;
	NSColor * white = [NSColor whiteColor];
	
	//save context and turn off antialias so lines are 1 px.
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	
	//draw very light gray line.
	NSBezierPath * line = [NSBezierPath bezierPath];
//	gray = [NSColor colorWithDeviceRed:0.905 green:0.905 blue:0.905 alpha:1];
//	[gray setStroke];
//	[line setLineWidth:1/self.window.backingScaleFactor];
//	[line moveToPoint:NSMakePoint(3,bounds.size.height)];
//	[line lineToPoint:NSMakePoint(self.bounds.size.width-3,bounds.size.height)];
//	[line stroke];
//	
//	//draw light gray line over.
//	line = [NSBezierPath bezierPath];
//	gray = [NSColor colorWithRed:0 green:0 blue:0 alpha:0]; //[NSColor colorWithDeviceRed:0.892 green:0.892 blue:0.892 alpha:1];
//	[gray setStroke];
//	[line setLineWidth:1/self.window.backingScaleFactor];
//	[line moveToPoint:NSMakePoint(4,bounds.size.height)];
//	[line lineToPoint:NSMakePoint(self.bounds.size.width-4,bounds.size.height)];
//	[line stroke];
	
	//restore context
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	//draw darker gray border
	NSBezierPath * bg = [NSBezierPath bezierPathWithRoundedRect:shorterBounds xRadius:4 yRadius:4];
	gray = [NSColor colorWithDeviceRed:0.784 green:0.784 blue:0.784 alpha:1];
	[gray setFill];
	[bg fill];
	
	//draw white inner
	NSBezierPath * insetbg = [NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:4 yRadius:4];
	[white setFill];
	[insetbg fill];
	
	//save context and turn off antialias so lines are 1 px.
	[[NSGraphicsContext currentContext] saveGraphicsState];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	
	//draw slightly darker line over white inner
	line = [NSBezierPath bezierPath];
	gray = [NSColor colorWithDeviceRed:0.716 green:0.716 blue:0.716 alpha:1];
	[gray setStroke];
	[line setLineWidth:1/self.window.backingScaleFactor];
	[line moveToPoint:NSMakePoint(3*self.window.backingScaleFactor,shorterBounds.size.height)];
	[line lineToPoint:NSMakePoint(self.bounds.size.width-(3*self.window.backingScaleFactor),shorterBounds.size.height)];
	[line stroke];
	
	//draw darker line over white inner
	line = [NSBezierPath bezierPath];
	gray = [NSColor colorWithDeviceRed:0.674 green:0.674 blue:0.674 alpha:1];
	[gray setStroke];
	[line setLineWidth:(1/self.window.backingScaleFactor)];
	[line moveToPoint:NSMakePoint(4,shorterBounds.size.height)];
	[line lineToPoint:NSMakePoint(self.bounds.size.width-4,shorterBounds.size.height)];
	[line stroke];
	
	//restore context
	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (BOOL) clearButtonVisible {
	return self.previousMutableLabel.length > 0;
}

- (NSRect) clearButtonRect {
	NSRect bounds = self.bounds;
	NSSize imageSize = self.clearImage.size;
	int pad = 4;
	NSRect rect = NSMakeRect(bounds.size.width - (imageSize.width+pad), (self.bounds.size.height-12)/2,12,12);
	return rect;
}

- (void) drawClearButton {
	NSRect rect = [self clearButtonRect];
	if(self.mouseDownInClear) {
		[self.clearImageTinted drawInRect:rect];
	} else {
		[self.clearImage drawInRect:rect];
	}
}

- (BOOL) snapBackButtonVisible {
	return self.isRecording;
}

- (NSRect) snapBackButtonRect {
	NSRect bounds = self.bounds;
	NSSize imageSize = self.snapBackImage.size;
	int pad = 4;
	NSRect rect = NSMakeRect(bounds.size.width - (imageSize.width+pad), (self.bounds.size.height-12)/2,12,12);
	if(self.previousMutableLabel.length > 0) {
		rect.origin.x -= 16;
	}
	return rect;
}

- (void) drawSnapBackButton {
	NSRect rect = [self snapBackButtonRect];
	if(self.mouseDownInSnapBack) {
		[self.snapBackImageTinted drawInRect:rect];
	} else {
		[self.snapBackImage drawInRect:rect];
	}
}

- (void) drawLabel {
	NSRect labelRect = [self rectForLabel];
	[self centerRect:&labelRect inRect:[self innerRect]];
	NSMutableAttributedString * label = [self labelToDraw];
	[label drawInRect:labelRect];
}

- (void) drawRect:(NSRect) dirtyRect {
	[super drawRect:dirtyRect];
	[self drawBackground];
	[self drawLabel];
	if(self.isRecording) {
		if(self.previousMutableLabel.length > 0) {
			[self drawClearButton];
		}
		[self drawSnapBackButton];
	}
}

- (void) drawFocusRingMask {
	NSRect bounds = self.bounds;
	bounds.size.height -= 1;
	NSRect insetBounds = NSInsetRect(bounds,1,1);
	NSBezierPath * path = [NSBezierPath bezierPathWithRoundedRect:insetBounds xRadius:4 yRadius:4];
	[path fill];
}

- (NSRect) focusRingMaskBounds {
	return self.bounds;
}

@end
