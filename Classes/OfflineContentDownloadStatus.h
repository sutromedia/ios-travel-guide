//
//  OfflineContentDownloadStatus.h
//  TheProject
//
//  Created by Tobin Fisher on 11/15/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GuideDownloader;

@interface OfflineContentDownloadStatus : UIView {

    GuideDownloader *__unsafe_unretained downloader;
    NSDictionary *lastStatus;
    UILabel *downloadProgressLabel;
    UILabel *statusLabel;
    UIButton *pauseButton;
    UIButton *resumeButton;
    UIButton *downloadImagesButton;
    UIButton *cancelImageDownloadButton;
    UIButton *removeOfflineImagesButton;
    UIProgressView *downloadProgress;
    NSString *currentTask;
    NSTimer *connectivityChecker;
    float height;
    BOOL downloading;
    BOOL readyForViewing;
    BOOL paused;
    BOOL waiting;
    BOOL connectedToInternet;
}


@property (nonatomic)        BOOL   downloading;
@property (nonatomic)        BOOL   waiting;
@property (unsafe_unretained, nonatomic) GuideDownloader *downloader;
@property (nonatomic)        float  height;


@end
