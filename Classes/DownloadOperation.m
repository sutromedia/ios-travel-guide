
#import "DownloadOperation.h"

@interface DownloadOperation ()
@property (readwrite, copy) NSURL *url;
@property (readwrite, copy) NSString *downloadPath;
@end

@implementation DownloadOperation

@synthesize url;
@synthesize downloadPath;

-(id)initWithURL:(NSURL *)newURL downloadPath:(NSString *)newDownloadPath {
    
    self = [super init];
    if (self != nil) {
        self.url = newURL;
        self.downloadPath = newDownloadPath;
    }
    return self;
}

-(void)main {
    
    int numberOfTrys = 5;
    
    int tryCounter;
    for (tryCounter = 0; tryCounter <= numberOfTrys; tryCounter ++) {
    
        if ( self.isCancelled ) return;  
        
        if ( nil == self.url ) return;
        NSData *imageData = [NSData dataWithContentsOfURL:self.url]; 
        if ( self.isCancelled ) return;  
        
        NSError *theError = nil;
        if ([imageData writeToFile:downloadPath  options:NSAtomicWrite error:&theError]) {
            NSLog(@"DOWNLOADOPERATION.main: Successfully wrote image file to %@", downloadPath);
            
            if (tryCounter > 0) {
                NSLog(@"Download worked after %i try", tryCounter);
            }
            
            break;
        }
        
        else NSLog(@"DOWNLOADOPERATION.main: Failed to download or save image file from %@. Error = %@", [url absoluteString], [theError description]);
    }
   
}

@end
