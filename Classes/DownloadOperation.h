
#import <Foundation/Foundation.h>

@interface DownloadOperation : NSOperation {
    NSURL *url;
    NSString *downloadPath;
}

@property (readonly, copy) NSURL *url;
@property (readonly, copy) NSString *downloadPath;

-(id)initWithURL:(NSURL *)url downloadPath:(NSString *)downloadPath;

@end
