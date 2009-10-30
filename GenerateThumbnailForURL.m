#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <AppKit/AppKit.h>
#import "TimelineGenerator.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, 
                                 QLThumbnailRequestRef thumbnail, 
                                 CFURLRef url, CFStringRef contentTypeUTI, 
                                 CFDictionaryRef options, CGSize maxSize)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  
  // Use webkit render
  
  NSMutableString *html = HTMLTimelineForDatabase(
                                [[(NSURL*)url path] fileSystemRepresentation],
                                12);
  [html appendString:@"<div style='font-size: 120px; position: absolute; "
                      " bottom: 0; background: white; width: 100%; color: #555;"
                      " font-weight: bold; "
                      " text-align: center; padding: 30px 0'>FOSSIL</div>"];
  
  
  NSRect webKitRect = NSMakeRect(0.0, 0.0, 600.0, 800.0);
  CGSize thumbSize = NSSizeToCGSize(NSMakeSize(maxSize.width * (600.0/800.0),
                                                maxSize.height));
  float scale = maxSize.height / 800.0;
  NSSize scaleSize = NSMakeSize(scale, scale);

  WebView* webView = [[WebView alloc] initWithFrame:webKitRect];
  [webView scaleUnitSquareToSize:scaleSize];
  [[[webView mainFrame] frameView] setAllowsScrolling:NO];
  
  [[webView mainFrame] loadData:[html dataUsingEncoding:NSUTF8StringEncoding]
                       MIMEType:@"text/html"
                       textEncodingName:@"UTF-8" baseURL:nil];
  
  while([webView isLoading]) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0, true);
  }
  
  // Get a context to render into
  CGContextRef cgContext = 
    QLThumbnailRequestCreateContext(thumbnail, thumbSize, false, NULL);
  NSGraphicsContext* context = 
    [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext 
                       flipped:[webView isFlipped]];
  
  [webView displayRectIgnoringOpacity:[webView bounds] inContext:context];
    
  QLThumbnailRequestFlushContext(thumbnail, cgContext);
  
  CFRelease(cgContext);
  
  // Or just fossil image: (put fossil.png into Resources)
  /*
  CFBundleRef bundle = QLThumbnailRequestGetGeneratorBundle(thumbnail);
  CFURLRef imageUrl = CFBundleCopyResourceURL(bundle, CFSTR("fossil"), CFSTR("eps"), NULL);
  //NSData *data = [NSData dataWithContentsOfURL:(NSURL *)imageUrl];
  NSImage *image = [[NSImage alloc] initWithContentsOfURL:(NSURL *)imageUrl];
  [image setSize:NSMakeSize(maxSize.width, maxSize.height)];
  QLThumbnailRequestSetImageWithData(thumbnail, (CFDataRef)[image TIFFRepresentation], nil);
  
  CFRelease(bundle);
  CFRelease(url);
*/
  
  [pool release];
  return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
