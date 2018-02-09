//
//  ExampleViewController.m
//  TQImageViewer_Example
//
//  Created by zhanghao on 2018/2/9.
//  Copyright © 2018年 snail-z. All rights reserved.
//

#import "TQEntryViewController.h"
#import "TQPreViewController.h"

@interface TQEntryViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *loadingSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *pageLabelSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *presentSegmentedControl;
@property (weak, nonatomic) IBOutlet UISwitch *pageLabelSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *bouncesSwitch;

@end

@implementation TQEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    TQPreViewController *preViewVC = [segue destinationViewController];
    preViewVC.loadingType = _loadingSegmentedControl.selectedSegmentIndex;
    preViewVC.pageLabelType = _pageLabelSegmentedControl.selectedSegmentIndex;
    preViewVC.presentFade = _presentSegmentedControl.selectedSegmentIndex;
    preViewVC.alwaysShowPageLabel = _pageLabelSwitch.isOn;
    preViewVC.bouncesAnimated = _bouncesSwitch.isOn;
}

- (IBAction)clearCaches:(UIBarButtonItem *)sender {
    NSLog(@"clearCaches");
}

@end
