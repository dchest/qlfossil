#import <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import "TimelineGenerator.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview,
              CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
  if (QLPreviewRequestIsCancelled(preview))
    return noErr;
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *html = HTMLTimelineForDatabase(
                            [[(NSURL*)url path] fileSystemRepresentation], 100);
   
  if (!html || [html isEqualToString:@""])
    goto out;

  CFDictionaryRef properties = 
  (CFDictionaryRef)[NSDictionary dictionaryWithObject:@"UTF-8" 
                     forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
  
  QLPreviewRequestSetDataRepresentation(preview, 
                      (CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding], 
                                        kUTTypeHTML, 
                                        properties);
out:
  [pool release];
  return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
