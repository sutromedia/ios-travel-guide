//
//  LibraryHome.h
//  TheProject
//
//  Created by Tobin1 on 5/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FMDatabase, GuideDownloader;

@interface LibraryHome : UIViewController <UITableViewDelegate, UITableViewDataSource> {
   
    UITableView *libraryList;
    NSMutableArray *displayedGuides;
    FMDatabase *guidesDB;
    NSMutableDictionary *guideDownloaders;
    GuideDownloader *sw_downloader;
    int guideID;
    BOOL needToRunOpeningSequence;
}

@property (nonatomic, strong) UITableView *libraryList;


@end
