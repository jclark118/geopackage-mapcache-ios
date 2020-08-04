//
//  MCLayerViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/3/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NGADrawerViewController.h"
#import "GPKGUserDao.h"
#import "GPKGFeatureDao.h"
#import "GPKGTileDao.h"
#import "MCFeatureTable.h"
#import "MCTileTable.h"
#import "MCButtonCell.h"
#import "MCSectionTitleCell.h"
#import "MCHeaderCell.h"
#import "MCLayerCell.h"
#import "MCUtils.h"
#import "MCProperties.h"
#import <SFPProjectionTransform.h>
#import "MCFeatureLayerOperationsCell.h"
#import "MCTileLayerOperationsCell.h"
#import "MCDescriptionCell.h"
#import "MCTitleCell.h"
#import "SFPProjectionConstants.h"
#import "GPKGOverlayFactory.h"
#import "MCTable.h"
#import "MCTileTable.h"
#import "MCFeatureTable.h"


@protocol MCLayerOperationsDelegate <NSObject>
- (void) deleteLayer;
- (void) createOverlay;
- (void) indexLayer;
- (void) createTiles;
- (BOOL) renameLayer:(NSString *) newLayerName;
- (void) showTileScalingOptions;
- (void) showFieldCreationView;
- (void) layerViewDidClose;
- (void) setSelectedLayerName;
- (void) renameColumn:(GPKGUserColumn *)column name:(NSString *)name;
- (void) deleteColumn:(GPKGUserColumn *)column;
- (void) layerViewCompletionHandler;
@end


@interface MCLayerViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, MCFeatureLayerOperationsCellDelegate, MCTileLayerOperationsCellDelegate, MCButtonCellDelegate>
- (void) update;
@property (strong, nonatomic) GPKGUserDao *layerDao;
@property (strong, nonatomic) MCTable* table;
@property (strong, nonatomic) NSArray *columns;
@property (weak, nonatomic) id<MCLayerOperationsDelegate> delegate;
@end
