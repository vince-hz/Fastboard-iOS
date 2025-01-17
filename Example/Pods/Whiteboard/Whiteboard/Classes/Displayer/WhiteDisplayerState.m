//
//  WhiteDisplayerState.m
//  WhiteSDK
//
//  Created by yleaf on 2019/7/22.
//

#import "WhiteDisplayerState.h"

WhiteWindowBoxState const WhiteWindowBoxStateNormal = @"normal";
WhiteWindowBoxState const WhiteWindowBoxStateMini = @"minimized";
WhiteWindowBoxState const WhiteWindowBoxStateMax = @"maximized";

@interface WhiteDisplayerState ()

@property (nonatomic, strong, readwrite) WhiteGlobalState *globalState;
@property (nonatomic, strong, readwrite) WhiteSceneState *sceneState;
@property (nonatomic, strong, readwrite) NSArray<WhiteRoomMember *> *roomMembers;
@property (nonatomic, strong, readwrite) WhiteCameraState *cameraState;
@property (nonatomic, copy, nullable, readwrite) WhiteWindowBoxState windowBoxState;

@end

@implementation WhiteDisplayerState

static Class CustomGlobalClass;
+ (BOOL)setCustomGlobalStateClass:(Class)clazz
{
    if ([clazz isSubclassOfClass:[WhiteGlobalState class]]) {
        CustomGlobalClass = clazz;
        return YES;
    } else {
        CustomGlobalClass = nil;
        return NO;
    }
}

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"roomMembers": [WhiteRoomMember class]};
}

- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic;
{
    if (CustomGlobalClass) {
        _globalState = [CustomGlobalClass modelWithJSON:dic[@"globalState"]];
    }
    return YES;
}

@end
