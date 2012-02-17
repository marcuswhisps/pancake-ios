//
//  ListViewController.m
//  iSugarCRM
//
//  Created by Ved Surtani on 06/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ListViewController.h"
#import "ListViewMetadata.h"
#import "SugarCRMMetadataStore.h"
#import "DBSession.h"
#import "DataObject.h"
#import "DetailViewController.h"
#import "ModuleSettingsViewController.h"
#import "ModuleSettingsDataStore.h"

@implementation ListViewController
@synthesize moduleName,datasource,metadata, tableData;
@synthesize segmentedControl;


+(ListViewController*)listViewControllerWithMetadata:(ListViewMetadata*)metadata
{
    ListViewController *lViewController = [[ListViewController alloc] init];
    lViewController.metadata = metadata;
    lViewController.moduleName = metadata.moduleName;
    return lViewController;

}

+(ListViewController*)listViewControllerWithModuleName:(NSString*)module
{
    ListViewController *lViewController = [[ListViewController  alloc] init];
    //lViewController.moduleName = module;
    return lViewController;
}

-(id)init{
    if (self=[super init]) {
        myTableView = [[UITableView alloc] init];
        tableData = [[NSMutableArray alloc] init];
    }
    return self;
}

-(UISegmentedControl *) segmentedControl{
    if (!segmentedControl) {
        segmentedControl = [[UISegmentedControl alloc] initWithItems:nil];
        [segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"settings.png"] atIndex:0 animated:YES];
        [segmentedControl insertSegmentWithImage:[UIImage imageNamed:@"sync.png"] atIndex:1 animated:YES];
    }
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    segmentedControl.frame = CGRectMake(0, 0, 90, 30);
    segmentedControl.momentary = YES;
    [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    return segmentedControl;
}

-(void)segmentAction:(id)sender{
    UISegmentedControl *segControl = (UISegmentedControl *)sender;
    if (segControl.selectedSegmentIndex == 0) {
        [self displayModuleSetting];
    }else if(segControl.selectedSegmentIndex == 1){
        [self synchModule];
    }
}


-(void)displayModuleSetting{
    ModuleSettingsViewController *msvc = [[ModuleSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    msvc.moduleName = self.title;
    [self.navigationController pushViewController:msvc animated:NO];
}


-(void)synchModule{
    //TODO module synch code;
    NSLog(@"SYNCH MODULES");
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    CGRect mainFrame = [[UIScreen mainScreen] applicationFrame];
    UIApplication *application = [UIApplication sharedApplication];
    CGFloat width = mainFrame.size.width;
    if (UIInterfaceOrientationIsLandscape(application.statusBarOrientation))
    {
        width = mainFrame.size.height;
    }
    sBar = [[UISearchBar alloc]initWithFrame:CGRectMake(0,0,width,30)];
    sBar.delegate = self;
    [sBar setAutoresizesSubviews:YES];
    [self.view addSubview:sBar];
    myTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 31,width, mainFrame.size.height-30)];
    [sBar setAutoresizesSubviews:YES];
    [self.view addSubview:myTableView];
    [self.view setAutoresizesSubviews:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    datasource = [[NSMutableArray alloc] init];
    if (!metadata) {
      self.metadata = [[SugarCRMMetadataStore sharedInstance]listViewMetadataForModule:moduleName];
    }
    //myTableView = [[UITableView alloc] init];
    myTableView.delegate = self;
    myTableView.dataSource = self;
    //myTableView.frame = [[UIScreen mainScreen] applicationFrame];
    CGFloat rowHeight = 20.f + [[metadata otherFields] count] *15 + 10;
    myTableView.rowHeight = rowHeight>51.0?rowHeight:51.0f;
    //self.view = myTableView;
    
    
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.segmentedControl];
    self.navigationItem.rightBarButtonItem = barButtonItem;
    
    SugarCRMMetadataStore *sharedInstance = [SugarCRMMetadataStore sharedInstance];
    DBMetadata *dbMetadata = [sharedInstance dbMetadataForModule:metadata.moduleName];
    DBSession * dbSession = [DBSession sessionWithMetadata:dbMetadata];
    dbSession.delegate = self;
    [dbSession startLoading];
}

#pragma mark DBLoadSession Delegate;
-(void)session:(DBSession *)session downloadedModuleList:(NSArray *)moduleList moreComing:(BOOL)moreComing
{   
    datasource = moduleList;
    [tableData removeAllObjects];
    [tableData addObjectsFromArray:datasource];
}

-(void)session:(DBSession *)session listDownloadFailedWithError:(NSError *)error
{
    NSLog(@"Error: %@",[error localizedDescription]);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect mainFrame = self.view.bounds;
    sBar.frame = CGRectMake(0,0,mainFrame.size.width,30);
    myTableView.frame = CGRectMake(0, 31, mainFrame.size.width, mainFrame.size.height-30);
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString *name,*sortFieldLabel,*sortOrderValue;
    sortFieldLabel = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"key_%@_%@",moduleName,kSettingTitleForSortField]];
    sortOrderValue = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"key_%@_%@",moduleName,kSettingTitleForSortorder]];
    NSDictionary *lablenameDict = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_labelnameDict",moduleName]];
    
    if(sortFieldLabel != nil)
        name = [lablenameDict objectForKey:sortFieldLabel];
    else
        name = nil;
    
    
    self.tableData =(NSMutableArray *) [tableData sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *str1,*str2;
        if (name != nil) {
            str1 = [obj1 objectForFieldName:name];
            str2 = [obj2 objectForFieldName:name];
        }else{
            str1 = [obj1 objectForFieldName:metadata.primaryDisplayField.name];
            str2 = [obj2 objectForFieldName:metadata.primaryDisplayField.name];
        }
        if([sortOrderValue isEqualToString:@"Descending"])
            return[str1 compare:str2 options:NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSLiteralSearch];
        else
            return[str1 compare:str2 options:NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSLiteralSearch];
    }];
    [myTableView reloadData];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return [tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    id dataObjectForRow = [tableData objectAtIndex:indexPath.row];
  
    cell.textLabel.text = [dataObjectForRow objectForFieldName:metadata.primaryDisplayField.name];
    
    for(DataObjectField *otherField in metadata.otherFields)
    {
          if ([dataObjectForRow objectForFieldName:otherField.name]) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@",otherField.label,[dataObjectForRow objectForFieldName:otherField.name]];
        }
          else{
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: NA",otherField.label];}
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    // Navigation logic may go here. Create and push another view controller.
    id beanTitle = [[datasource objectAtIndex:indexPath.row] objectForFieldName:@"name"];
    id beanId =[[datasource objectAtIndex:indexPath.row]objectForFieldName:@"id"];
    NSLog(@"beanId %@, beantitle %@",beanId,beanTitle);
                
    DetailViewController *detailViewController = [DetailViewController detailViewcontroller:[[SugarCRMMetadataStore sharedInstance] detailViewMetadataForModule:metadata.moduleName] beanId:beanId beanTitle:beanTitle];
     [self.navigationController pushViewController:detailViewController animated:YES];
   }

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    // only show the status bar’s cancel button while in edit mode
    sBar.showsCancelButton = YES;
    sBar.autocorrectionType = UITextAutocorrectionTypeNo;
    // flush the previous search content
    //[tableData removeAllObjects];
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    sBar.showsCancelButton = NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [tableData removeAllObjects];// remove all data that belongs to previous search
    if(searchText==nil || [searchText isEqualToString:@""]){
        [tableData addObjectsFromArray:datasource];
        [myTableView reloadData];
        return;
    }
    for(int i=0; i < [datasource count]; i++)
    {
        id dataObjectRow = [datasource objectAtIndex:i];
        NSString* name = [dataObjectRow objectForFieldName:metadata.primaryDisplayField.name];
        NSRange r = [[name lowercaseString] rangeOfString:[searchText lowercaseString]];
        if(r.location != NSNotFound)
        {
            [tableData addObject:dataObjectRow];
        }
    }
    [myTableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    // if a valid search was entered but the user wanted to cancel, bring back the main list content
    [tableData removeAllObjects];
    [tableData addObjectsFromArray:datasource];
    @try{
        [myTableView reloadData];
    }
    @catch(NSException *e){
    }
    [sBar resignFirstResponder];
    sBar.text = @"";
}
// called when Search (in our case “Done”) button pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

@end
