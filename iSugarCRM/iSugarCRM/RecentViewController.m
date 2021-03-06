//
//  RecentViewController.m
//  iSugarCRM
//
//  Created by satyavrat-mac on 03/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RecentViewController.h"

@implementation RecentViewController

#pragma mark view-life-cycle methods

-(void)loadView{
    [super loadView];
}

-(void)viewDidLoad{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:YES];
    if([[self.dataSourceDictionary allKeys] count]==0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info" message:@"No Recent Items" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
    self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark initmethods

-(id)initWithRecentItems:(NSMutableDictionary*)recentItems{
    if (self = [super init]) {
         self.dataSourceDictionary = recentItems;
    }
    return self;
}
@end
