//
//  MCDualButtonCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/21/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCDualButtonCell.h"

@implementation MCDualButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (IBAction)leftButtonPressed:(id)sender {
    [_dualButtonDelegate performDualButtonAction:self.leftButtonAction];
}


- (IBAction)rightButtonPressed:(id)sender {
    [_dualButtonDelegate performDualButtonAction:self.rightButtonAction];
}


- (void)setLeftButtonLabel: (NSString *) text {
    [_leftButton setTitle:text forState:UIControlStateNormal];
}


- (void)setRightButtonLabel: (NSString *) text {
    [_rightButton setTitle:text forState:UIControlStateNormal];
}


- (void)enableLeftButton {
    [_leftButton setEnabled: YES];
}


- (void)enableRightButton {
    [_rightButton setEnabled: YES];
}


- (void)disableLeftButton {
    [_leftButton setEnabled: NO];
}


- (void)disableRightButton {
    [_rightButton setEnabled: NO];
}


- (void)disableButtons {
    [_leftButton setEnabled: NO];
    [_rightButton setEnabled: NO];
}


- (void)enableButtons {
    [_leftButton setEnabled: YES];
    [_rightButton setEnabled: YES];
}


@end
