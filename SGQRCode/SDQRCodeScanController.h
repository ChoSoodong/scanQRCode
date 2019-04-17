







#import "SDBaseController.h"

@class SDQRCodeScanController;

@protocol SDQRCodeScanControllerDelegate<NSObject>

//字符串的扫描结果
-(void)QRCodeScanController:(SDQRCodeScanController *)scanVC stringResult:(NSString *)stringResult;
//网址字符串的扫描结果
-(void)QRCodeScanController:(SDQRCodeScanController *)scanVC httpResult:(NSString *)httpResult;

@end

@interface SDQRCodeScanController : SDBaseController

/** 代理属性 */
@property (nonatomic, weak) id<SDQRCodeScanControllerDelegate> delegate;

@end


