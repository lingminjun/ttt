//
//  GifImageInfo.m
//  SCGifExample
//
//  Created by lingminjun on 13-8-26.
//
//

#import "GifImageInfo.h"
#import <UIKit/UIKit.h>

typedef struct GIF_Color {
    int GIF_sorted;
    int GIF_colorS;
    int GIF_colorC;
    int GIF_colorF;
} GifColor;

@interface AnimatedGifFrame : NSObject
{
	NSData *data;
	NSData *header;
	double delay;
	int disposalMethod;
	CGRect area;
}

@property (nonatomic, copy) NSData *header;
@property (nonatomic, copy) NSData *data;
@property (nonatomic) double delay;
@property (nonatomic) int disposalMethod;
@property (nonatomic) CGRect area;

@end

@interface GIFImageBytes : NSObject {//用于操作bytes,采用data对象操作，意味着需要开辟很多的内存
    NSData * datas;
    unsigned long point;//游标值
}
@property (nonatomic,retain) NSData * datas;
@property (nonatomic) unsigned long point;
- (BOOL)skipBytes:(int)length;
- (BOOL)getBytes:(unsigned char *)buffer skipBytes:(int)length;
- (NSData *)subDataWithSkipBytes:(int)length;
- (NSArray *)gifFramesReadDataExtensions;
- (void)readDataDescriptorInFrame:(AnimatedGifFrame *)frame gifColor:(GifColor *)gifColor screen:(NSData **)screen global:(NSData *)global;
@end


@implementation AnimatedGifFrame

@synthesize data, delay, disposalMethod, area, header;

@end


@implementation GifImageInfo
@synthesize images;
@synthesize duration;

@end

@implementation NSData (GifImageExpand)

- (BOOL)isGifImageDatas {
    const char* buf = (const char*)[self bytes];
	if (buf[0] == 0x47 && buf[1] == 0x49 && buf[2] == 0x46 && buf[3] == 0x38) {
		return YES;
	}
	return NO;
}

+ (NSArray *)filterArray:(NSArray *)targetAry maxCount:(NSInteger)maxCount screening:(FramesScreeningOptionType)type {
    if (maxCount == 0) {
        return targetAry;
    }
    
    NSInteger count = [targetAry count];
    
    if (maxCount >= count) {
        return targetAry;
    }
    
    NSMutableArray * temAry = [NSMutableArray arrayWithCapacity:maxCount];
    switch (type) {
        case FramesProportionSelect: {
            NSInteger space = [targetAry count]/maxCount;
            for (NSInteger i = 0; i < [targetAry count]; i = i + space) {
                [temAry addObject:[targetAry objectAtIndex:i]];
            }
            if ([temAry count] < maxCount) {//还没到三十个时，取最后一个
                [temAry addObject:[targetAry lastObject]];
            }
        }
            break;
        case FramesKeepHead:{
            [temAry addObjectsFromArray:[targetAry subarrayWithRange:NSMakeRange(0, maxCount)]];
        }
            break;
        case FramesKeepTail:{
            [temAry addObjectsFromArray:[targetAry subarrayWithRange:NSMakeRange(count - maxCount, maxCount)]];
        }
            break;
        case FramesKeepCentre:{
            [temAry addObjectsFromArray:[targetAry subarrayWithRange:NSMakeRange((count - maxCount)/2, maxCount)]];
        }
            break;
        default:
            break;
    }
    return temAry;
}

+ (GifImageInfo *)gifImageInfoWithGifFrame:(NSArray *)GIF_frames maxFramesCount:(NSInteger)maxCount screening:(FramesScreeningOptionType)type {
    
    GifImageInfo * gifInfo = [[GifImageInfo alloc] init];
    
	// Add all subframes to the animation
	NSMutableArray *array = [[NSMutableArray alloc] init];
	for (NSUInteger i = 0; i < [GIF_frames count]; i++) {
        NSData *frameData = ((AnimatedGifFrame *)[GIF_frames objectAtIndex:i]).data;
        if (frameData) {
            UIImage *image = [UIImage imageWithData:frameData];
            if (image) {
                [array addObject:image];
            }
        }
	}
    
    if ([array count] == 0) {
        return nil;
    }
	
	NSMutableArray *overlayArray = [[NSMutableArray alloc] init];
	UIImage *firstImage = [array objectAtIndex:0];
	CGSize size = firstImage.size;
	CGRect rect = CGRectZero;
	rect.size = size;
	
	UIGraphicsBeginImageContext(size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	int i = 0;
	AnimatedGifFrame *lastFrame = nil;
    CGRect firstArea = [(AnimatedGifFrame *)[GIF_frames objectAtIndex:0] area];//主要用兼容一些较老版本的gif，如果发现绘制尺寸比第一张图片小时，所以明需要采用上一张背景（不能光看disposalMethod）
	for (UIImage *image in array)
	{
		// Get Frame
		AnimatedGifFrame *frame = [GIF_frames objectAtIndex:i];
		
		// Initialize Flag
		UIImage *previousCanvas = nil;
		
		// Save Context
		CGContextSaveGState(ctx);
		// Change CTM
		CGContextScaleCTM(ctx, 1.0, -1.0);
		CGContextTranslateCTM(ctx, 0.0, -size.height);
		
		// Check if lastFrame exists
        int backgroundDisposalMethod = frame.disposalMethod;
        if (CGRectContainsRect(firstArea,frame.area)) {
            if (!CGRectEqualToRect(firstArea,frame.area)) {
                backgroundDisposalMethod = 2;
                //printf("\nchange disposalMethod %d\n",frame.disposalMethod);
            }
        }
        
        if (i == 0) {//表示第一个，第一个图片将disposalMethod 处理成2是最合理的
            backgroundDisposalMethod = 2;
        }
        
		CGRect clipRect;
		
		// Disposal Method (Operations before draw frame)
        //printf("\ndisposalMethod %d\n",frame.disposalMethod);
        //backgroundDisposalMethod = frame.disposalMethod;
		switch (backgroundDisposalMethod)
		{
			case 1: // Do not dispose (draw over context)
                // Create Rect (y inverted) to clipping
				clipRect = CGRectMake(frame.area.origin.x, size.height - frame.area.size.height - frame.area.origin.y, frame.area.size.width, frame.area.size.height);
				// Clip Context
				CGContextClipToRect(ctx, clipRect);
				break;
			case 2: // Restore to background the rect when the actual frame will go to be drawed
                // Create Rect (y inverted) to clipping
				clipRect = CGRectMake(frame.area.origin.x, size.height - frame.area.size.height - frame.area.origin.y, frame.area.size.width, frame.area.size.height);
				// Clip Context
				CGContextClipToRect(ctx, clipRect);
				break;
			case 3: // Restore to Previous
                // Get Canvas
				previousCanvas = UIGraphicsGetImageFromCurrentImageContext();
				
				// Create Rect (y inverted) to clipping
				clipRect = CGRectMake(frame.area.origin.x, size.height - frame.area.size.height - frame.area.origin.y, frame.area.size.width, frame.area.size.height);
				// Clip Context
				CGContextClipToRect(ctx, clipRect);
				break;
		}
		
		// Draw Actual Frame
		CGContextDrawImage(ctx, rect, image.CGImage);
		// Restore State
		CGContextRestoreGState(ctx);
		
		//delay must larger than 0, the minimum delay in firefox is 10.
        //一般的处理，并不是采取火狐处理方式，主要是为了兼容老版本gif
//        if (frame.delay < 5) {
//            frame.delay = 10 + frame.delay;
//        }
        if (frame.delay < 1) {
            frame.delay = 1;
        }
        //		if (frame.delay <= 0) {
        //			frame.delay = 10;
        //		}
		[overlayArray addObject:UIGraphicsGetImageFromCurrentImageContext()];
		
		// Set Last Frame
		lastFrame = frame;
		
		// Disposal Method (Operations afte draw frame)
		switch (frame.disposalMethod)
		{
			case 2: // Restore to background color the zone of the actual frame
                // Save Context
				CGContextSaveGState(ctx);
				// Change CTM
				CGContextScaleCTM(ctx, 1.0, -1.0);
				CGContextTranslateCTM(ctx, 0.0, -size.height);
				// Clear Context
				CGContextClearRect(ctx, clipRect);
				// Restore Context
				CGContextRestoreGState(ctx);
				break;
			case 3: // Restore to Previous Canvas
                // Save Context
				CGContextSaveGState(ctx);
				// Change CTM
				CGContextScaleCTM(ctx, 1.0, -1.0);
				CGContextTranslateCTM(ctx, 0.0, -size.height);
				// Clear Context
				CGContextClearRect(ctx, lastFrame.area);
				// Draw previous frame
				CGContextDrawImage(ctx, rect, previousCanvas.CGImage);
				// Restore State
				CGContextRestoreGState(ctx);
				break;
		}
		
		// Increment counter
		i++;
	}
	UIGraphicsEndImageContext();
	
	//[self setImage:[overlayArray objectAtIndex:0]];
    NSArray * filterAry = [self filterArray:overlayArray maxCount:maxCount screening:type];
    if ([filterAry count]) {
        gifInfo.images = [NSArray arrayWithArray:filterAry];
    }
	//[self setAnimationImages:overlayArray];
	
    //gifInfo.images = [NSArray arrayWithArray:array];
	
	// Count up the total delay, since Cocoa doesn't do per frame delays.
	double total = 0;
    NSArray * filterFrames = [self filterArray:GIF_frames maxCount:maxCount screening:type];
	for (AnimatedGifFrame *frame in filterFrames) {
		total += frame.delay;
	}
	
	// GIFs store the delays as 1/100th of a second,
	// UIImageViews want it in seconds.
    gifInfo.duration = total/100;
    
    return gifInfo;
}

+ (NSArray *)gifFramesDecodeGIFData:(NSData *)data {
    
    GIFImageBytes * gifData = [[GIFImageBytes alloc] init];
    gifData.datas = data;
    gifData.point = 0;
    
    NSMutableArray *gifFrames = [NSMutableArray arrayWithCapacity:0];
    GifColor gifColor = {0};
	NSData *globalData = nil;//记录尺寸信息
	
	//[gifData skipBytes:6];//[self GIFSkipBytes: 6]; // GIF89a, throw away
    unsigned char fileHead[6] = {0};
    [gifData getBytes:fileHead skipBytes:6];
    
	NSData * gifScreen = [gifData subDataWithSkipBytes:7];//[self GIFGetBytes: 7]; // Logical Screen Descriptor
	
    // Copy the read bytes into a local buffer on the stack
    // For easy byte access in the following lines.
    int length = [gifScreen length];
	unsigned char *aBuffer = (unsigned char *)malloc(sizeof(unsigned char)*length);//[length];
    memset(aBuffer, 0, sizeof(unsigned char)*length);
	[gifScreen getBytes:aBuffer length:length];
	
	if (aBuffer[4] & 0x80) gifColor.GIF_colorF = 1; else gifColor.GIF_colorF = 0;
	if (aBuffer[4] & 0x08) gifColor.GIF_sorted = 1; else gifColor.GIF_sorted = 0;
	gifColor.GIF_colorC = (aBuffer[4] & 0x07);
	gifColor.GIF_colorS = 2 << gifColor.GIF_colorC;
	
    free(aBuffer);
    
	if (gifColor.GIF_colorF == 1) {//存储globaldata,主要是颜色尺寸信息
		globalData = [gifData subDataWithSkipBytes:(3 * gifColor.GIF_colorS)];
	}
    
    //int x1 = 0,x2 = 0;
	
	unsigned char bBuffer[1] = {0};
    NSData * temBuff = [gifData subDataWithSkipBytes:1];//while ([self GIFGetBytes:1] == YES)
    while ([temBuff length]) {
        
        [temBuff getBytes:bBuffer length:1];
        
        if (bBuffer[0] == 0x3B) { // This is the end
            break;
        }
        
        switch (bBuffer[0])
        {
            case 0x21: {
                // Graphic Control Extension (#n of n)
                NSArray * temAry = [gifData gifFramesReadDataExtensions];//[self GIFReadExtensions];
                if ([temAry count]) {
                    [gifFrames addObjectsFromArray:temAry];
                }
            }
                //x1++;
                break;
            case 0x2C:
                // Image Descriptor (#n of n)
                //[self GIFReadDescriptor];
                [gifData readDataDescriptorInFrame:[gifFrames lastObject]
                                          gifColor:&gifColor
                                            screen:&gifScreen
                                            global:globalData];
                //x2++;
                break;
        }
        
        //继续取下一个值
        temBuff = [gifData subDataWithSkipBytes:1];
	}
    
    //printf("gif 帧数 与描述 拓展块 x1 = %d,x2 = %d\n",x1,x2);
    return gifFrames;
}

+ (GifImageInfo *)gifInfoWithGIFData:(NSData *)data {
    return [self gifInfoWithGIFData:data maxFramesCount:0 screening:FramesProportionSelect];
}

+ (GifImageInfo *)gifInfoWithGIFData:(NSData *)data maxFramesCount:(NSInteger)maxCount screening:(FramesScreeningOptionType)type {
    if (![data isGifImageDatas]) {
        return nil;
    }
    
    NSArray * GIF_frames = [self gifFramesDecodeGIFData:data];
    
    if (GIF_frames.count <= 0) {
        UIImage *onceImage = [UIImage imageWithData:data];
        if (onceImage) {
            GifImageInfo * info = [[GifImageInfo alloc] init];
            info.images = [NSArray arrayWithObject:onceImage];
            return info;
        }
		return nil;
	}
    //NSLog(@"images count = %d",GIF_frames.count);
    return [self gifImageInfoWithGifFrame:GIF_frames maxFramesCount:maxCount screening:type];
}

@end

#pragma mark GifImageBytes操作，可以减少大量的内存，以及提高效率
@implementation GIFImageBytes
@synthesize datas,point;

- (BOOL)skipBytes:(int)length {
    if ([datas length] - point < length) {
        return NO;
    }
    self.point = self.point + length;
    return YES;
}

- (NSData *)subDataWithSkipBytes:(int)length {
    if ([datas length] - point < length) {
        return nil;
    }
    NSData * subData = [self.datas subdataWithRange:NSMakeRange(self.point, length)];
    self.point = self.point + length;
    return subData;
}

- (BOOL)getBytes:(unsigned char *)buffer skipBytes:(int)length {
    if ([datas length] - point < length) {
        return NO;
    }
    [self.datas getBytes:buffer range:NSMakeRange(self.point, length)];
    self.point = self.point + length;
    return YES;
    
}

- (NSArray *)gifFramesReadDataExtensions {
    NSMutableArray * gifFrames = [NSMutableArray arrayWithCapacity:0];
    
    // 21! But we still could have an Application Extension,
	// so we want to check for the full signature.
	unsigned char cur[1] = {0}, prev[1] = {0};
    //    NSData * temBuff = [self subDataWithSkipBytes:1];//[self GIFGetBytes:1];
    //    [temBuff getBytes:cur length:1];
    [self getBytes:cur skipBytes:1];//Graphic Control Label - 标识这是一个图形控制扩展块,固定值 0xF9
    
	while (cur[0] != 0x00)
    {
		
		// TODO: Known bug, the sequence F9 04 could occur in the Application Extension, we
		//       should check whether this combo follows directly after the 21.
		if (cur[0] == 0x04 && prev[0] == 0xF9)
		{
			//temBuff = [self subDataWithSkipBytes:5];//[self GIFGetBytes:5];
            
			AnimatedGifFrame *frame = [[AnimatedGifFrame alloc] init];
			
			unsigned char buffer[5] = {0};
			//[temBuff getBytes:buffer length:5];
            [self getBytes:buffer skipBytes:5];
			frame.disposalMethod = (buffer[0] >> 2) & 7;//(buffer[0] & 0x1c) >> 2;
			//NSLog(@"flags=%x, dm=%x", (int)(buffer[0]), frame.disposalMethod);
			//printf("extend %s\n",buffer);
			// We save the delays for easy access.
			frame.delay = (buffer[1] | buffer[2] << 8);//此参数比一定准确，不等于1一般表示延迟，一般是1/100秒
            printf("frame delay %f ",frame.delay);
			
			unsigned char board[8] = {0};
			board[0] = 0x21;
			board[1] = 0xF9;
			board[2] = 0x04;
			
			for(int i = 3, a = 0; a < 5; i++, a++)
			{
				board[i] = buffer[a];
			}
			
			frame.header = [NSData dataWithBytes:board length:8];
            
			[gifFrames addObject:frame];
			break;
		}
		
		prev[0] = cur[0];
        //        temBuff = [self subDataWithSkipBytes:1];//[self GIFGetBytes:1];
        //		[temBuff getBytes:cur length:1];
        [self getBytes:cur skipBytes:1];//
	}
    
    return gifFrames;
}
- (void)readDataDescriptorInFrame:(AnimatedGifFrame *)frame gifColor:(GifColor *)gifColor screen:(NSData **)screen global:(NSData *)global {
    NSData *temBuff = [self subDataWithSkipBytes:9];//[self GIFGetBytes:9];
    
    // Deep copy
	//NSMutableData *screenTmp = [NSMutableData dataWithData:temBuff];
    NSData *screenTmp = temBuff;
	
	unsigned char aBuffer[9] = {0};
	[temBuff getBytes:aBuffer length:9];
    //    [self getBytes:aBuffer skipBytes:9];
    //	NSData *screenTmp = [NSData dataWithBytes:aBuffer length:9];
    
	CGRect rect;
	rect.origin.x = ((int)aBuffer[1] << 8) | aBuffer[0];
	rect.origin.y = ((int)aBuffer[3] << 8) | aBuffer[2];
	rect.size.width = ((int)aBuffer[5] << 8) | aBuffer[4];
	rect.size.height = ((int)aBuffer[7] << 8) | aBuffer[6];
    
	//AnimatedGifFrame *frame = [GIF_frames lastObject];
	frame.area = rect;
	
	if (aBuffer[8] & 0x80) gifColor->GIF_colorF = 1; else gifColor->GIF_colorF = 0;
	
	unsigned char GIF_code = gifColor->GIF_colorC, GIF_sort = gifColor->GIF_sorted;
	
	if (gifColor->GIF_colorF == 1)
    {
		GIF_code = (aBuffer[8] & 0x07);
        
		if (aBuffer[8] & 0x20)
        {
            GIF_sort = 1;
        }
        else
        {
        	GIF_sort = 0;
        }
	}
	
	int GIF_size = (2 << GIF_code);
	
	size_t blength = [*screen length];
	unsigned char *bBuffer = (unsigned char *)malloc(sizeof(unsigned char)*blength);//[blength] ;
    memset(bBuffer, 0, sizeof(unsigned char)*blength);
	[*screen getBytes:bBuffer length:blength];
	
	bBuffer[4] = (bBuffer[4] & 0x70);
	bBuffer[4] = (bBuffer[4] | 0x80);
	bBuffer[4] = (bBuffer[4] | GIF_code);
	
	if (GIF_sort)
    {
		bBuffer[4] |= 0x08;
	}
	
    NSMutableData *GIF_string = [NSMutableData dataWithData:[@"GIF89a" dataUsingEncoding: NSUTF8StringEncoding]];
	*screen = [NSData dataWithBytes:bBuffer length:blength];
    [GIF_string appendData: *screen];
    
    free(bBuffer);
    
	if (gifColor->GIF_colorF == 1)
    {
		temBuff = [self subDataWithSkipBytes:(3 * GIF_size)];//[self GIFGetBytes:(3 * GIF_size)];
		[GIF_string appendData:temBuff];
	}
    else
    {
		[GIF_string appendData:global];
	}
	
	// Add Graphic Control Extension Frame (for transparancy)
	[GIF_string appendData:frame.header];
	
	char endC = 0x2c;
	[GIF_string appendBytes:&endC length:sizeof(endC)];
	
	size_t clength = [screenTmp length];
    if (clength == 3846144) {
        NSLog(@"err 发生");
    }
	unsigned char *cBuffer = (unsigned char *)malloc(sizeof(unsigned char)*clength);//[clength];
    memset(cBuffer, 0, sizeof(unsigned char)*clength);
	[screenTmp getBytes:cBuffer length:clength];
	
	cBuffer[8] &= 0x40;
	
	screenTmp = [NSData dataWithBytes:cBuffer length:clength];
	[GIF_string appendData: screenTmp];
    
    free(cBuffer);
    
	temBuff = [self subDataWithSkipBytes:1];//[self GIFGetBytes:1];
	[GIF_string appendData:temBuff];
	
	while (true)
    {
		temBuff = [self subDataWithSkipBytes:1];//[self GIFGetBytes:1];
		[GIF_string appendData:temBuff];
		
		unsigned char dBuffer[1] = {0};
		[temBuff getBytes:dBuffer length:1];
		
		long u = (long) dBuffer[0];
        
		if (u != 0x00)
        {
            temBuff = [self subDataWithSkipBytes:u];//[self GIFGetBytes:u];
			[GIF_string appendData:temBuff];
        }
        else
        {
            break;
        }
        
	}
	
	endC = 0x3b;
	[GIF_string appendBytes:&endC length:sizeof(endC)];
	
	// save the frame into the array of frames
	frame.data = GIF_string;
}
@end

