//
//  LibraryCell.h
//  TheProject
//
//  Created by Tobin1 on 5/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>


@class Entry;
@class GuideDownloader;


@interface LibraryCell : UITableViewCell <UIGestureRecognizerDelegate> {
    Entry *entry;
    GuideDownloader *downloader;
    NSDictionary *lastStatus;
    UILabel *titleLabel;
    UILabel *downloadProgressLabel;
    UILabel *authorLabel;
    UILabel *lastUpdateLabel;
    UILabel *statusLabel;
    //**UILabel *sizeLabel;
    UIButton *pauseButton;
    UIButton *resumeButton;
    UIButton *buyButton;
    UIButton *deleteButton;
	//CAGradientLayer *buttonBackground;
    //**UIButton *downloadImagesButton;
    //**UIButton *cancelImageDownloadButton;
    //**UIButton *removeOfflineImagesButton;
    UIProgressView *downloadProgress;
    NSString *currentTask;
    NSTimer *connectivityChecker;
    CGRect iconFrame;
    float height;
    BOOL downloading;
    BOOL isSample;
    //**BOOL offlineImagesDownloaded;
    BOOL readyForViewing;
    BOOL paused;
    BOOL waiting;
    BOOL connectedToInternet;
}


@property (nonatomic, strong) Entry *entry;
@property (nonatomic)        BOOL   downloading;
@property (nonatomic)        BOOL   waiting;
@property (nonatomic, strong) GuideDownloader *downloader;
@property (nonatomic)        float  height;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

@end

