/* 
 Boxer is copyright 2009 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/GNU General Public License.txt, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */

#import "BXInspectorController.h"
#import "BXSession.h"
#import "BXEmulator.h"
#import "BXDrive.h"
#import "BXAppController.h"
#import "BXValueTransformers.h"
#import "NSWindow+BXWindowEffects.h"

#import "BXDOSWindowController.h"
#import "BXInputController.h"

const CGFloat BXInspectorPanelBlurRadius = 2.0f;
const CGFloat BXMouseSensitivityRange = 2.0f;

@implementation BXInspectorController
@synthesize panelSelector;

+ (void) initialize
{
	NSArray *sensitivityThresholds = [NSArray arrayWithObjects:
									  [NSNumber numberWithFloat: 1.0f / BXMouseSensitivityRange],
									  [NSNumber numberWithFloat: 1.0f],
									  [NSNumber numberWithFloat: 1.0f * BXMouseSensitivityRange],
									  nil];
	
	BXBandedValueTransformer *mouseSensitivity = [[BXBandedValueTransformer alloc] initWithThresholds: sensitivityThresholds];
	
	[NSValueTransformer setValueTransformer: mouseSensitivity forName: @"BXMouseSensitivitySlider"];
	
	[mouseSensitivity release];
}

+ (BXInspectorController *)controller
{
	static BXInspectorController *singleton = nil;
	if (!singleton) singleton = [[self alloc] initWithWindowNibName: @"InspectorPanel"];
	return singleton;
}

- (void) dealloc
{
	[self setPanelSelector: nil], [panelSelector release];
	
	[super dealloc];
}

- (void) awakeFromNib
{
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded: YES];
	
	[[self window] setFrameAutosaveName: @"InspectorPanel"];
	
	//Set the initial panel based on the user's last chosen panel (defaulting to the CPU panel)
	NSInteger selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey: @"initialInspectorPanelIndex"];
	
	if (selectedIndex < 0 || selectedIndex > [[self tabView] numberOfTabViewItems])
		selectedIndex = BXCPUInspectorPanelTag;
	
	[[self tabView] selectTabViewItemAtIndex: selectedIndex];
	
	
	//Listen for changes to the current session
	[[NSApp delegate] addObserver: self
					   forKeyPath: @"currentSession"
						  options: NSKeyValueObservingOptionInitial
						  context: nil];
}

//Whenever the session changes, update the availability of the gamebox panel
- (void) observeValueForKeyPath: (NSString *)keyPath
					   ofObject: (id)object
						 change: (NSDictionary *)change
						context: (void *)context
{	
	BXSession *session = [[NSApp delegate] currentSession];
	if ([keyPath isEqualToString: @"currentSession"])
	{
		if (session)
		{
			//Disable the gamebox tab if the current session is not a gamebox
			
			//Find the panel selector segment whose tag corresponds to the game inspector panel
			//(This charade is necessary because NSSegmentedControl has an awful interface)
			NSInteger i;
			for (i = 0; i < [[self panelSelector] segmentCount]; i++)
			{
				if ([[[self panelSelector] cell] tagForSegment: i] == BXGameInspectorPanelTag)
					[[self panelSelector] setEnabled: [session isGamePackage] forSegment: i];
			}
			
			//If the gamebox tab was already selected, then switch to the next tab
			if (![session isGamePackage] &&
				[[self tabView] indexOfTabViewItem: [[self tabView] selectedTabViewItem]] == BXGameInspectorPanelTag)
			{
				[[self tabView] selectTabViewItemAtIndex: BXCPUInspectorPanelTag];
			}
		}
	}
}

- (void) showWindow: (id)sender
{
	[self loadWindow];
	[[self window] fadeInWithDuration: 0.2];
	[[self window] applyGaussianBlurWithRadius: BXInspectorPanelBlurRadius];
	
	isTemporarilyHidden = NO;
}

+ (NSSet *) keyPathsForValuesAffectingPanelShown
{
	return [NSSet setWithObject: @"window.visible"];
}

- (void) setPanelShown: (BOOL)show
{
	if (show)
	{
		[self showWindow: self];
		
		//Unlock the mouse from the DOS window whenever the Inspector panel is shown
		//(This will happen automatically for normal windows, but since we're an NSPanel
		//that doesnt become key automatically, the DOS window doesn't know to release
		//mouse focus)
		[NSApp sendAction: @selector(toggleMouseLocked:) to: nil from: [NSNumber numberWithBool: NO]];
		
	}
	else if ([self isWindowLoaded])
	{
		[[self window] fadeOutWithDuration: 0.2];
		isTemporarilyHidden = NO;
	}
}

- (BOOL) panelShown
{
	return [self isWindowLoaded] && [[self window] isVisible];
}

- (BOOL) windowShouldClose: (id)sender
{
	[[self window] fadeOutWithDuration: 0.2];
	isTemporarilyHidden = NO;
	return NO;
}

- (void) windowDidUpdate: (NSNotification *)notification
{
	[self willChangeValueForKey: @"panelShown"];
	[self didChangeValueForKey: @"panelShown"];
}


- (void) hideIfVisible
{
	if ([self panelShown])
	{
		[self setPanelShown: NO];
		isTemporarilyHidden = YES;
	}
}

- (void) revealIfHidden
{
	if (isTemporarilyHidden)
	{
		[self setPanelShown: YES];
		isTemporarilyHidden = NO;
	}
}


#pragma mark -
#pragma mark Tab selection

- (IBAction) showGameInspectorPanel: (id)sender		{ [self showPanelAtTabIndex: BXGameInspectorPanelTag]; }
- (IBAction) showCPUInspectorPanel: (id)sender		{ [self showPanelAtTabIndex: BXCPUInspectorPanelTag]; }
- (IBAction) showMouseInspectorPanel: (id)sender	{ [self showPanelAtTabIndex: BXMouseInspectorPanelTag]; }
- (IBAction) showDriveInspectorPanel: (id)sender	{ [self showPanelAtTabIndex: BXDriveInspectorPanelTag]; }

- (void) showPanelAtTabIndex: (NSUInteger)tabIndex
{
	[[self tabView] selectTabViewItemAtIndex: tabIndex];
	[self showWindow: nil];
}

- (void) tabView: (NSTabView *)tabView didSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
	[super tabView: tabView didSelectTabViewItem: tabViewItem];
	
	//Record the user's choice of tab, and synchronize the selected segment
	NSInteger selectedIndex = [tabView indexOfTabViewItem: tabViewItem];
	
	if (selectedIndex != NSNotFound)
	{
		[[NSUserDefaults standardUserDefaults] setInteger: selectedIndex
												   forKey: @"initialInspectorPanelIndex"];
		
		
		[[self panelSelector] selectSegmentWithTag: selectedIndex];
	}
}

- (BOOL) tabView: (NSTabView *)tabView shouldSelectTabViewItem: (NSTabViewItem *)tabViewItem
{
	return ([tabView indexOfTabViewItem: tabViewItem] != BXGameInspectorPanelTag ||
			[[[NSApp delegate] currentSession] isGamePackage]);
}

@end
