//
//  GifImageInfo.h
//  SCGifExample
//
//  Created by lingminjun on 13-8-26.
//
//

#import <Foundation/Foundation.h>

#ifndef GifImagesScreeningFramesOptionType
#define GifImagesScreeningFramesOptionType
typedef enum FramesScreeningOptionType {//帧筛选方式
    FramesProportionSelect  = 0,//比例筛选
    FramesKeepHead          = 1,//截取前面
    FramesKeepTail          = 2,//截取后面
    FramesKeepCentre        = 3,//截取中间
} FramesScreeningOptionType;
#endif

@interface GifImageInfo : NSObject {//gif信息
    NSArray * images;
    NSTimeInterval duration;
}
@property (nonatomic,retain) NSArray * images;
@property (nonatomic) NSTimeInterval duration;
@end

@interface NSData (GifImageExpand)

- (BOOL)isGifImageDatas;

+ (GifImageInfo *)gifInfoWithGIFData:(NSData *)data;//非gif返回nil

+ (GifImageInfo *)gifInfoWithGIFData:(NSData *)data maxFramesCount:(NSInteger)maxCount screening:(FramesScreeningOptionType)type;//非gif返回nil,count = 0表示不过滤

@end
