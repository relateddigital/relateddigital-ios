//
//  RelatedDigitalGlobal.h
//  RelatedDigital
//
//  Created by Egemen Gülkılık on 22.01.2022.
//

#import <UIKit/UIKit.h>


#define RD_LEVEL_LOG_THREAD(level, levelString, fmt, ...) \
    do { \
        if (rdLogLevel >= level) { \
            NSString *thread = ([[NSThread currentThread] isMainThread]) ? @"M" : @"B"; \
            NSLog((@"[%@] [%@] => %s [Line %d] " fmt), levelString, thread, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); \
        } \
    } while(0)

#define RD_LEVEL_LOG_NO_THREAD(level, levelString, fmt, ...) \
    do { \
        if (rdLogLevel >= level) { \
            NSLog((@"[%@] %s [Line %d] " fmt), levelString, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__); \
        } \
    } while(0)

#define RD_LEVEL_LOG_IMPLEMENTATION(fmt, ...) \
    do { \
        if (rdLogLevel >= 1) { \
            NSLog((@"🚨RelatedDigital Implementation Error🚨 - " fmt), ##__VA_ARGS__); \
        } \
    } while(0)

//only log thread if #RD_LOG_THREAD is defined
#ifdef RD_LOG_THREAD
#define RD_LEVEL_LOG RD_LEVEL_LOG_THREAD
#else
#define RD_LEVEL_LOG RD_LEVEL_LOG_NO_THREAD
#endif

extern NSInteger rdLogLevel; // Default is RDLogLevelError

#define RD_LTRACE(fmt, ...) RD_LEVEL_LOG(5, @"T", fmt, ##__VA_ARGS__)
#define RD_LDEBUG(fmt, ...) RD_LEVEL_LOG(4, @"D", fmt, ##__VA_ARGS__)
#define RD_LINFO(fmt, ...) RD_LEVEL_LOG(3, @"I", fmt, ##__VA_ARGS__)
#define RD_LWARN(fmt, ...) RD_LEVEL_LOG(2, @"W", fmt, ##__VA_ARGS__)
#define RD_LERR(fmt, ...) RD_LEVEL_LOG(1, @"E", fmt, ##__VA_ARGS__)
#define RD_LIMPERR(fmt, ...) RD_LEVEL_LOG_IMPLEMENTATION(fmt, ##__VA_ARGS__)
#define RDLOG RD_LDEBUG

#define RD_WEAKIFY(var) __weak __typeof(var) RDWeak_##var = var;
#define RD_STRONGIFY(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong __typeof(var) var = RDWeak_##var; \
