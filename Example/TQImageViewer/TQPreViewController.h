//
//  TQViewController.h
//  TQImageViewer
//
//  Created by TQTeam on 02/09/2018.
//  Copyright (c) 2018 TQTeam. All rights reserved.
//

@import UIKit;

@interface TQPreViewController : UIViewController

@property (nonatomic, assign) NSInteger loadingType;
@property (nonatomic, assign) NSInteger pageLabelType;
@property (nonatomic, assign) BOOL presentFade;
@property (nonatomic, assign) BOOL alwaysShowPageLabel;
@property (nonatomic, assign) BOOL bouncesAnimated;

@end
