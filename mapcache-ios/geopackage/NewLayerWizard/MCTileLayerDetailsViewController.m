//
//  GPKGSTileLayerDetailsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCTileLayerDetailsViewController.h"
#import "mapcache_ios-Swift.h"

@interface MCTileLayerDetailsViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) MCButtonCell *buttonCell;
@property (nonatomic, strong) MCButtonCell *selectServerButtonCell;
@property (nonatomic, strong) MCButtonCell *helpButtonCell;
@property (nonatomic, strong) MCDescriptionCell *helpText;
@property (nonatomic, strong) MCFieldWithTitleCell *layerNameCell;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) BOOL urlIsValid;
@end

@implementation MCTileLayerDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] init];
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y + 32, bounds.size.width, bounds.size.height - 20);
    self.tableView = [[UITableView alloc] initWithFrame: insetBounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 390.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.urlIsValid = YES;
    
    self.tileServer = [[MCTileServer alloc] initWithServerName:@"GEOINT Services OSM"];
    self.tileServer.url = @"https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png";
    
    [self registerCellTypes];
    [self initCellArray];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    [self.view addSubview:self.tableView];
    [self addDragHandle];
    [self addCloseButton];
    self.selectedServerURL = nil;
    self.layerName = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *title = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    title.label.text = @"New tile layer";
    [_cellArray addObject:title];
    
    _layerNameCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _layerNameCell.title.text = @"Layer name";
    
    if (self.layerName != nil) {
        [_layerNameCell.field setText:self.layerName];
    }
    
    [_layerNameCell.field setReturnKeyType:UIReturnKeyDone]; // TODO look into UIReturnKeyNext
    _layerNameCell.field.delegate = self;
    [_cellArray addObject:_layerNameCell];
    
    _urlCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    [_urlCell setTitleText:@"Tile server URL"];

    [_urlCell setPlaceholder:self.tileServer.url];
    [_urlCell setFieldText:self.tileServer.url];
    
    [_urlCell setTextFielDelegate: self];
    [_urlCell useReturnKeyDone];
    [_cellArray addObject:_urlCell];
    
    self.helpText = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    self.helpText.descriptionLabel.text = @"Tip: EPSG:3857 tiles from XYZ and WMS servers are supported.";
    [_cellArray addObject:self.helpText];
    
    _selectServerButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_selectServerButtonCell.button setTitle:@"Choose Tile Server" forState:UIControlStateNormal];
    _selectServerButtonCell.action = @"ShowServers";
    _selectServerButtonCell.delegate = self;
    [_cellArray addObject:_selectServerButtonCell];
    [_selectServerButtonCell useSecondaryColors];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_buttonCell.button setTitle:@"Next" forState:UIControlStateNormal];
    [_buttonCell disableButton];
    _buttonCell.delegate = self;
    _buttonCell.action = @"ContinueToBoundingBox";
    [_cellArray addObject:_buttonCell];
    
    _helpButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_helpButtonCell.button setTitle:@"More about URL templates" forState:UIControlStateNormal];
    _helpButtonCell.action = @"ShowHelp";
    _helpButtonCell.delegate = self;
    [_cellArray addObject:_helpButtonCell];
    [_helpButtonCell useSecondaryColors];
}

- (void)update {
    [self initCellArray];
    [self.tableView reloadData];
    [self textFieldDidEndEditing:self.layerNameCell.field];
    [self textFieldDidEndEditing:self.urlCell.field];
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
}


#pragma mark - UITableViewDelegate methods
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


#pragma mark- UITextFieldDelegate methods
- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField trimWhiteSpace];
    
    if (textField == _urlCell.field) {
        NSLog(@"URL Field ended editing");
        
        if ([textField.text isEqualToString:@""]) {
            self.urlIsValid = NO;
            [self.helpText.descriptionLabel setText:@"URL can't be blank."];
            [self.urlCell useErrorAppearance];
            [self.buttonCell disableButton];
        } else {
            [textField isValidTileServerURL:textField withResult:^(MCTileServerResult *tileServerResult) {
                
                if (tileServerResult == nil) {
                    NSLog(@"Bad url");
                    self.urlIsValid = NO;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.helpText.descriptionLabel setText:@"Check your URL."];
                        [self.buttonCell disableButton];
                        [self.urlCell useErrorAppearance];
                    });
                    [textField resignFirstResponder];
                    return;
                }
                
                MCServerError *error = (MCServerError *)tileServerResult.failure;
                MCTileServerType serverType = ((MCTileServer *)tileServerResult.success).serverType;
                
                if (tileServerResult.failure != nil && error.code != MCNoError) {
                    self.urlIsValid = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSDictionary *userInfo = error.userInfo;
                        [self.helpText.descriptionLabel setText:userInfo[@"message"]];
                        [self.buttonCell disableButton];
                        [self.urlCell useErrorAppearance];
                    });
                } else if (serverType == MCTileServerTypeXyz || serverType == MCTileServerTypeWms) {
                    NSLog(@"Valid URL");
                    self.tileServer = (MCTileServer *)tileServerResult.success;
                    self.urlIsValid = YES;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.urlCell useNormalAppearance];
                        BOOL isLayerNameAvailable = [self.delegate isLayerNameAvailable: self.layerName];
                        
                        if (self.layerName != nil && ![self.layerName isEqualToString:@""] && isLayerNameAvailable) {
                            [self.buttonCell enableButton];
                        }
                    });
                } else {
                    // TODO add TMS support
                    NSLog(@"Bad url");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buttonCell disableButton];
                        [self.urlCell useErrorAppearance];
                    });
                }
            }];
        }
    } else {
        self.layerName = textField.text;
        BOOL isLayerNameAvailable = [self.delegate isLayerNameAvailable: self.layerName];
        
        if ([_layerNameCell.field.text isEqualToString:@""]) {
            [self.layerNameCell useErrorAppearance];
            [_buttonCell disableButton];
            [self.helpText.descriptionLabel setText:@"Please name your layer."];
        } else if (!isLayerNameAvailable) {
            [self.layerNameCell useErrorAppearance];
            [_buttonCell disableButton];
            [self.helpText.descriptionLabel setText:@"There is already a layer with that name."];
        } else {
            [self.layerNameCell useNormalAppearance];
            
            if (self.urlIsValid) {
                [_buttonCell enableButton];
            }
        }
    }
    
    [textField resignFirstResponder];
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - GPKGSButtonCellDelegate methods
- (void) performButtonAction:(NSString *)action {
    if ([action isEqualToString:@"ContinueToBoundingBox"]) {
        [_delegate tileLayerDetailsCompletionHandlerWithName:_layerNameCell.field.text tileServer: self.tileServer andReferenceSystemCode:PROJ_EPSG_WEB_MERCATOR];
    } else if ([action isEqualToString:@"ShowServers"]) {
        [self.delegate showTileServerList];
    } else {
        [_delegate showURLHelp];
    }
}

#pragma mark - NGADrawerView methods
- (void) closeDrawer {
    [self.drawerViewDelegate popDrawer];
}

- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    
    if (CGRectContainsPoint(_layerNameCell.frame, point) || CGRectContainsPoint(_urlCell.frame, point)) {
        return true;
    }
    
    return false;
}

@end
