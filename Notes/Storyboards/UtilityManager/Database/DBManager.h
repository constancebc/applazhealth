//
//  DBManager.h
//  TruckInspection
//
//  Created by Apple1 on 3/26/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <UIKit/UIKit.h>
//#import <WatchKit/WatchKit.h>
#import <sys/utsname.h>


@interface DBManager : NSObject
{
    
}

+(id)sharedManager;
-(void)createEditableCopyOfSQLIteIfNeeded;
-(NSString *)getDBPath;
-(NSMutableArray *)getResultForSQLQuery:(NSString *)strSQLQuery;
-(BOOL)executeSQLQuery:(NSString *)strSQLQuery;

-(BOOL)deleteNotes:(NSString *)strCategoryID;
-(BOOL)addNote:(NSString *)strNoteCateory;
-(BOOL)addNote:(NSString *)strNoteTitle strNoteCategory:(NSString *)strNoteCategory strNoteDescription:(NSString *)strNoteDescription;

-(BOOL)deleteRecord:(NSString *)strNoteID;
-(BOOL)deleteNoteCategory:(NSString *)strNoteCategory;
-(BOOL)deleteNote:(NSString *)strNoteID;

-(BOOL)updateNote:(NSString *)strQuery;

-(BOOL)updateNoteCategory:(NSString *)strChangedNoteCategory strNoteCategory:(NSString *)strNoteCategory strNoteID:(NSString *)strNoteID;
-(BOOL)updateNote:(NSString *)strChangedNoteCategory strNoteTitle:(NSString *)strNoteTitle strNoteDescription:(NSString *)strNoteDescription strNoteID:(NSString *)strNoteID;
-(BOOL)updateNote:(NSString *)strChangedNoteCategory strNoteCategory:(NSString *)strNoteCategory;

-(BOOL)updatepasscode:(NSString *)strLoginNewPasscode strLoginOLDPasscode:(NSString *)strLoginOLDPasscode;
-(BOOL)removePasscode:(NSString *)strPasscode;

-(BOOL)updateNoteCategory:(NSString *)strQuery;
-(BOOL)isiWatch;

-(BOOL)setPasscode:(NSString *)strPasscode;

@end

