//
//  PERFTimer.m
//  PerfHarness
//
//  Created by sachs on 3/29/16.
//  Copyright © 2016 Adobe Labs. All rights reserved.
//

#import "PERFTimer.h"


@interface PERFTimer() {
    CFAbsoluteTime startTime;
    CFAbsoluteTime lastTime;
    NSString *name;
    NSString *logName;
}
@end

@implementation PERFTimer

// Get a named timer from a singleton dicitionary of timers. If the named timer doesn't
// exist then create a new one.
+ (PERFTimer *)sharedTimer:(NSString *)timerName
{
    static dispatch_once_t pred;
    static NSMutableDictionary *sharedTimers = nil;
    
    dispatch_once(&pred, ^{
        sharedTimers = [NSMutableDictionary dictionary];
    });
    
    // lock the dictionary when deciding whether or not to create a new TMTimer
    PERFTimer *timer = nil;
    @synchronized(sharedTimers)
    {
        timer = [sharedTimers objectForKey:timerName];
        if (timer == nil)
        {
            timer = [[PERFTimer alloc] initWithName:timerName];
            [sharedTimers setValue:timer forKey:timerName];
        }
    }
    return timer;
}

- (id)initWithName:(NSString *)timerName
{
    self = [super init];
    if (self != nil)
    {
        name = timerName;
        logName = [NSString stringWithFormat:@"  Timer(%@)", name];
    }
    return self;
}

- (void)start
{
    startTime = CFAbsoluteTimeGetCurrent();
    lastTime = startTime;
}

- (void)stop
{
    lastTime = CFAbsoluteTimeGetCurrent();
}

- (void)logElapsedSecondsWithMessage:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    NSLog(@"%@ (%.6fs)", msg, now - lastTime);
    lastTime = now;
    
    va_end(args);
}

- (void)logTotalTimeWithMessage:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    NSLog(@"%@ (%.6fs)", msg, now - lastTime);
    
    va_end(args);
}

@end
