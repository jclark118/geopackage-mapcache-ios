//
//  MCTileServerURLManagerViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/22/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCTileServerURLManagerViewController.h"


@interface MCTileServerURLManagerViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MCButtonCell *buttonCell;
@property (nonatomic, strong) MCFieldWithTitleCell *urlCell;
@end

@implementation MCTileServerURLManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] init];
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
    [self registerCellTypes];
    [self initCellArray];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;

    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    [self.view addSubview:self.tableView];
    [self addDragHandle];
    [self addCloseButton];
    self.selectMode = NO;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initCellArray];
    [self.tableView reloadData];
}


- (void) initCellArray {
    self.cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *tileTitle = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    [tileTitle.label setText:@"Tile Server URLs"];
    [self.cellArray addObject:tileTitle];
     
    MCDescriptionCell *description = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    [description.descriptionLabel setText:@"Saved URLs for easy access when creating new tile layers."];
    [self.cellArray addObject:description];
    
    self.buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [self.buttonCell setButtonLabel:@"New Tile Server"];
    [self.buttonCell setAction:@"SAVE"];
    [self.buttonCell setDelegate:self];
    [self.cellArray addObject:self.buttonCell];
    
    MCLayerCell *testURL1 = [self.tableView dequeueReusableCellWithIdentifier:@"server"];
    [testURL1 setName:@"GEOINT Services OSM"];
    [testURL1 setDetails:@"https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png"];
    [testURL1 activeIndicatorOff];
    [testURL1.layerTypeImage setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:GPKGS_PROP_ICON_TILE_SERVER]]];
    [self.cellArray addObject:testURL1];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *serverUrls = [defaults dictionaryForKey:MC_SAVED_TILE_SERVER_URLS];
    
    if (serverUrls) {
        NSArray *serverNames = [serverUrls allKeys];
        for (NSString *serverName in serverNames) {
            MCLayerCell *tileServerCell = [self.tableView dequeueReusableCellWithIdentifier:@"server"];
            [tileServerCell setName: serverName];
            [tileServerCell setDetails: [serverUrls objectForKey:serverName]];
            [tileServerCell activeIndicatorOff];
            [tileServerCell.layerTypeImage setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:GPKGS_PROP_ICON_TILE_SERVER]]];
            [self.cellArray addObject:tileServerCell];
        }
    }
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCLayerCell" bundle:nil] forCellReuseIdentifier:@"server"];
}


- (void) update {
    [self initCellArray];
    [self.tableView reloadData];
}


#pragma mark - UITableViewDelegate methods
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    return [self.cellArray objectAtIndex:indexPath.row];
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.cellArray count];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.selectMode && [[_cellArray objectAtIndex:indexPath.row] isKindOfClass:[MCLayerCell class]]) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        [self.selectServerDelegate selectTileServer: cell.detailLabel.text];
        [self.drawerViewDelegate popDrawer];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[_cellArray objectAtIndex:indexPath.row] isKindOfClass:[MCLayerCell class]]) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        
        if ([cell.layerNameLabel.text isEqualToString:@"GEOINT Services OSM"]) {
            return NO;
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}


- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIContextualAction *editAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Edit" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        [self.tileServerManagerDelegate editTileServer:cell.layerNameLabel.text];
        completionHandler(YES);
    }];
    
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        [self.tileServerManagerDelegate deleteTileServer: cell.layerNameLabel.text];
        completionHandler(YES);
    }];
    
    editAction.backgroundColor = [UIColor purpleColor];
    deleteAction.backgroundColor = [UIColor redColor];
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[editAction, deleteAction]];
    configuration.performsFirstActionWithFullSwipe = YES;
    return configuration;
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - NGADrawerView methods
- (void) closeDrawer {
    [self.drawerViewDelegate popDrawer];
}


#pragma mark - GPKGSButtonCellDelegate methods
- (void) performButtonAction:(NSString *)action {
    [self.tileServerManagerDelegate showNewTileServerView];
}


@end