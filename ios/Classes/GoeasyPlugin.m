#import "GoeasyPlugin.h"
#if __has_include(<goeasy/goeasy-Swift.h>)
#import <goeasy/goeasy-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "goeasy-Swift.h"
#endif

@implementation GoeasyPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftGoeasyPlugin registerWithRegistrar:registrar];
}
@end
