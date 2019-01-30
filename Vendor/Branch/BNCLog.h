/**
 @file          BNCLog.h
 @package       Branch-SDK
 @brief         Simple logging functions.

 @author        Edward Smith
 @date          October 2016
 @copyright     Copyright © 2016 Branch. All rights reserved.
*/

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif


///@functiongroup Branch Logging Functions

#pragma mark Log Initialization

/// Log facility initialization. Usually there is no need to call this directly.
FOUNDATION_EXPORT void BNCLogInitialize(void) __attribute__((constructor));

#pragma mark Log Message Severity

/// Log message severity
typedef NS_ENUM(NSInteger, BNCLogLevel) {
    BNCLogLevelAll = 0,
    BNCLogLevelDebugSDK = BNCLogLevelAll,
    BNCLogLevelBreakPoint,
    BNCLogLevelDebug,
    BNCLogLevelWarning,
    BNCLogLevelError,
    BNCLogLevelAssert,
    BNCLogLevelLog,
    BNCLogLevelNone,
    BNCLogLevelMax
};

/*!
* @return Returns the current log severity display level.
*/
FOUNDATION_EXPORT BNCLogLevel BNCLogDisplayLevel(void);

/*!
* @param level Sets the current display level for log messages.
*/
FOUNDATION_EXPORT void BNCLogSetDisplayLevel(BNCLogLevel level);

/*!
* @param level The log level to convert to a string.
* @return Returns the string indicating the log level.
*/
FOUNDATION_EXPORT NSString *_Nonnull BNCLogStringFromLogLevel(BNCLogLevel level);

/*!
* @param string A string indicating the log level.
* @return Returns The log level corresponding to the string.
*/
FOUNDATION_EXPORT BNCLogLevel BNCLogLevelFromString(NSString*_Null_unspecified string);


#pragma mark - Programmatic Breakpoints


///@return Returns 'YES' if programmatic breakpoints are enabled.
FOUNDATION_EXPORT BOOL BNCLogBreakPointsAreEnabled(void);

///@param enabled Sets programmatic breakpoints enabled or disabled.
FOUNDATION_EXPORT void BNCLogSetBreakPointsEnabled(BOOL enabled);


#pragma mark - Client Initialization Function


typedef void (*BNCLogClientInitializeFunctionPtr)(void);

///@param clientInitializationFunction The client function that should be called before logging starts.
FOUNDATION_EXPORT BNCLogClientInitializeFunctionPtr _Null_unspecified
    BNCLogSetClientInitializeFunction(BNCLogClientInitializeFunctionPtr _Nullable clientInitializationFunction);


#pragma mark - Optional Log Output Handlers


///@brief Pre-defined log message handlers --

typedef void (*BNCLogOutputFunctionPtr)(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString*_Nullable message);

FOUNDATION_EXPORT void BNCLogFunctionOutputToStdOut(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString *_Nullable message);
FOUNDATION_EXPORT void BNCLogFunctionOutputToStdErr(NSDate*_Nonnull timestamp, BNCLogLevel level, NSString *_Nullable message);

///@param functionPtr   A pointer to the logging function.  Setting the parameter to NULL will flush
///                     and close the currently set log function and future log messages will be
///                     ignored until a non-NULL logging function is set.
FOUNDATION_EXPORT void BNCLogSetOutputFunction(BNCLogOutputFunctionPtr _Nullable functionPtr);

///@return Returns the current logging function.
FOUNDATION_EXPORT BNCLogOutputFunctionPtr _Nullable BNCLogOutputFunction(void);

/// If a predefined log handler is being used, the function closes the output file.
FOUNDATION_EXPORT void BNCLogCloseLogFile(void);

///@param URL Sets the log output function to a function that writes messages to the file at URL.
FOUNDATION_EXPORT void BNCLogSetOutputToURL(NSURL *_Nullable URL);

///@param URL Sets the log output function to a function that writes messages to the file at URL.
///@param maxRecords Wraps the file at `maxRecords` records.
FOUNDATION_EXPORT void BNCLogSetOutputToURLRecordWrap(NSURL *_Nullable URL, long maxRecords);

///@param URL Sets the log output function to a function that writes messages to the file at URL.
///@param maxBytes Wraps the file at `maxBytes` bytes.  Must be an even number of bytes.
FOUNDATION_EXPORT void BNCLogSetOutputToURLByteWrap(NSURL *_Nullable URL, long maxBytes);

typedef void (*BNCLogFlushFunctionPtr)(void);

///@param flushFunction The logging functions use `flushFunction` to flush the outstanding log
///                     messages to the output function.  For instance, this function may call
///                     `fsync` to assure that the log messages are written to disk.
FOUNDATION_EXPORT void BNCLogSetFlushFunction(BNCLogFlushFunctionPtr _Nullable flushFunction);

///@return Returns the current flush function.
FOUNDATION_EXPORT BNCLogFlushFunctionPtr _Nullable BNCLogFlushFunction(void);


#pragma mark - BNCLogWriteMessage


/// The main logging function used in the variadic logging defines.
FOUNDATION_EXPORT void BNCLogWriteMessageFormat(
    BNCLogLevel logLevel,
    const char *_Nullable sourceFileName,
    int32_t sourceLineNumber,
    NSString* _Nullable messageFormat,
    ...
) NS_FORMAT_FUNCTION(4,5);

/// Swift-friendly wrapper for BNCLogWriteMessageFormat
FOUNDATION_EXPORT void BNCLogWriteMessage(
    BNCLogLevel logLevel,
    NSString *_Nonnull sourceFileName,
    int32_t sourceLineNumber,
    NSString *_Nonnull message
);

/// This function synchronizes all outstanding log messages and writes them to the logging function
/// set by BNCLogSetOutputFunction.
FOUNDATION_EXPORT void BNCLogFlushMessages(void);

///@return  Returns true if the app is currently attached to a debugger.
FOUNDATION_EXPORT BOOL BNCLogDebuggerIsAttached(void);

#pragma - Debugging

///@return  Returns true if the app is currently attached to a debugger.
extern BOOL BNCLogDebuggerIsAttached(void);

/// Stops execution at the current execution point.
/// If attached to a debugger, current app will halt and wait for the debugger.
/// If not attached to a debugger then the current app will probably quit executing.
#define BNCLogDebugBreakpoint() \
    do { raise(SIGINT); } while (0)

#pragma mark - Logging
///@info Logging

///@param format Log an info message with the specified formatting.
#define BNCLogDebugSDK(...) \
    do  { BNCLogWriteMessageFormat(BNCLogLevelDebugSDK, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a debug message with the specified formatting.
#define BNCLogDebug(...) \
    do  { BNCLogWriteMessageFormat(BNCLogLevelDebug, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a warning message with the specified formatting.
#define BNCLogWarning(...) \
    do  { BNCLogWriteMessageFormat(BNCLogLevelWarning, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log an error message with the specified formatting.
#define BNCLogError(...) \
    do  { BNCLogWriteMessageFormat(BNCLogLevelError, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///@param format Log a message with the specified formatting.
#define BNCLog(...) \
    do  { BNCLogWriteMessageFormat(BNCLogLevelLog, __FILE__, __LINE__, __VA_ARGS__); } while (0)

///Cause a programmatic breakpoint if breakpoints are enabled.
#define BNCLogBreakPoint() \
    do  { \
        if (BNCLogBreakPointsAreEnabled()) { \
            BNCLogWriteMessageFormat(BNCLogLevelBreakPoint, __FILE__, __LINE__, @"Programmatic breakpoint."); \
            if (BNCLogDebuggerIsAttached()) { \
                BNCLogFlushMessages(); \
                BNCLogDebugBreakpoint(); \
            } \
        } \
    } while (0)

///Log a message and cause a programmatic breakpoint if breakpoints are enabled.
#define BNCBreakPointWithMessage(...) \
    do  { \
        if (BNCLogBreakPointsAreEnabled() { \
            BNCLogWriteMessageFormat(BNCLogLevelBreakPoint, __FILE__, __LINE__, __VA_ARGS__); \
            if (BNCLogDebuggerIsAttached()) { \
                BNCLogFlushMessages(); \
                BNCLogDebugBreakpoint(); \
            } \
        } \
    } while (0)

///Check if an asserting is true.  If programmatic breakpoints are enabled then break.
#define BNCLogAssert(condition) \
    do  { \
        if (!(condition)) { \
            BNCLogWriteMessageFormat(BNCLogLevelAssert, __FILE__, __LINE__, @"(%s) !!!", #condition); \
            if (BNCLogBreakPointsAreEnabled() && BNCLogDebuggerIsAttached()) { \
                BNCLogFlushMessages(); \
                BNCLogDebugBreakpoint(); \
            } \
        } \
    } while (0)

///Check if an asserting is true logging a message if the assertion fails.
///If programmatic breakpoints are enabled then break.
#define BNCLogAssertWithMessage(condition, message, ...) \
    do  { \
        if (!(condition)) { \
            NSString *m = [NSString stringWithFormat:message, __VA_ARGS__]; \
            BNCLogWriteMessageFormat(BNCLogLevelAssert, __FILE__, __LINE__, @"(%s) !!! %@", #condition, m); \
            if (BNCLogBreakPointsAreEnabled() && BNCLogDebuggerIsAttached()) { \
                BNCLogFlushMessages(); \
                BNCLogDebugBreakpoint(); \
            } \
        } \
    } while (0)

///Assert that the current thread is the main thread.
#define BNCLogAssertIsMainThread() \
    BNCLogAssert([NSThread isMainThread])

///Write the name of the current method to the log.
#define BNCLogMethodName() \
    BNCLogDebug(@"Method '%@'.",  NSStringFromSelector(_cmd))

///Write the name of the current function to the log.
#define BNCLogFunctionName() \
    BNCLogDebug(@"Function '%s'.", __FUNCTION__)


#ifdef __cplusplus
}
#endif
