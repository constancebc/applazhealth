//
//  DBManager.m
//  TruckInspection
//
//  Created by Apple1 on 3/26/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "DBManager.h"


#define kAppDBName  @"notes.sqlite"
#define kiWatchAppDBName  @"notesDatabase.sqlite"
#define DEG2RAD(degrees) (degrees * 0.01745327)

@implementation DBManager

+(id)sharedManager
{
    static DBManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init {
    if (self = [super init]) { }
    return self;
}

-(void)createEditableCopyOfSQLIteIfNeeded
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *dbPath = [self getDBPath];
    NSLog(@"the datapath:%@",dbPath);
    BOOL success = [fileManager fileExistsAtPath:dbPath];
    
    if(!success)
    {
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: self.databseName];
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        
        if (!success)
        {
            NSAssert1(0, @"Failed to create writable plist file with message '%@'.", [error localizedDescription]);
        }
    }
}


-(NSString *)extDBPath{
    
    NSURL *strurl = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.watchnotes"];
    NSURL *dataBaseURL = [strurl  URLByAppendingPathComponent: self.databseName];
 
    return [dataBaseURL absoluteString];
 }


-(NSString *)getDBPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    
    NSLog(@"%@", self.databseName);
    
    return [documentsDir stringByAppendingPathComponent: self.databseName];
}


-(NSMutableArray *)getResultForSQLQuery:(NSString *)strSQLQuery
{
    NSLog(@"The QUERY:%@",strSQLQuery);
    NSMutableArray *arrResult=[[NSMutableArray alloc]init];
    sqlite3 *database;
    
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK)
    {
        const char *sqlStatement = [strSQLQuery UTF8String];
        
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK)
        {
            while(sqlite3_step(compiledStatement) == SQLITE_ROW)
            {
                NSMutableDictionary *dictResult=[NSMutableDictionary dictionaryWithCapacity:(sqlite3_column_count(compiledStatement)+1)];
                
                for (int i=0;i<sqlite3_column_count(compiledStatement);i++) {
                
                    id result;
                    
                    if(sqlite3_column_type(compiledStatement,i)==SQLITE_TEXT) {
                        
                        result=[NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement,i)];
                    }
                    else if(sqlite3_column_type(compiledStatement,i) == SQLITE_INTEGER) {
                        
                        result = [NSNumber numberWithInt:(int)sqlite3_column_int(compiledStatement,i)];
                    }
                    else if(sqlite3_column_type(compiledStatement,i) == SQLITE_FLOAT) {
                        
                        result = [NSNumber numberWithFloat:(float)sqlite3_column_double(compiledStatement,i)];
                    }
                    else if(sqlite3_column_type(compiledStatement,i) == SQLITE_BLOB) {
                        
                        result = [UIImage imageWithData:[NSData dataWithBytes:sqlite3_column_blob(compiledStatement,i) length:sqlite3_column_bytes(compiledStatement,i)]];
                    }
                    else if(sqlite3_column_type(compiledStatement,i) == SQLITE_NULL) {
                        
                        result=[NSString stringWithFormat:@" "];
                    }
                    else {
                        const unsigned char *tempresult = sqlite3_column_text(compiledStatement, i);
                        
                        if(tempresult==NULL) {
                            result=@"";
                        }
                        else {
                            result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledStatement,i)];
                        }
                    }
                    if(result) {
                       [dictResult setObject:result forKey:[NSString stringWithUTF8String:sqlite3_column_name(compiledStatement,i)]];
                    }
                }
                [arrResult addObject:dictResult];
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
        }
        sqlite3_finalize(compiledStatement);
    }
    sqlite3_close(database);
    return arrResult;
}

-(BOOL)executeSQLQuery:(NSString *)strSQLQuery
{
    NSLog(@"The SQL Query:%@",strSQLQuery);
    sqlite3 *database;
    BOOL isSucess=NO;
    
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK)
    {
        const char *sqlStatement = [strSQLQuery UTF8String];
        
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK)
        {
            isSucess=YES;
        }
        else
        {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    
    return isSucess;
}


-(BOOL)addNote:(NSString *)strNoteCateory {
 
    sqlite3 *database;
    BOOL isSucess=NO;

    if(sqlite3_open_v2([[self getDBPath] UTF8String], &database, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
//    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK)
    {
        NSString *sqlStr = [NSString stringWithFormat:@"insert into notescategory ('cateoryname') VALUES (?)"];
        const char *sqlStatement = [sqlStr UTF8String];

        sqlite3_stmt *compiledStatement;

        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {

            sqlite3_bind_text(compiledStatement,1,[strNoteCateory UTF8String],-1,SQLITE_TRANSIENT);

            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    
    return isSucess;
}

-(BOOL)addNote:(NSString *)strNoteTitle strNoteCategory:(NSString *)strNoteCategory strNoteDescription:(NSString *)strNoteDescription {
    
    sqlite3 *database;
    BOOL isSucess=NO;

    if(sqlite3_open_v2([[self getDBPath] UTF8String], &database, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK) {
//    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK) {
        NSString *sqlStr = [NSString stringWithFormat:@"insert into notes (notetitle,notedescription,notecateory) VALUES (?,?,?)"];
        const char *sqlStatement = [sqlStr UTF8String];
        
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {
            sqlite3_bind_text(compiledStatement,1,[strNoteTitle UTF8String],-1,SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement,2,[strNoteDescription UTF8String],-1,SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement,3,[strNoteCategory UTF8String],-1,SQLITE_TRANSIENT);

            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    
    return isSucess;
}



-(BOOL)deleteNoteCategory:(NSString *)strNoteCategory {
    
    
    sqlite3 *database;
    BOOL isSucess=NO;
    
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK) {
        
        NSString *sqlStr = [NSString stringWithFormat:@"delete from notes WHERE notecateory=?"];
        const char *sqlStatement = [sqlStr UTF8String];
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {
            
            sqlite3_bind_text(compiledStatement,1,[strNoteCategory UTF8String],-1,SQLITE_TRANSIENT);
            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    return isSucess;
}


-(BOOL)deleteNote:(NSString *)strNoteID {
    
    
    sqlite3 *database;
    BOOL isSucess=NO;
    
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK) {
        
        NSString *sqlStr = [NSString stringWithFormat:@"delete from notes WHERE id=?"];
        const char *sqlStatement = [sqlStr UTF8String];
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {
            
            sqlite3_bind_text(compiledStatement,1,[strNoteID UTF8String],-1,SQLITE_TRANSIENT);
            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    return isSucess;
}


-(BOOL)deleteNotes:(NSString *)strCategoryID {
    
    
    sqlite3 *database;
    BOOL isSucess=NO;
    
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK) {
        
        NSString *sqlStr = [NSString stringWithFormat:@"delete from notes WHERE notecateory=?"];
        const char *sqlStatement = [sqlStr UTF8String];
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {
            
            sqlite3_bind_text(compiledStatement,1,[strCategoryID UTF8String],-1,SQLITE_TRANSIENT);
            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    return isSucess;
}


-(BOOL)deleteRecord:(NSString *)strNoteID {

    
    sqlite3 *database;
    BOOL isSucess=NO;
    
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK) {
        
        NSString *sqlStr = [NSString stringWithFormat:@"delete from notescategory WHERE id=?"];
        const char *sqlStatement = [sqlStr UTF8String];
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {
            
            sqlite3_bind_text(compiledStatement,1,[strNoteID UTF8String],-1,SQLITE_TRANSIENT);
            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    return isSucess;
}

-(BOOL)updateNoteCategory:(NSString *)strChangedNoteCategory strNoteCategory:(NSString *)strNoteCategory strNoteID:(NSString *)strNoteID {
    
    sqlite3 *database;
    BOOL isSucess=NO;
        
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK) {
        
        NSString *sqlStr = [NSString stringWithFormat:@"UPDATE notescategory SET cateoryname=? WHERE id=?"];
        const char *sqlStatement = [sqlStr UTF8String];
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {
            
            sqlite3_bind_text(compiledStatement,1,[strChangedNoteCategory UTF8String],-1,SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement,2,[strNoteID UTF8String],-1,SQLITE_TRANSIENT);
            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
//                [self updateNote:strChangedNoteCategory strNoteCategory:strNoteCategory];
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    return isSucess;
}


-(BOOL)updateNote:(NSString *)strChangedNoteCategory strNoteTitle:(NSString *)strNoteTitle strNoteDescription:(NSString *)strNoteDescription strNoteID:(NSString *)strNoteID {
    
    sqlite3 *database;
    BOOL isSucess=NO;
    
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK) {
        
        NSString *sqlStr = [NSString stringWithFormat:@"UPDATE notes SET notetitle=?,notedescription=?,notecateory=? WHERE id=?"];
        const char *sqlStatement = [sqlStr UTF8String];
        sqlite3_stmt *compiledStatement;

        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {
            
            sqlite3_bind_text(compiledStatement,1,[strNoteTitle UTF8String],-1,SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement,2,[strNoteDescription UTF8String],-1,SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement,3,[strChangedNoteCategory UTF8String],-1,SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement,4,[strNoteID UTF8String],-1,SQLITE_TRANSIENT);

            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    return isSucess;
}


-(BOOL)updateNote:(NSString *)strChangedNoteCategory strNoteCategory:(NSString *)strNoteCategory {
    
    sqlite3 *database;
    BOOL isSucess=NO;
    
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK) {
        
        NSString *sqlStr = [NSString stringWithFormat:@"UPDATE notes SET notecateory=? WHERE notecateory=?"];
        const char *sqlStatement = [sqlStr UTF8String];
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK)
        {
            sqlite3_bind_text(compiledStatement,1,[strChangedNoteCategory UTF8String],-1,SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement,2,[strNoteCategory UTF8String],-1,SQLITE_TRANSIENT);
            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    
    
    return isSucess;
}


-(NSString *)databseName {
    //    return self.isiWatch ? kiWatchAppDBName : kAppDBName;
    return kAppDBName;
}

/*
-(BOOL)isiWatch {
    

    NSString *strModel = [WKInterfaceDevice currentDevice].model;
    if ([strModel isEqualToString:@"Apple Watch"]) {
        return YES;
    } else {
        return NO;
    }
}
*/

-(BOOL)setPasscode:(NSString *)strPasscode {
    
    sqlite3 *database;
    BOOL isSucess=NO;
    
    if(sqlite3_open_v2([[self getDBPath] UTF8String], &database, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        NSString *sqlStr = [NSString stringWithFormat:@"insert into login ('passcode') VALUES (?)"];
        const char *sqlStatement = [sqlStr UTF8String];
        
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {
            
            sqlite3_bind_text(compiledStatement,1,[strPasscode UTF8String],-1,SQLITE_TRANSIENT);
            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    
    return isSucess;
}


-(BOOL)updatepasscode:(NSString *)strLoginNewPasscode strLoginOLDPasscode:(NSString *)strLoginOLDPasscode {

    sqlite3 *database;
    BOOL isSucess=NO;
    
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK) {
        
        NSString *sqlStr = [NSString stringWithFormat:@"UPDATE login SET passcode=? WHERE passcode=?"];
        const char *sqlStatement = [sqlStr UTF8String];
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {
            
            sqlite3_bind_text(compiledStatement,1,[strLoginNewPasscode UTF8String],-1,SQLITE_TRANSIENT);
            sqlite3_bind_text(compiledStatement,2,[strLoginOLDPasscode UTF8String],-1,SQLITE_TRANSIENT);
            
            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    return isSucess;
}


-(BOOL)removePasscode:(NSString *)strPasscode {
    
    sqlite3 *database;
    BOOL isSucess=NO;
    
    if(sqlite3_open([[self getDBPath] UTF8String],&database) == SQLITE_OK) {
        
        NSString *sqlStr = [NSString stringWithFormat:@"delete from login WHERE passcode=?"];
        const char *sqlStatement = [sqlStr UTF8String];
        sqlite3_stmt *compiledStatement;
        
        if(sqlite3_prepare_v2(database,sqlStatement,-1,&compiledStatement,NULL)==SQLITE_OK) {
            
            sqlite3_bind_text(compiledStatement,1,[strPasscode UTF8String],-1,SQLITE_TRANSIENT);
            
            while(sqlite3_step(compiledStatement) == SQLITE_DONE) {
                isSucess=YES;
            }
        } else {
            NSLog(@"Error : %s",sqlite3_errmsg(database));
            sqlite3_finalize(compiledStatement);
            isSucess=NO;
        }
    }
    sqlite3_close(database);
    return isSucess;
}



@end
