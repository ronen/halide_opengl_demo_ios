//
//  PERFTimer.h
//  PerfHarness
//
//  Created by sachs on 3/29/16.
//  Copyright © 2016 Adobe Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern void PERFTimerLog(NSString *s, ...);

@interface PERFTimer : NSObject

+ (PERFTimer *)sharedTimer:(NSString *)timerName;
- (id)initWithName:(NSString *)timerName;
- (void)start;
- (void)stop;
- (void)logElapsedSecondsWithMessage:(NSString *)msg, ...;
- (void)logTotalTimeWithMessage:(NSString *)msg, ...;

@end
