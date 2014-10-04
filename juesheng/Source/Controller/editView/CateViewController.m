//
//  CateViewController.m
//  top100
//
//  Created by Dai Cloud on 12-7-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CateViewController.h"
#import "SubCateViewController.h"
#import "CateTableCell.h"
#import "AppDelegate.h"
#import "LoginViewController.h"
#import "EGOImageView.h"

@interface CateViewController ()

//@property (strong, nonatomic) SubCateViewController *subVc;
//@property (strong, nonatomic) NSDictionary *currentCate;


@end

@implementation CateViewController
static int LOGINTAG = -1;       //需要退回到登陆状态的TAG标志
static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch;
static int TAG_RIGHT_VIEW = 2;
static int TAG_MAIN_VIEW = 1;

@synthesize cates=_cates;
@synthesize subVc=_subVc;
//@synthesize currentCate=_currentCate;
//@synthesize tableView=_tableView;
@synthesize delegate=_delegate;
@synthesize rightView=_rightView;
@synthesize rightViewArray=_rightViewArray;
@synthesize mainViewArray=_mainViewArray;
@synthesize queryMainViewArray=_queryMainViewArray;
@synthesize subViewArray=_subViewArray;
@synthesize searchString=_searchString;

- (id)initWIthClassType:(NSInteger)classType itemClassTypeId:(NSInteger)itemClassTypeId selectFieldName:(NSString *)selectFieldName
{
    self = [self initWithNibName:@"CateViewController" bundle:nil];
    if (self) {
        _classType = classType;
        _itemClassTypeId = itemClassTypeId;
        [_selectFieldName release];
        _selectFieldName = [selectFieldName retain];
    }
    return self;
}

- (void)dealloc
{
    [_cates release];
    [_subVc release];
//    [_currentCate release];
    [_tableView release];
    [_delegate release];
    [_queryMainViewArray release];
    [_mainViewArray release];
    [_subViewArray release];
    [_rightViewArray release];
    [_rightView release];
    [_subVc release];
    [super dealloc];
}

-(NSArray *)cates
{
    if (_cates == nil){
        
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"Category" withExtension:@"plist"];
        _cates = [[NSArray arrayWithContentsOfURL:url] retain];
        
    }
    
    return _cates;
}

- (void)viewDidLoad
{
    //设置查询框及临时查询列表
    self.searchViewController = self;
    
    _searchController.pausesBeforeSearching = YES;
    _searchController.searchBar.placeholder = NSLocalizedString(@"输入关键字进行查询", @"");
//    self.searchDisplayController.searchBar.showsSearchResultsButton = YES;
    
    _searchController.searchResultsTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth  | UIViewAutoresizingFlexibleHeight;
    _searchController.searchResultsTableView.delegate = self;
    self.tableView.tableHeaderView = _searchController.searchBar;
    
    //设置代理
    _searchController.searchBar.delegate = self;
    _searchController.delegate = self;
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    _tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tmall_bg_furley.png"]];
    self.navigationItem.title = @"车型选择";
    _tableView.tag = TAG_MAIN_VIEW;
    
    _rightView = [[UITableView alloc]initWithFrame:CGRectMake(100, 0,210,460) style:UITableViewStyleGrouped];
    _rightView.backgroundView.alpha = 0;
    _rightView.backgroundColor = [UIColor grayColor];
    _rightView.tag = TAG_RIGHT_VIEW;
    _rightView.delegate = self;
    _rightView.dataSource = self;
    if ([Three20 systemMajorVersion] >= 7) {
        _rightView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    else{
        _rightView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    _rightView.hidden = true;
    
//    UIControl *_back = [[UIControl alloc] initWithFrame:_rightView.frame];
//    [(UIControl *)_back addTarget:self action:@selector(backgroundTap) forControlEvents:UIControlEventTouchDown];
//    [_rightView addSubview:_back];
//    [_back release];
    
    [self.view addSubview:_rightView];
    
    [self.view bringSubviewToFront:_tableView];
    
    [self sendRequestDataList];
}

/**
 * 初始化search bar时将取消按钮的标题更改为中文
 */
- (void)searchBarTextDidBeginEditing:(UISearchBar *)_searchBar
{
    _searchBar.showsCancelButton = YES;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        NSArray *searchBarSubViews = [[_searchBar.subviews objectAtIndex:0] subviews];
        for (UIView *searchbuttons in searchBarSubViews){
            if ([searchbuttons isKindOfClass:[UIButton class]]){
                UIButton *cancelButton = (UIButton*)searchbuttons;
                cancelButton.enabled = YES;
                [cancelButton setTitle:@"确定"  forState:UIControlStateNormal];//文字
                [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
                break;
            }
        }
    }
    else{
        for (id cc in [_searchBar subviews]) {
            if ([cc isKindOfClass:[UIButton class]]) {
                UIButton *button = (UIButton *)cc;
                [button setTitle:@"确定" forState:UIControlStateNormal];
                break;
            }
        }
    }
    _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
}

-(void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
{
    if (_searchString && _searchString.length > 0) {
        _searchController.searchBar.text = _searchString;
    }
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods
/**
 * 发生更换检索字符串时执行的方法
 */
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    // Return YES to cause the search result table view to be reloaded.
    if (_searchString && [_searchString isEqualToString:searchString]) {
        return YES;
    }
    _searchString = [[NSMutableString stringWithFormat:@"%@",searchString] copy];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"idName CONTAINS[c] %@", searchString];
    _queryMainViewArray = [[_mainViewArray filteredArrayUsingPredicate:pred] mutableCopy];
    [_tableView reloadData];
    self.searchDisplayController.searchResultsDataSource = _tableView.dataSource;
    [self.searchDisplayController.searchResultsTableView reloadData];
    return YES;
}

- (void)backgroundTap
{
    if (!_rightView.hidden) {
        [_rightView setHidden:!_rightView.hidden];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)backAction
{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView.tag == TAG_MAIN_VIEW) {
        return _queryMainViewArray.count;
    }
    else if(tableView.tag == TAG_RIGHT_VIEW) {
        return _rightViewArray.count;
    }
    else {
        return _queryMainViewArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"cate_cell";
    
//    NSDictionary *cate = [self.cates objectAtIndex:indexPath.row];
//    cell.logo.image = [UIImage imageNamed:[[cate objectForKey:@"imageName"] stringByAppendingString:@".png"]];
//    cell.title.text = [cate objectForKey:@"name"];
    NameValue *nameValue = nil;
    if (tableView.tag == TAG_MAIN_VIEW) {
        
        CateTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[[CateTableCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                         reuseIdentifier:CellIdentifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
        nameValue = [_queryMainViewArray objectAtIndex:indexPath.row];
        if (nameValue.idImageUrl) {
            //[cell.logo performSelectorOnMainThread:@selector(setImageURL:) withObject:[NSURL URLWithString: nameValue.idImageUrl] waitUntilDone:NO];
            cell.logo.imageURL = [NSURL URLWithString: nameValue.idImageUrl];
            //cell.logo.imageURL = [NSURL URLWithString:@"http://d.hiphotos.baidu.com/image/w%3D2048/sign=c3e0b36e2ff5e0feee188e01685835a8/c8177f3e6709c93d4330b2809d3df8dcd0005482.jpg"];
        }
        else{
            [cell.logo setImage:[UIImage imageNamed:@"logo.png"]];
        }
        cell.title.text = nameValue.idName;
        return cell;
    }
    else if(tableView.tag == TAG_RIGHT_VIEW){
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:CellIdentifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
        nameValue = [_rightViewArray objectAtIndex:indexPath.row];
        cell.textLabel.text = nameValue.idName;
        return cell;
    }
    else{   //搜索结果
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                         reuseIdentifier:CellIdentifier] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
        }
        nameValue = [_queryMainViewArray objectAtIndex:indexPath.row];
        cell.textLabel.text = nameValue.idName;
        return cell;
    }
    return  [tableView cellForRowAtIndexPath:indexPath];
    
//    NSMutableArray *subTitles = [[NSMutableArray alloc] init];
//    NSArray *subClass = [cate objectForKey:@"subClass"];
//    for (int i=0; i < MIN(4,  subClass.count); i++) {
//        [subTitles addObject:[[subClass objectAtIndex:i] objectForKey:@"name"]];
//    }
//    cell.subTtile.text = [subTitles componentsJoinedByString:@"/"];
//    [subTitles release];
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tableView.frame.origin.x == -220) {
        _tableView.transform = CGAffineTransformMakeTranslation(0, 0);
        [_rightView setHidden:true];
        //[self.view bringSubviewToFront:_tableView];
    }
    if (!_rightView.hidden) {
        [_rightView setHidden:!_rightView.hidden];
    }
    if (tableView.tag == TAG_MAIN_VIEW) {
        NameValue *nameValue = [_queryMainViewArray objectAtIndex:indexPath.row];
        
        [_subVc release];
        _subVc = [[SubCateViewController alloc]
                                         initWithNibName:NSStringFromClass([SubCateViewController class])
                                         bundle:nil];
        _subVc.cateVC = self;
        
        self.tableView.scrollEnabled = NO;
        UIFolderTableView *folderTableView = (UIFolderTableView *)tableView;
        [folderTableView openFolderAtIndexPath:indexPath WithContentView:_subVc.view
                                     openBlock:^(UIView *subClassView, CFTimeInterval duration, CAMediaTimingFunction *timingFunction){
                                         // opening actions
                                     }
                                    closeBlock:^(UIView *subClassView, CFTimeInterval duration, CAMediaTimingFunction *timingFunction){
                                        // closing actions
                                    }
                               completionBlock:^{
                                   // completed actions
                                   self.tableView.scrollEnabled = YES;
                                   if (_tableView.frame.origin.x == -220) {
                                       _tableView.transform = CGAffineTransformMakeTranslation(0, 0);
                                       [_rightView setHidden:true];
                                       //[self.view bringSubviewToFront:_tableView];
                                   }
                                   if (!_rightView.hidden) {
                                       [_rightView setHidden:!_rightView.hidden];
                                   }
                               }];
        
        [self sendRequestDataListSub1:nameValue.idValue];
    }
    else if(tableView.tag == TAG_RIGHT_VIEW){
        NameValue *nameValue = [_rightViewArray objectAtIndex:indexPath.row];
        [_delegate setSelectValue:nameValue];
        [_tableView reloadData];
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

-(CGFloat)tableView:(UIFolderTableView *)tableView xForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}

-(void)subCateBtnAction:(UIButton *)btn
{
    _rightView.frame = CGRectMake(100, self.view.bounds.origin.y,210,460);
    NameValue *nameValue = [_subVc.subCates objectAtIndex:btn.tag];
    [self sendRequestDataListSub2:nameValue.idValue];
    //_tableView.transform = CGAffineTransformMakeTranslation(-220, 0);
    [_rightView setHidden:false];
    [self.view bringSubviewToFront:_rightView];
//    NSDictionary *subCate = [[self.currentCate objectForKey:@"subClass"] objectAtIndex:btn.tag];
//    NSString *name = [subCate objectForKey:@"name"];
//    UIAlertView *Notpermitted=[[UIAlertView alloc] initWithTitle:@"子类信息"
//                                                         message:[NSString stringWithFormat:@"名称:%@, ID: %@", name, [subCate objectForKey:@"classID"]]
//                                                        delegate:nil
//                                               cancelButtonTitle:@"确认"
//                                               otherButtonTitles:nil];
//    [Notpermitted show];
//    [Notpermitted release];
}

-(void)sendRequestDataList
{
    AppDelegate *delegate=(AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *server_base = [NSString stringWithFormat:@"%@/classType!getItemClass.action", delegate.SERVER_HOST];
    TTURLRequest* request = [TTURLRequest requestWithURL: server_base delegate: self];
    [request setHttpMethod:@"POST"];
    request.contentType=@"application/x-www-form-urlencoded";
    
    NSString* postBodyString = [NSString stringWithFormat:@"isMobile=true&fItemClassId=%i&selectFieldName=%@&classType=%i&jsonTableData={}",_itemClassTypeId,_selectFieldName,_classType];
    postBodyString = [postBodyString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    request.cachePolicy = TTURLRequestCachePolicyNoCache;
    NSData* postData = [NSData dataWithBytes:[postBodyString UTF8String] length:[postBodyString length]];
    
    [request setHttpBody:postData];
    [request send];
    request.userInfo = @"itemClass";
    request.response = [[[TTURLDataResponse alloc] init] autorelease];
    
}

-(void)sendRequestDataListSub1:(NSString *)selectItem
{
    AppDelegate *delegate=(AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *server_base = [NSString stringWithFormat:@"%@/classType!getItemClass.action", delegate.SERVER_HOST];
    TTURLRequest* request = [TTURLRequest requestWithURL: server_base delegate: self];
    [request setHttpMethod:@"POST"];
    request.contentType=@"application/x-www-form-urlencoded";
    
    NSString* postBodyString = [NSString stringWithFormat:@"isMobile=true&fItemClassId=%i&selectFieldName=%@&classType=%i&jsonTableData={isEdit:'0',FBrand:'%@'}",10379,@"FCarClass",_classType,selectItem];
    postBodyString = [postBodyString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    request.cachePolicy = TTURLRequestCachePolicyNoCache;
    NSData* postData = [NSData dataWithBytes:[postBodyString UTF8String] length:[postBodyString length]];
    
    [request setHttpBody:postData];
    [request send];
    request.userInfo = @"itemClass1";
    request.response = [[[TTURLDataResponse alloc] init] autorelease];
    
}

-(void)sendRequestDataListSub2:(NSString *)selectItem
{
    AppDelegate *delegate=(AppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString *server_base = [NSString stringWithFormat:@"%@/classType!getItemClass.action", delegate.SERVER_HOST];
    TTURLRequest* request = [TTURLRequest requestWithURL: server_base delegate: self];
    [request setHttpMethod:@"POST"];
    request.contentType=@"application/x-www-form-urlencoded";
    
    NSString* postBodyString = [NSString stringWithFormat:@"isMobile=true&fItemClassId=%i&selectFieldName=%@&classType=%i&jsonTableData={isEdit:'0',FCarClass:'%@'}",10380,@"FModel",_classType,selectItem];
    postBodyString = [postBodyString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    request.cachePolicy = TTURLRequestCachePolicyNoCache;
    NSData* postData = [NSData dataWithBytes:[postBodyString UTF8String] length:[postBodyString length]];
    
    [request setHttpBody:postData];
    [request send];
    request.userInfo = @"itemClass2";
    request.response = [[[TTURLDataResponse alloc] init] autorelease];
    
}

- (void)requestDidStartLoad:(TTURLRequest*)request {
    //加入请求开始的一些进度条
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)requestDidFinishLoad:(TTURLRequest*)request {
    TTURLDataResponse* dataResponse = (TTURLDataResponse*)request.response;
    NSError *error;
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:dataResponse.data options:kNilOptions error:&error];
	request.response = nil;
    bool loginfailure = [[jsonDic objectForKey:@"loginfailure"] boolValue];
    if (loginfailure) {
        //创建对话框 提示用户重新输入
        UIAlertView * alert= [[UIAlertView alloc] initWithTitle:[jsonDic objectForKey:@"msg"] message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        alert.tag = LOGINTAG;   //通过该标志让用户返回登陆界面
        alert.delegate = self;
        [alert show];
        [alert release];
        return;
    }
    bool success = [[jsonDic objectForKey:@"success"] boolValue];
    if (!success) {
        //创建对话框 提示用户获取请求数据失败
        UIAlertView * alert= [[UIAlertView alloc] initWithTitle:[jsonDic objectForKey:@"msg"] message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
    else{
        //static NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch;
        if (request.userInfo != nil && [request.userInfo compare:@"itemClass" options:comparisonOptions] == NSOrderedSame) {
            _mainViewArray = [[NameValue alloc] initNameValueWithDictionay:[jsonDic objectForKey:@"itemClassList"]];
            _queryMainViewArray = [_mainViewArray copy];
            [_tableView reloadData];
            //[self invalidateModel];
            
        }
        else if (request.userInfo != nil && [request.userInfo compare:@"itemClass1" options:comparisonOptions] == NSOrderedSame) {
            //_subViewArray = [[NameValue alloc] initNameValueWithDictionay:[jsonDic objectForKey:@"itemClassList"]];
            _subVc.subCates = [[[NameValue alloc] initNameValueWithDictionay:[jsonDic objectForKey:@"itemClassList"]] autorelease];
            [_subVc reloadCateData];
        }
        else if (request.userInfo != nil && [request.userInfo compare:@"itemClass2" options:comparisonOptions] == NSOrderedSame) {
            [_rightViewArray release];
            _rightViewArray = nil;
            _rightViewArray = [[NameValue alloc] initNameValueWithDictionay:[jsonDic objectForKey:@"itemClassList"]];
            [_rightView reloadData];
        }
    }
}

-(void)alertView:(UIAlertView *)theAlert clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(theAlert.tag == LOGINTAG){
        LoginViewController *loginViewComtroller = [[LoginViewController alloc] initWithNavigatorURL:nil query:nil];
        [self.navigationController pushViewController:loginViewComtroller animated:YES];
        [loginViewComtroller release];
    }
}
@end
