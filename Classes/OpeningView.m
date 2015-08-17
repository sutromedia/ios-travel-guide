//
//  OpeningView.m
//  TheProject
//
//  Created by Tobin Fisher on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "OpeningView.h"
#import "ZipArchive.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "FilterPicker.h"
#import "MapViewController.h"
#import "EntryCollection.h"

#define kContentUpdateAlertTag 25

@implementation OpeningView

- (id)init {
    
    [Props global].contentUpdateInProgress = TRUE;
    
    CGRect frame = CGRectMake(0, 0, [Props global].screenWidth, [Props global].screenHeight);
    
    self = [super initWithFrame:frame];
    if (self) {
        
        UIView *background = [[UIView alloc] initWithFrame:self.frame];
        
        if ([ActivityLogger sharedActivityLogger].sequence_id == 0) {
            UIImageView *updateView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];
            updateView.frame = self.frame;
            [self addSubview:updateView];
            
            background.alpha = 0.6;
        }
       
        else background.alpha = 0.75;
        
        background.backgroundColor = [UIColor blackColor];
        [self addSubview:background];
                
        float loadingAnimationSize = 40;
        
        float fontSize = [Props global].deviceType == kiPad ? 25 : 20;
        CGRect labelRect = CGRectMake(0, [Props global].screenHeight * .3, [Props global].screenWidth, fontSize * 2.2);
        label = [[UILabel alloc] initWithFrame:labelRect];
        label.text = @"Downloading the latest...";
        label.font = [UIFont fontWithName:kFontName size:fontSize];
        label.textColor = [UIColor whiteColor];
        label.lineBreakMode = 0;
        label.shadowColor = [UIColor darkGrayColor];
        label.shadowOffset = CGSizeMake(1, 1);
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.hidden = TRUE;
        [self addSubview:label];
        
        progressInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        progressInd.frame = CGRectMake(([Props global].screenWidth - loadingAnimationSize)/2, CGRectGetMaxY(labelRect) + [Props global].tweenMargin, loadingAnimationSize, loadingAnimationSize);
        [progressInd sizeToFit];
        //[progressInd startAnimating];
        progressInd.hidden = TRUE;
        [self addSubview: progressInd];
        
        cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton setTitle:@"cancel" forState:UIControlStateNormal];
        float buttonWidth = [Props global].screenWidth/3.2;
        cancelButton.frame = CGRectMake(([Props global].screenWidth - buttonWidth)/2, [Props global].screenHeight * .7, buttonWidth, 35);
        cancelButton.hidden = TRUE;
        [self addSubview:cancelButton];
        
        UIAlertView *updateAlert = [[UIAlertView alloc] initWithTitle:@"Updated content available" message:@"Would you like to get the latest?" delegate:self cancelButtonTitle:@"Not now" otherButtonTitles:@"Yes!", nil];
        
        updateAlert.tag = kContentUpdateAlertTag;
        [updateAlert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];

        //[self checkForContentUpdate];
        
    }
    
    return self;
}


- (void) dealloc {
    
    [progressInd stopAnimating];
}

/*- (void) checkForContentUpdate {
    
    NSLog(@"EAD.checkForContentUpdate");
    
    NSString *urlString;
    if ([Props global].appID != 1 && ![Props global].isShellApp)
        urlString = [NSString stringWithFormat:@"http://www.sutromedia.com/published/content/%i-bundleversion.txt", [Props global].appID];
    
    else urlString = @"http://www.sutromedia.com/published/content/1.v2-bundleversion.txt";
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSError* error;
    int latestBundleVersion = [[NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:&error] intValue];
    
    NSLog(@"EAD.checkForContentUpdate: Latest bundle version = %i and current bundle version = %i", latestBundleVersion, [Props global].bundleVersion);
    
    NSLog(@"************** WARNING: SET TO ALWAYS UPDATE DATABASE - CHANGE ME!!! **************************");
    
    if (TRUE || latestBundleVersion > [Props global].bundleVersion){
        
        if ([Props global].appID == 1) [self updateContent];
        
        else {
            
            UIAlertView *updateAlert = [[UIAlertView alloc] initWithTitle:@"Updated content available" message:@"Would you like to get the latest?" delegate:self cancelButtonTitle:@"Not now" otherButtonTitles:@"Yup!", nil];
            
            updateAlert.tag = kContentUpdateAlertTag;
            [updateAlert show];
            [updateAlert release];
        }
    }

}
*/

-(void) alertView: (UIAlertView*) theAlert clickedButtonAtIndex: (NSInteger) buttonIndex {
    
	if (theAlert.tag == kContentUpdateAlertTag){
        
        if (buttonIndex != 0){
            
            progressInd.hidden = FALSE;
            [progressInd startAnimating];
            cancelButton.hidden = FALSE;
            label.hidden = FALSE;
            
            [self setNeedsDisplay];
            
            //[self performSelector:@selector(update) withObject:nil afterDelay:0.1];
            [self performSelectorInBackground:@selector(update) withObject:nil]; //This needs to be done in the background for the cancel button to work
            //[self updateContent];
        }
        
        else [self hide];
    }
}


- (void) update {
    
    [self updateContent];
    
    [self hide];
}


- (void) cancel {
    
    NSLog(@"Cancel button pressed");
    
    cancel = TRUE;
    [self hide];
}


- (void) updateContent {
    
    NSLog(@"EAD.updateContent. In main thread - %@", [NSThread isMainThread] ? @"YES" : @"NO");
    
    @autoreleasepool {
    
        NSDate *date = [NSDate date];
        
        NSString *unzippedFilePath;   
        
        NSString *urlString;
        if ([Props global].appID != 1 && ![Props global].isShellApp){
            urlString = [NSString stringWithFormat:@"%@/%i.sqlite3.zip", [Props global].serverDatabaseUpdateSource, [Props global].appID];
            unzippedFilePath= [NSString stringWithFormat:@"%@/%i.sqlite3", [Props global].cacheFolder, [Props global].appID];
        }
        
        else{
            urlString = [NSString stringWithFormat:@"%@/1.v2.sqlite3.zip", [Props global].serverDatabaseUpdateSource];
            unzippedFilePath= [NSString stringWithFormat:@"%@/1.v2.sqlite3", [Props global].cacheFolder];
        }
        
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; 
        
        NSString *zippedFilePath= [NSString stringWithFormat:@"%@.zip", unzippedFilePath];
        
        NSURL *dataURL = [NSURL URLWithString: urlString];
        NSLog(@"EAD.updateContent: About to try and download database at %@", urlString);
        
        //Get the data
        NSData *databaseData = [[NSData alloc] initWithContentsOfURL:dataURL options:NSDataReadingUncached error:nil];
        
        //Write the data to disk
        [databaseData writeToFile: zippedFilePath atomically:YES];
        
        //Unzip file
        ZipArchive *za = [[ZipArchive alloc] init];
        if ([za UnzipOpenFile: zippedFilePath]) {
            BOOL ret = [za UnzipFileTo: [Props global].cacheFolder overWrite: YES];
            if (NO == ret){} [za UnzipCloseFile];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:zippedFilePath error:nil];
        
        NSLog(@"EAD.updateContent: File saved to disk, %0.2f", -[date timeIntervalSinceNow]);
        
        //*************** Get any missing app icons and check that the database is good *********************
        
        FMDatabase *db = [[FMDatabase alloc] initWithPath:unzippedFilePath];
        [db open];
        
        NSMutableArray *missingImages = [NSMutableArray new];
        BOOL databaseIsReadable = FALSE;
        
        @synchronized ([Props global].dbSync){
            FMResultSet *rs = [db executeQuery:@"SELECT icon_photo_id FROM entries"];
            while ([rs next] && !cancel){
                
                int iconId = [rs intForColumn:@"icon_photo_id"];
                
                NSString *imageName = [NSString stringWithFormat:@"%i_x100", iconId];
                NSString *filePath = [NSString stringWithFormat:@"%@/images/%@.jpg", [Props global].contentFolder, imageName];
                
                //NSLog(@"Checking for %@", imageName);
                
                //Look to see if the 100px icon image is present
                if (!([[NSFileManager defaultManager] fileExistsAtPath:[[NSBundle mainBundle] pathForResource:imageName ofType:@"jpg"]] || [[NSFileManager defaultManager] fileExistsAtPath:filePath])) {
                    [missingImages addObject:[NSNumber numberWithInt:iconId]];
                }
                
                databaseIsReadable = TRUE;
            }
            
            [rs close];
        }
        
        if (!databaseIsReadable) {
            NSLog(@"***** ERROR: OPENINGVIEW.updateContent: database does not appear to be readable. Aborting ***********");
            return;
        }
        
        NSLog(@"EAD.updateContent: %i images missing", [missingImages count]);
        
        NSString *theFolderPath = [NSString stringWithFormat:@"%@/images", [Props global].contentFolder];
        NSError *theError = nil;
        
        //Create folder for content as necessary
        if(![[NSFileManager defaultManager] isWritableFileAtPath:theFolderPath]) 
            [[NSFileManager defaultManager] createDirectoryAtPath: theFolderPath withIntermediateDirectories:YES attributes: nil error:&theError];
        
        for (NSNumber *missingImage in missingImages) {
            NSLog(@"EAD.updateContent: Missing image %i", [missingImage intValue]);
            
            if (cancel) break;
            
            NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i_x100.jpg", [Props global].contentFolder, [missingImage intValue]];
            
            NSString *urlString = [[NSString stringWithFormat: @"http://%@/published/dynamic-photos/height/100/%i.jpg", [Props global].serverContentSource, [missingImage intValue]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
            
            //Get the data
            NSData *imageData = [[NSData alloc] initWithContentsOfURL:dataURL];
            
            //Write the data to disk
            theError = nil;
            
            if([imageData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) 
                NSLog(@"EAD.updateContent: failed to write local file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
            
            else NSLog(@"EAD.updateContent: Wrote image to %@", theFilePath);
			
			if (![Props global].deviceShowsHighResIcons) {
				NSString *theFilePath = [NSString stringWithFormat:@"%@/images/%i-icon.jpg", [Props global].contentFolder, [missingImage intValue]];
				
				NSString *urlString = [[NSString stringWithFormat: @"http:/%@/published/dynamic-photos/height/45/%i.jpg", [Props global].serverContentSource, [missingImage intValue]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSURL *dataURL = [[NSURL alloc] initWithString: urlString];
				
				//Get the data
				NSData *imageData = [[NSData alloc] initWithContentsOfURL:dataURL];
				
				//Write the data to disk
				theError = nil;
				
				if([imageData writeToFile: theFilePath  options:NSAtomicWrite error:&theError]!= TRUE) 
					NSLog(@"EAD.updateContent: failed to write local file to %@, error = %@, userInfo = %@", theFilePath, theError, [theError userInfo]);
				
				else NSLog(@"EAD.updateContent: Wrote image to %@", theFilePath);

			}
            
            //Clean up
        }
        
        NSLog(@"EAD.updateContent: Missing icons downloaded in %0.2f seconds", -[date timeIntervalSinceNow]);
        
        //******************* Update the Photos table to correctly show what images are present ***********************
        //This is used for correctly setting up the slideshow
        
        NSDate *dbUpdateTimer = [NSDate date];
        
        //Update x100px images
        if (!cancel) {
            NSMutableString *downloadedPhotoList = [[NSMutableString alloc] initWithString:@""];
            
            @synchronized([Props global].dbSync) {
                
                NSString *query = @"SELECT rowid from photos WHERE downloaded_x100px_photo is null LIMIT 3000";
                
                FMResultSet * rs = [db executeQuery:query];
                
                if ([db hadError]) NSLog(@"sqlite error in EAD.updateContent, query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
                
                if (![rs next]) NSLog(@"EAD.updateContent - no rows in result set");
                
                while ([rs next]) {
                    
                    int imageId = [rs intForColumn:@"rowid"];
                    NSString *fileName = [NSString stringWithFormat:@"%i_x100", imageId];
                    NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%@.jpg", [Props global].contentFolder, fileName];
                    
                    //NSLog(@"About to look for file at %@", theFilePath);
                    
                    if([[NSFileManager defaultManager] fileExistsAtPath: theFilePath] || [[NSFileManager defaultManager] fileExistsAtPath: [[NSBundle mainBundle] pathForResource:fileName ofType:@"jpg"]]) 
                        [downloadedPhotoList appendString:[NSString stringWithFormat:@"%i,", imageId]];
                    
                }
                
                [rs close];
            }
            
            @synchronized([Props global].dbSync) {
                
                //NSLog(@"DATADOWNLOADER.updatePhotoStatuses: Downloaded photos ids has about %i objects", [downloadedPhotoList length]/7);
                
                if ([downloadedPhotoList length] > 0) {
                    
                    //NSLog(@"DOWNLOADER.updatePhotoStuatuses: updating datebase for %i new photos", [downloadedPhotoList length]/7);
                    
                    [downloadedPhotoList deleteCharactersInRange:NSMakeRange([downloadedPhotoList length] - 1, 1)];
                    
                    //NSLog(@"Downloaded photo list = %@", downloadedPhotoList);
                    
                    NSString *query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_x100px_photo = 1 WHERE rowid IN (%@)", downloadedPhotoList];
                    
                    //NSLog(@"Query = %@", query);
                    [db executeUpdate:@"BEGIN TRANSACTION"];
                    [db executeUpdate:query];
                    [db executeUpdate:@"END TRANSACTION"];
                }
            }
        }
        
        NSLog(@"OPENINGVIEW.updateContent: Took %0.2f seconds to update 100 px images", -[dbUpdateTimer timeIntervalSinceNow]);
        
        //Update 320px images
        if (!cancel) {
            NSMutableString *downloadedPhotoList = [[NSMutableString alloc] initWithString:@""];
            
            @synchronized([Props global].dbSync) {
                
                NSString *query = @"SELECT rowid from photos WHERE downloaded_320px_photo is null LIMIT 3000";
                
                FMResultSet * rs = [db executeQuery:query];
                
                if ([db hadError]) NSLog(@"sqlite error in EAD.updateContent, query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
                
                if (![rs next]) NSLog(@"EAD.updateContent - no rows in result set");
                
                while ([rs next]) {
                    
                    int imageId = [rs intForColumn:@"rowid"];
                    NSString *fileName = [NSString stringWithFormat:@"%i", imageId];
                    NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%@.jpg", [Props global].contentFolder, fileName];
                    
                    //NSLog(@"About to look for file at %@", theFilePath);
                    
                    if([[NSFileManager defaultManager] fileExistsAtPath: theFilePath] || [[NSFileManager defaultManager] fileExistsAtPath: [[NSBundle mainBundle] pathForResource:fileName ofType:@"jpg"]])
                        [downloadedPhotoList appendString:[NSString stringWithFormat:@"%i,", imageId]];
                    
                }
                
                [rs close];
            }
            
            @synchronized([Props global].dbSync) {
                
                //NSLog(@"DATADOWNLOADER.updatePhotoStatuses: Downloaded photos ids has about %i objects", [downloadedPhotoList length]/7);
                
                if ([downloadedPhotoList length] > 0) {
                    
                    //NSLog(@"DOWNLOADER.updatePhotoStuatuses: updating datebase for %i new photos", [downloadedPhotoList length]/7);
                    
                    [downloadedPhotoList deleteCharactersInRange:NSMakeRange([downloadedPhotoList length] - 1, 1)];
                    
                    //NSLog(@"Downloaded photo list = %@", downloadedPhotoList);
                    
                    NSString *query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_320px_photo = 1 WHERE rowid IN (%@)", downloadedPhotoList];
                    
                    //NSLog(@"Query = %@", query);
                    [db executeUpdate:@"BEGIN TRANSACTION"];
                    [db executeUpdate:query];
                    [db executeUpdate:@"END TRANSACTION"];
                }
            }
        }
        
         NSLog(@"OPENINGVIEW.updateContent: Took %0.2f seconds to update 320 px images", -[dbUpdateTimer timeIntervalSinceNow]);
        
        //Update 768px images
        if (!cancel) {
            NSMutableString *downloadedPhotoList = [[NSMutableString alloc] initWithString:@""];
            
            @synchronized([Props global].dbSync) {
                
                NSString *query = @"SELECT rowid from photos WHERE downloaded_768px_photo is null LIMIT 3000";
                
                FMResultSet * rs = [db executeQuery:query];
                
                if ([db hadError]) NSLog(@"sqlite error in EAD.updateContent, query = %@, %d: %@", query, [db lastErrorCode], [db lastErrorMessage]);
                
                if (![rs next]) NSLog(@"EAD.updateContent - no rows in result set");
                
                while ([rs next]) {
                    
                    int imageId = [rs intForColumn:@"rowid"];
                    NSString *fileName = [NSString stringWithFormat:@"%i", imageId];
                    NSString *theFilePath = [[NSString alloc] initWithFormat:@"%@/images/%@.jpg", [Props global].contentFolder, fileName];
                    
                    //NSLog(@"About to look for file at %@", theFilePath);
                    
                    if([[NSFileManager defaultManager] fileExistsAtPath: theFilePath] || [[NSFileManager defaultManager] fileExistsAtPath: [[NSBundle mainBundle] pathForResource:fileName ofType:@"jpg"]])
                        [downloadedPhotoList appendString:[NSString stringWithFormat:@"%i,", imageId]];
                    
                }
                
                [rs close];
            }
            
            @synchronized([Props global].dbSync) {
                
                //NSLog(@"DATADOWNLOADER.updatePhotoStatuses: Downloaded photos ids has about %i objects", [downloadedPhotoList length]/7);
                
                if ([downloadedPhotoList length] > 0) {
                    
                    //NSLog(@"DOWNLOADER.updatePhotoStuatuses: updating datebase for %i new photos", [downloadedPhotoList length]/7);
                    
                    [downloadedPhotoList deleteCharactersInRange:NSMakeRange([downloadedPhotoList length] - 1, 1)];
                    
                    //NSLog(@"Downloaded photo list = %@", downloadedPhotoList);
                    
                    NSString *query = [NSString stringWithFormat:@"UPDATE photos SET downloaded_768px_photo = 1 WHERE rowid IN (%@)", downloadedPhotoList];
                    
                    //NSLog(@"Query = %@", query);
                    [db executeUpdate:@"BEGIN TRANSACTION"];
                    [db executeUpdate:query];
                    [db executeUpdate:@"END TRANSACTION"];
                }
            }
        }
        
         NSLog(@"OPENINGVIEW.updateContent: Took %0.2f seconds to update 768 px images", -[dbUpdateTimer timeIntervalSinceNow]);
            
        [db close];
        
        
        if (cancel) return;
        
        NSString *theFilePath= [NSString stringWithFormat:@"%@/content.sqlite3", [Props global].cacheFolder];
        
        @synchronized ([Props global].dbSync) {
            
            [[NSFileManager defaultManager] removeItemAtPath:theFilePath error:nil];
            [[NSFileManager defaultManager] moveItemAtPath:unzippedFilePath toPath: theFilePath error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:unzippedFilePath error:nil];
            
            //Order of these operations is important
            [EntryCollection resetContent];
            [[Props global] setupPropsDictionary];
            [[EntryCollection sharedEntryCollection] initialize];
            [[FilterPicker sharedFilterPicker] initialize];
            
            if ([Props global].hasLocations) [[MapViewController sharedMVC] reset]; //This needs to be after setting up props dictionary, as calling this for the first time before setting the app id causes problems
            
            [Props global].dataDownloaderShouldCheckForUpdates = TRUE;
            
            //Reset bool keeping track of thumbnail download, as we'll need to download again to get the latest
            //If the app is just starting, the guidedownloader won't have been created yet, but the guidedownloader init will get the thumbnails
            //If the guide is being reopened from the background, then the guidedownloader object should get the ContentUpdated notification
            NSString *thumbnailKeyString = [NSString stringWithFormat:@"%@_%i", kThumbnailsDownloaded, [Props global].appID];
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:thumbnailKeyString];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kContentUpdated object:nil];
        }
        
        NSLog(@"EAD.updateContent: Current bundle verion = %i", [Props global].bundleVersion);
        NSLog(@"EAD.updateContent: Database updated with latest images, %0.2f", -[date timeIntervalSinceNow]);
    
    }
}


- (void) hide {
    
    [Props global].contentUpdateInProgress = FALSE;
    
    [self removeFromSuperview];
}


@end
