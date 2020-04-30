//
//  GPKGSFieldWithTitleCellTableViewCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextField+Validators.h"

@interface MCFieldWithTitleCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UITextField *field;

/**
    When editing the contents of a feature row this can be used to know which column the value of the field will need to be saved to.
 */
@property (strong, nonatomic) NSString *columnName;

- (NSString *)fieldValue;
- (void) setTitleText:(NSString *) titleText;
- (void) setPlaceholder:(NSString *) placeholder;
- (void) setFieldText:(NSString *) text;
- (void)setTextFielDelegate: (id<UITextFieldDelegate>)delegate;
- (void) useReturnKeyDone;
- (void)setupNumericalKeyboard;
- (void) useNormalAppearance;
- (void) useErrorAppearance;
@end
