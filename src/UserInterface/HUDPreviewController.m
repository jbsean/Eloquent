//
//  HUDPreviewController.m
//  MacSword2
//
//  Created by Manfred Bergmann on 10.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "HUDPreviewController.h"
#import "MBPreferenceController.h"
#import "ObjCSword/SwordManager.h"
#import "ObjCSword/SwordModule.h"
#import "ObjCSword/SwordModuleTextEntry.h"
#import "ObjCSword/SwordKey.h"
#import "globals.h"


@implementation HUDPreviewController

@synthesize delegate;

+ (NSDictionary *)previewDataFromDict:(NSDictionary *)previewData {
    NSMutableDictionary *ret = nil;
    
    if(previewData) {
        NSString *module = [previewData objectForKey:ATTRTYPE_MODULE];
        if(!module || [module length] == 0) {
            // get module for previewtype
            module = [userDefaults stringForKey:DefaultsBibleModule];
            NSString *attrType = [previewData objectForKey:ATTRTYPE_TYPE];
            if([attrType isEqualToString:@"Hebrew"]) {
                module = [userDefaults stringForKey:DefaultsStrongsHebrewModule];
            } else if([attrType isEqualToString:@"Greek"]) {
                module = [userDefaults stringForKey:DefaultsStrongsGreekModule];
            } else if([attrType hasPrefix:@"strongMorph"] || [attrType hasPrefix:@"robinson"]) {
                module = [userDefaults stringForKey:DefaultsMorphGreekModule];
            }
        }
        
        if(module) {
            ret = [NSMutableDictionary dictionary];
            
            SwordModule *mod = [[SwordManager defaultManager] moduleWithName:module];
            NSMutableString *displayText = [NSMutableString string];
            NSString *displayType = @"";
            if([[previewData objectForKey:ATTRTYPE_ACTION] isEqualToString:@"showNote"]) {
                if([[previewData objectForKey:ATTRTYPE_TYPE] isEqualToString:@"n"]) {
                    displayType = SW_OPTION_FOOTNOTES;
                } else if([[previewData objectForKey:ATTRTYPE_TYPE] isEqualToString:@"x"]) {
                    displayType = SW_OPTION_SCRIPTREFS;                    
                }
            } else if([[previewData objectForKey:ATTRTYPE_ACTION] isEqualToString:@"showStrongs"]) {
                displayType = SW_OPTION_STRONGS;            
            } else if([[previewData objectForKey:ATTRTYPE_ACTION] isEqualToString:@"showMorph"]) {
                displayType = SW_OPTION_MORPHS;
            } else if([[previewData objectForKey:ATTRTYPE_ACTION] isEqualToString:@"showRef"]) {
                displayType = SW_OPTION_REF;
            }
            [ret setObject:displayType forKey:@"PreviewDisplayTypeKey"];
            
            id result = [mod attributeValueForParsedLinkData:previewData];
            if(result != nil) {
                if([result isKindOfClass:[NSArray class]]) {
                    // prepare for view
                    for(SwordModuleTextEntry *entry in (NSArray *)result) {
                        NSString *verseText = [entry text];
                        NSString *key = [entry key];
                        
                        [displayText appendFormat:@"%@:\n%@\n", key, verseText];
                    }
                } else if([result isKindOfClass:[NSString class]]) {
                    displayText = result;
                } else if([result isKindOfClass:[SwordModuleTextEntry class]]) {
                    NSString *verseText = [(SwordModuleTextEntry *)result text];
                    NSString *key = [(SwordModuleTextEntry *)result key];
                    
                    [displayText appendFormat:@"%@:\n%@\n", key, verseText];                    
                }
            }
            [ret setObject:displayText forKey:@"PreviewDisplayTextKey"];            
        }      
    }

    return ret;
}

- (id)init {
    return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id)aDelegate {
	self = [super init];
    if(self) {
        delegate = aDelegate;
	}
	
	return self;
}

- (void)awakeFromNib {
    [previewText setTextColor:[NSColor lightGrayColor]];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(showPreviewData:)
                                                 name:NotificationShowPreviewData object:nil];    
}

- (void)finalize {
    [super finalize];
}

- (void)windowWillClose:(NSNotification *)notification {
    [userDefaults setBool:NO forKey:DefaultsShowHUDPreview];
    
    if(delegate && [delegate respondsToSelector:@selector(auxWindowClosing:)]) {
        [delegate performSelector:@selector(auxWindowClosing:) withObject:self];
    } else {
        CocoLog(LEVEL_WARN, @"[WindowHostController -windowWillClose:] delegate does not respond to selector!");
    }
}

#pragma mark - Notifications

- (void)showPreviewData:(NSNotification *)aNotification {
    NSDictionary *data = [aNotification object];
    NSDictionary *previewDict = [HUDPreviewController previewDataFromDict:data];
    if(previewDict) {
        [previewType setStringValue:[previewDict objectForKey:PreviewDisplayTypeKey]];
        [previewText setString:[previewDict objectForKey:PreviewDisplayTextKey]];            
    }
}

#pragma mark - Actions


@end
