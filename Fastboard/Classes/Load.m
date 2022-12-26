//
//  Load.m
//  Fastboard
//
//  Created by xuyunshi on 2022/1/13.
//

#import <UIKit/UIKit.h>
#import <Fastboard/Fastboard-Swift.h>

void methodExchange(Class cls, SEL oSelect, SEL swizzledSelector) {
    Method o = class_getInstanceMethod(cls, oSelect);
    Method s = class_getInstanceMethod(cls, swizzledSelector);
    method_exchangeImplementations(o, s);
}

@interface FastLoad : NSObject
@end

@implementation FastLoad

+ (void)load {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    methodExchange([UIViewController class],
                   @selector(traitCollectionDidChange:),
                   @selector(_fastboard_exchangedTraitCollectionDidChange:));
    
    methodExchange([UIView class],
                   @selector(traitCollectionDidChange:),
                   @selector(_fastboard_exchangedTraitCollectionDidChange:));
    [FastLoad initTheme];
#pragma clang diagnostic pop
}


+ (void)initTheme {
    (void)[FastRoomThemeManager shared];
}

@end
