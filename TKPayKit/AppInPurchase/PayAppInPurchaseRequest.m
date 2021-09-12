//
//  PayAppInPurchaseRequest.m
//  TKPayKitDemo
//
//  Created by PC on 2021/9/12.
//

#import "PayAppInPurchaseRequest.h"

@implementation PayAppInPurchaseRequest
- (NSInteger)quantity
{
    if (_quantity < 1) {
        return 1;
    }
    return _quantity;
}
@end
