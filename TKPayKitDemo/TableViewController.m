//
//  TableViewController.m
//  TKPayKitDemo
//
//  Created by PC on 2021/9/6.
//

#import "TableViewController.h"
#import "TKPayKit.h"

@interface TableViewController ()
@property (nonatomic, strong) NSArray *dataAry;
@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
}

- (NSArray *)dataAry
{
    if (!_dataAry) {
        _dataAry = @[@"微信支付",
                     @"支付宝支付",
                     @"App In Purchase",
                     @"Apple Pay"
        ];
    }
    return _dataAry;;
}

#pragma mark - Table view data source



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataAry.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.dataAry[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (row == 0) {
        [PayWeChat payRequestReq:@{} completion:^(BOOL success, NSString * _Nonnull msg) {
            NSLog(@"success:%d  msg:%@",success,msg);
        }];

        PayResp *pay = [[PayResp alloc] init];
        pay.returnKey = @"returnKyr";
        pay.errCode = 2;
        NSArray *keys = @[@"returnKey",@"errCode",@"errStr",@"type"];
        NSDictionary *dic = [pay dictionaryWithValuesForKeys:keys];
        NSLog(@"dic:%@",dic);
  

    }else if ( row == 1){
        NSString *orderString = @"pp_id=2015052600090779";
        [PayAliPay payRequestOrder:orderString fromScheme:@"pay"];
    }else if (row ==2){
        NSArray *pro = @[@"com.czchat.CZChat01",
                       @"com.czchat.CZChat02",
                       @"com.czchat.CZChat03"
        ];
        [PayAppInPurchase payPequestProducts:pro quantity:1 completion:^(BOOL success, NSString * _Nonnull msg) {

        }];
    }
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
