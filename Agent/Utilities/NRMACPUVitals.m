//
//  NRMACPUVitals.m
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 2/7/14.
//  Copyright (c) 2014 New Relic. All rights reserved.
//

#import "NRMACPUVitals.h"
#import "NRLogger.h"

#import <objc/runtime.h>
#import <mach/mach.h>


@implementation NRMACPUVitals

static NSString *__NRMACPUVitalsLock = @"NRMACPUVitalsLock";

static CPUTime __appStartCPUTime;
static BOOL __appStartCPUTimeIsValid;

//
// Get the total user & system CPU time for the current process.
//
// Adapted from this:
// http://stackoverflow.com/questions/9081094/how-do-you-measure-actual-on-cpu-time-for-an-ios-thread
//
+ (int)cpuTime:(CPUTime*) rpd
{
    @synchronized(__NRMACPUVitalsLock) {
        task_t task;
        kern_return_t kern_retval;
        mach_msg_type_number_t count;
        thread_array_t thread_table;
        thread_basic_info_t thi;
        thread_basic_info_data_t thi_data;
        mach_msg_type_number_t table_size;
        struct mach_task_basic_info ti;
        double utime = 0.0;
        double stime = 0.0;
        BOOL error = NO;

        task = mach_task_self();
        count = MACH_TASK_BASIC_INFO_COUNT;
        kern_retval = task_info(task, MACH_TASK_BASIC_INFO, (task_info_t)&ti, &count);
        if (kern_retval != KERN_SUCCESS) {
            return -1;
        }
        {
            unsigned i;

            //
            // the following times are for threads which have already terminated and gone away.
            //
            utime = ti.user_time.seconds + ti.user_time.microseconds * 1e-6;
            stime = ti.system_time.seconds + ti.system_time.microseconds * 1e-6;

            kern_retval = task_threads(task, &thread_table, &table_size);

            //
            // failed to retrieve thread list: we can't proceed any further.
            //
            if (kern_retval != KERN_SUCCESS) {
                NRLOG_ERROR(@"task_threads: %s", mach_error_string(kern_retval));
                return -1;
            }

            thi = &thi_data;

            //
            // for each active thread, add up thread time
            //
            for (i = 0; i < table_size; ++i) {
                count = THREAD_BASIC_INFO_COUNT;
                kern_retval = thread_info(thread_table[i], THREAD_BASIC_INFO, (thread_info_t)thi, &count);

                //
                // if the thread_info call fails, clean up and fail hard. partial results are probably useless.
                //
                if (kern_retval != KERN_SUCCESS) {
                    for (; i < table_size; ++i) {
                        kern_retval = mach_port_deallocate(mach_task_self(), thread_table[i]);
                        if(kern_retval != KERN_SUCCESS) {
                            NRLOG_ERROR(@"mach_port_deallocate thread_table: %s", mach_error_string(kern_retval));
                        }
                    }

                    kern_retval = vm_deallocate(mach_task_self(), (vm_offset_t)thread_table, table_size * sizeof(thread_array_t));
                    if(kern_retval != KERN_SUCCESS) {
                        NRLOG_ERROR(@"vm_deallocate thread_table: %s", mach_error_string(kern_retval));
                    }
                    return -1;
                }

                //
                // otherwise, accumulate & continue.
                //
                if ((thi->flags & TH_FLAGS_IDLE) == 0) {
                    utime += thi->user_time.seconds + thi->user_time.microseconds * 1e-6;
                    stime += thi->system_time.seconds + thi->system_time.microseconds * 1e-6;
                }

                kern_retval = mach_port_deallocate(mach_task_self(), thread_table[i]);
                if(kern_retval != KERN_SUCCESS) {
                    NRLOG_ERROR(@"mach_port_deallocate thread_table: %s", mach_error_string(kern_retval));
                    error = YES;
                }
            }

            //
            // deallocate the thread table.
            //
            kern_retval = vm_deallocate(mach_task_self(), (vm_offset_t)thread_table, table_size * sizeof(thread_array_t));
            if(kern_retval != KERN_SUCCESS) {
                NRLOG_ERROR(@"vm_deallocate thread_table: %s", mach_error_string(kern_retval));
                error = YES;
            }
        }
        if (error == YES)
            return -1;

        rpd->utime = utime;
        rpd->stime = stime;
        return 0;
    }
}

+ (int) appStartCPUtime:(CPUTime*)cpuTime
{
    if (!__appStartCPUTimeIsValid) {
        int errorCode = [[self class] setAppStartCPUTime];
        if (errorCode != 0) {
            return errorCode;
        }
    }
    cpuTime->utime = __appStartCPUTime.utime;
    cpuTime->stime = __appStartCPUTime.stime;
    return 0;
}
+ (int) setAppStartCPUTime
{
    int errorCode = [[self class] cpuTime:&__appStartCPUTime];
    __appStartCPUTimeIsValid = (errorCode==0)?YES:NO;
    return errorCode;
}


@end
