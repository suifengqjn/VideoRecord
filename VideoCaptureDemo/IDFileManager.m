//
//  IDFileManager.m
//  VideoCaptureDemo
//
//  Created by Adriaan Stellingwerff on 9/04/2015.
//  Copyright (c) 2015 Infoding. All rights reserved.
//

#import "IDFileManager.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation IDFileManager


- (NSURL *)tempFileURL
{
    NSString *path = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSInteger i = 0;
    while(path == nil || [fm fileExistsAtPath:path]){
        path = [NSString stringWithFormat:@"%@output%ld.mov", NSTemporaryDirectory(), (long)i];
        i++;
    }
    return [NSURL fileURLWithPath:path];
}

- (void) removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        [fileManager removeItemAtPath:filePath error:&error];
        if(error){
            NSLog(@"error removing file: %@", [error localizedDescription]);
        }
    }
}

- (void) copyFileToDocuments:(NSURL *)fileURL
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    NSString *destinationPath = [documentsDirectory stringByAppendingFormat:@"/output_%@.mov", [dateFormatter stringFromDate:[NSDate date]]];
    NSError	*error;
    [[NSFileManager defaultManager] copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:destinationPath] error:&error];
    if(error){
        NSLog(@"error copying file: %@", [error localizedDescription]);
    }
}

- (void)copyFileToCameraRoll:(NSURL *)fileURL
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if(![library videoAtPathIsCompatibleWithSavedPhotosAlbum:fileURL]){
        NSLog(@"video incompatible with camera roll");
    }
    [library writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        
        if(error){
            NSLog(@"Error: Domain = %@, Code = %@", [error domain], [error localizedDescription]);
        } else if(assetURL == nil){
            
            //It's possible for writing to camera roll to fail, without receiving an error message, but assetURL will be nil
            //Happens when disk is (almost) full
            NSLog(@"Error saving to camera roll: no error message, but no url returned");
            
        } else {
            //remove temp file
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
            if(error){
                NSLog(@"error: %@", [error localizedDescription]);
            }
            
        }
    }];

}


@end
