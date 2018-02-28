//
//  ViewController.m
//  WWCollectionWaterfallLayout
//
//  Created by Tidus on 17/1/13.
//  Copyright © 2017年 Tidus. All rights reserved.
//

#import "CollectViewController.h"
#import "CollectionWaterfallLayout.h"
#import "WFHeaderView.h"

#define StatusBarHeight ([UIApplication sharedApplication].statusBarFrame.size.height)
#define NavigationBarHeight (self.navigationController.navigationBar.frame.size.height)
#define TabBarHeight (self.tabBarController.tabBar.frame.size.height)

#define ScreenWidth ([[UIScreen mainScreen] bounds].size.width)
#define ScreenHeight ([[UIScreen mainScreen] bounds].size.height)

static NSString *const kCollectionViewItemReusableID = @"kCollectionViewItemReusableID";
static NSString *const kCollectionViewHeaderReusableID = @"kCollectionViewHeaderReusableID";


@interface CollectViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, CollectionWaterfallLayoutProtocol>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) CollectionWaterfallLayout *waterfallLayout;
@property (nonatomic, strong) NSMutableArray<NSMutableArray *> *dataList;

@end

@implementation CollectViewController

- (void)loadView
{
    [super loadView];
    [self.view addSubview:self.collectionView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    [self setupDataList];
    [self setupRightButton];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 数据源
- (void)setupDataList
{   _dataList = [NSMutableArray array];
    {
        NSMutableArray *dataList = [NSMutableArray array];
        NSInteger dataCount = arc4random()%25+30;
        for(NSInteger i=0; i<dataCount; i++){
            NSInteger rowHeight = arc4random()%100+30;
            [dataList addObject:@(rowHeight)];
        }
        [_dataList addObject:dataList];
    }
    {
        NSMutableArray *dataList = [NSMutableArray array];
        NSInteger dataCount = arc4random()%25+50;
        for(NSInteger i=0; i<dataCount; i++){
            NSInteger rowHeight = arc4random()%100+30;
            [dataList addObject:@(rowHeight)];
        }
        [_dataList addObject:dataList];
    }
}

- (void)setupRightButton
{
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                       target:self action:@selector(buttonClick)];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, nil];
}

- (void)buttonClick
{
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"样式选择"
                                                        delegate:self
                                               cancelButtonTitle:@"取消"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"停靠瀑布流",
                             @"简单瀑布流",
                             @"停靠表格流",
                             @"停靠固定行高流",
                             nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"取消"]) {
        return;
    }
    
    if ([title isEqualToString:@"停靠瀑布流"]) {
        //
    } else if ([title isEqualToString:@"简单瀑布流"]) {
        //
    } else if ([title isEqualToString:@"停靠表格流"]) {
        //
    } else if ([title isEqualToString:@"固定行高表格流"]) {
        //
    }
    
    [self setupDataList];
    [self.collectionView reloadData];
}


#pragma mark - getter
- (UICollectionView *)collectionView
{
    if(!_collectionView){
        
        _waterfallLayout = [[CollectionWaterfallLayout alloc] init];
        _waterfallLayout.delegate = self;
        _waterfallLayout.columns = 2;
        _waterfallLayout.columnSpacing = 10;
        _waterfallLayout.insets = UIEdgeInsetsMake(10, 10, 10, 10);
        
//        MMCollectionViewLayout *layout = [[MMCollectionViewLayout alloc] init];
//        layout.config =
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight-StatusBarHeight-NavigationBarHeight) collectionViewLayout:_waterfallLayout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kCollectionViewItemReusableID];
        UINib *headerViewNib = [UINib nibWithNibName:@"WFHeaderView" bundle:nil];
        [_collectionView registerNib:headerViewNib forSupplementaryViewOfKind:kSupplementaryViewKindHeader withReuseIdentifier:kCollectionViewHeaderReusableID];
    }
    
    
    return _collectionView;
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _dataList.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _dataList[section].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionViewItemReusableID forIndexPath:indexPath];
    
    if(!cell){
        cell = [[UICollectionViewCell alloc] init];
    }
    
    CGFloat red = arc4random()%256/255.0;
    CGFloat green = arc4random()%256/255.0;
    CGFloat blue = arc4random()%256/255.0;
    
    cell.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1];
    
    NSLog(@"cell indexpath = (%ld,%ld)",indexPath.section,indexPath.row);
    return cell;
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"view indexpath = (%ld,%ld)",indexPath.section,indexPath.row);
    if([kind isEqualToString:kSupplementaryViewKindHeader]){
        UICollectionReusableView *headerView = (UICollectionReusableView *)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kCollectionViewHeaderReusableID forIndexPath:indexPath];
        
        CGFloat red = arc4random()%256/255.0;
        CGFloat green = arc4random()%256/255.0;
        CGFloat blue = arc4random()%256/255.0;
        
        headerView.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1];
        return headerView;
    }
    return nil;
}

#pragma mark - CollectionWaterfallLayoutProtocol
- (CGFloat)collectionViewLayout:(CollectionWaterfallLayout *)layout heightForItemAtIndexPath:(NSIndexPath *)indexPath
{
//    NSInteger row = indexPath.row;
    CGFloat cellHeight = [_dataList[indexPath.section][indexPath.row] floatValue];
    return cellHeight;
}

- (CGFloat)collectionViewLayout:(CollectionWaterfallLayout *)layout heightForSupplementaryViewAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0){
        return 44;
    } else if (indexPath.section == 1) {
        return 44;
    }
    return 0;
}
@end
