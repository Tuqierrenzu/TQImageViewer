//
//  TQViewController.m
//  TQImageViewer
//
//  Created by snail-z on 02/09/2018.
//  Copyright (c) 2018 snail-z. All rights reserved.
//

#import "TQPreViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "TQImageViewer.h"

@interface TQPreViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSString *imageUrlString;

@end

@implementation TQPreViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleToFill;
        [self.contentView addSubview:_imageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.bounds;
}

- (void)setImageUrlString:(NSString *)imageUrlString {
    if (!imageUrlString) return;
    _imageUrlString = imageUrlString;
    [_imageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString] placeholderImage:[UIImage imageNamed:@"tq_placeholderImage"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        if (!image) return ;
//        CGFloat scale = (image.size.height / image.size.width) / (_imageView.bounds.size.height / _imageView.bounds.size.width);
//        if (scale < 0.99 || isnan(scale)) {
//            _imageView.contentMode = UIViewContentModeScaleAspectFill;
//            _imageView.layer.contentsRect = CGRectMake(0, 0, 1, 1);
//        } else {
//            _imageView.contentMode = UIViewContentModeScaleAspectFill;
//            _imageView.layer.contentsRect = CGRectMake(0, 0, 1, (float)image.size.width / image.size.height);
//        }
    }];
}

@end


@interface TQPreViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, TQImageViewerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<NSString *> *photos;

@end

@implementation TQPreViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(10, 5, 10, 5);
   
    NSUInteger maxCount = 4;
    CGFloat spareTotal = layout.sectionInset.left + layout.sectionInset.right + layout.minimumInteritemSpacing * (maxCount - 1);
    CGFloat itemWidth = floor((self.view.bounds.size.width - spareTotal) / (double)maxCount);
    layout.itemSize = CGSizeMake(itemWidth, itemWidth);
    
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    [_collectionView registerClass:[TQPreViewCell class] forCellWithReuseIdentifier:@"cell"];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.backgroundView = [UIView new];
    _collectionView.userInteractionEnabled = YES;
    _collectionView.canCancelContentTouches = NO;
    _collectionView.multipleTouchEnabled = NO;
    [self.view addSubview:_collectionView];
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TQPreViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.imageUrlString = self.photos[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *photos = [NSMutableArray array];
    for (NSInteger i = 0; i < self.photos.count; i++) {
        TQPreViewCell *cell = (TQPreViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:indexPath.section]];
        NSString *url = self.photos[i];
        TQImageViewerAttribute *attri = [[TQImageViewerAttribute alloc] init];
        attri.pressView = self.presentFade ? nil : cell.imageView;
        attri.imageURL = [NSURL URLWithString:url];
        [photos addObject:attri];
    }
    TQImageViewer *viewer = [[TQImageViewer alloc] initWithPhotos:photos];
    viewer.loadingStyle = self.loadingType;
    viewer.pageLabelStyle = self.pageLabelType;
    viewer.alwaysShowPageLabel = self.alwaysShowPageLabel;
    viewer.bouncesAnimated = self.bouncesAnimated;
    viewer.delegate = self;
    [viewer presentInView:self.navigationController.view currentIndex:indexPath.row completion:NULL];
}

#pragma mark - TQImageViewerDelegate

- (void)imageViewer:(TQImageViewer *)imageViewer didLongPress:(UILongPressGestureRecognizer *)longPress attribute:(TQImageViewerAttribute *)attribute image:(UIImage *)image
{
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        activityViewController.popoverPresentationController.sourceView = longPress.view;
        CGPoint point = [longPress locationInView:longPress.view];
        activityViewController.popoverPresentationController.sourceRect = CGRectMake(point.x, point.y, 1, 1);
    }
    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - Photos

- (NSMutableArray<NSString *> *)photos
{
    if (!_photos) {
        _photos = [NSMutableArray array];
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/006tTrumly1fnksvaxdq9j30rs13d4qp.jpg"];
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/006tTrumly1fnksva712rj30rs13d4o9.jpg"];
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/006tTrumly1fnksvasi89j31jk0v37wh.jpg"];
        [_photos addObject:@"http://ww3.sinaimg.cn/bmiddle/006tTrumly1fnksvcvhv0j31jk15m7wh.jpg"];
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/006tTrumly1fnksvbakhgj31iw0s0b29.jpg"];
        [_photos addObject:@"http://ww3.sinaimg.cn/bmiddle/006tTrumly1fnksvawrfxj31io0jnb29.jpg"];
        [_photos addObject:@"http://ww2.sinaimg.cn/bmiddle/006tTrumly1fnksvbcnagj31jk102b29.jpg"];
        [_photos addObject:@"http://ww1.sinaimg.cn/bmiddle/006tTrumly1fnksvcrsy6j315o0xlhdt.jpg"];
        [_photos addObject:@"http://ww2.sinaimg.cn/bmiddle/006tTrumly1fnksvcok5sj31kw0v44qp.jpg"];
        
        [_photos addObject:@"http://ww1.sinaimg.cn/bmiddle/e476903fgy1foa3g8fx4mj20qo0qothw.jpg"];
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/e476903fgy1foa3g80pedj20qo0tcqem.jpg"];
      
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/b2b43c2fgy1fnku6iwajej20j60j6tba.jpg"];
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/b2b43c2fgy1fnku6jp6q5j20j60j6ad5.jpg"];
        [_photos addObject:@"http://ww3.sinaimg.cn/bmiddle/b2b43c2fgy1fnku6idx5aj20j60j6acp.jpg"];
        [_photos addObject:@"http://ww3.sinaimg.cn/bmiddle/b2b43c2fgy1fnku6ir6n7j20j60j6ad4.jpg"];
      
        [_photos addObject:@"http://ww2.sinaimg.cn/bmiddle/005Afflpgy1fo9evin1v7j30jg0ykmyd.jpg"];
        [_photos addObject:@"http://ww3.sinaimg.cn/bmiddle/005Afflpgy1fo9et742wcj30jg0yk3yt.jpg"];
        [_photos addObject:@"http://ww1.sinaimg.cn/bmiddle/005Afflpgy1fo9et7o7h3j30jg0ykmx8.jpg"];
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/005Afflpgy1fo9et87ylgj30jg0zuju8.jpg"];
        
        [_photos addObject:@"http://ww1.sinaimg.cn/bmiddle/662ef982gy1foa507c3b0j20ku112whi.jpg"];
        
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/af0d43ddgy1fmwibto6azj20c81hw7b5.jpg"];
        [_photos addObject:@"http://ww3.sinaimg.cn/bmiddle/af0d43ddgy1fmwibtrnjbj20c83cdwuz.jpg"];
        [_photos addObject:@"http://ww2.sinaimg.cn/bmiddle/af0d43ddgy1fmwibtj74lj20c815z43f.jpg"];
        
        [_photos addObject:@"http://ww3.sinaimg.cn/bmiddle/006JPEp0gy1fo4qjd192sj30qo1be49s.jpg"];
        [_photos addObject:@"http://ww2.sinaimg.cn/bmiddle/006JPEp0gy1fo4qjjitikj30qo1bedo7.jpg"];
        [_photos addObject:@"http://ww2.sinaimg.cn/bmiddle/006JPEp0gy1fo4qjacs5nj30qo1begur.jpg"];
        [_photos addObject:@"http://ww2.sinaimg.cn/bmiddle/006JPEp0gy1fo4qj6nlrvj30qo1be47r.jpg"];
        
        [_photos addObject:@"http://ww1.sinaimg.cn/bmiddle/0060GtF7gy1fo75h1kk70j30hs0pan29.jpg"];
        [_photos addObject:@"http://ww2.sinaimg.cn/bmiddle/0060GtF7gy1fo75h5vo6kj30qo1be13u.jpg"];
        [_photos addObject:@"http://ww1.sinaimg.cn/bmiddle/0060GtF7gy1fo75h53jdbj30qo1be47f.jpg"];
        [_photos addObject:@"http://ww2.sinaimg.cn/bmiddle/0060GtF7gy1fo75h2d89sj30go0x7dlv.jpg"];
        
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/006K2lduly1fo75cg50x2j30qo0qoac5.jpg"];
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/006K2lduly1fo75ch9i0fj30rl0qotb4.jpg"];
        [_photos addObject:@"http://ww4.sinaimg.cn/bmiddle/006K2lduly1fo75cep0dsj30qo0qotd9.jpg"];
        [_photos addObject:@"http://ww2.sinaimg.cn/bmiddle/006K2lduly1fo75cfbvumj30jg0jgwhn.jpg"];
    }
    return _photos;
}

@end
