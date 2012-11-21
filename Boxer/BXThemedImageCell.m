/* 
 Boxer is copyright 2011 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/BoxerHelp/pages/legalese.html, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */

#import "BXThemedImageCell.h"
#import "BXGeometry.h"
#import "NSShadow+BXShadowExtensions.h"
#import "NSImage+BXImageEffects.h"
#import "BXThemes.h"


@interface BXThemedImageCell ()

@property (readonly, nonatomic) NSGradient *_fillForCurrentState;
@property (readonly, nonatomic) NSShadow *_dropShadowForCurrentState;
@property (readonly, nonatomic) NSShadow *_innerShadowForCurrentState;

@end

@implementation BXThemedImageCell
@synthesize themeKey = _themeKey;
@synthesize pushed = _pushed;
@synthesize selected = _selected;
@synthesize highlighted = _highlighted;


#pragma mark - Default theme handling

- (BGTheme *) themeForKey
{
    return [[BGThemeManager keyedManager] themeForKey: self.themeKey];
}

+ (NSString *) defaultThemeKey
{
    return nil;
}

- (id) initWithCoder: (NSCoder *)coder
{
    self = [super initWithCoder: coder];
    if (self)
    {
        if (![coder containsValueForKey: @"themeKey"])
            self.themeKey = [self.class defaultThemeKey];
    }
    return self;
}



- (void) dealloc
{
    self.themeKey = nil;
	[super dealloc];
}

- (NSGradient *) _fillForCurrentState
{
    if (self.isPushed)
        return self.themeForKey.pushedImageFill;
    
    if (self.isSelected)
        return self.themeForKey.selectedImageFill;
    
    if (self.isHighlighted)
        return self.themeForKey.highlightedImageFill;
    
    if (!self.isEnabled)
        return self.themeForKey.disabledImageFill;
    
    return self.themeForKey.imageFill;
}

- (NSShadow *) _innerShadowForCurrentState
{
    if (self.isPushed)
        return self.themeForKey.pushedImageInnerShadow;
    
    if (self.isSelected)
        return self.themeForKey.selectedImageInnerShadow;
    
    if (self.isHighlighted)
        return self.themeForKey.highlightedImageInnerShadow;
    
    if (!self.isEnabled)
        return self.themeForKey.disabledImageInnerShadow;
    
    return self.themeForKey.imageInnerShadow;
}

- (NSShadow *) _dropShadowForCurrentState
{    
    if (self.isPushed)
        return self.themeForKey.pushedImageDropShadow;
    
    if (self.isSelected)
        return self.themeForKey.selectedImageDropShadow;
    
    if (self.isHighlighted)
        return self.themeForKey.highlightedImageDropShadow;
    
    if (!self.isEnabled)
        return self.themeForKey.disabledImageDropShadow;
    
    return self.themeForKey.imageDropShadow;
}

- (NSRect) imageRectForBounds: (NSRect)theRect
{
    NSRect imageRect = [super imageRectForBounds: theRect];
    
    NSShadow *dropShadow = self._dropShadowForCurrentState;
    if (self.image.isTemplate && dropShadow != nil)
    {
        //If we have a shadow set, then constrain the image region to accomodate the shadow
        imageRect = [dropShadow insetRectForShadow: imageRect
                                           flipped: self.controlView.isFlipped];
    }
    return imageRect;
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView *)controlView
{
	//Apply our foreground colour and shadow when drawing any template image
	if (self.image.isTemplate)
	{
		NSRect imageRegion = [self imageRectForBounds: cellFrame];
        NSRect imageRect = [self.image imageRectAlignedInRect: imageRegion
                                                    alignment: self.imageAlignment
                                                      scaling: self.imageScaling];
        
        imageRect = NSIntegralRect(imageRect);
        
        [NSGraphicsContext saveGraphicsState];
            [self.image drawInRect: imageRect
                      withGradient: self._fillForCurrentState
                        dropShadow: self._dropShadowForCurrentState
                       innerShadow: self._innerShadowForCurrentState];
        [NSGraphicsContext restoreGraphicsState];
	}
	else
	{
		[super drawInteriorWithFrame: cellFrame inView: controlView];
	}
}

@end

@implementation BXHUDImageCell

+ (NSString *) defaultThemeKey
{
    return @"BXHUDTheme";
}

@end



@implementation BXIndentedImageCell

+ (NSString *) defaultThemeKey
{
    return @"BXIndentedTheme";
}

@end