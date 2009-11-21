#import <Foundation/Foundation.h>
#import <sqlite3.h>

NSMutableString *HTMLTimelineForDatabase(const char *database, int limit)
{
  sqlite3 *db;
  int rc;
  const char *sql;
  sqlite3_stmt *st;
  const char *key, *value;
  
  NSMutableString *html = [[[NSMutableString alloc] init] autorelease];
  
  rc = sqlite3_open(database, &db);
  if (rc) {
    fprintf(stderr, "QLFossil: Can't open database: %s\n", sqlite3_errmsg(db));
    goto out;
  }
  
  [html appendString:
   @"<style>"
   "body { background: #fff; color: #111; font: 12px Helvetica; margin: 0 } "
   ".info { padding: 10px; color: #333; background: #D6D6D6 "
   " -webkit-gradient(linear, left top, left bottom, from(#fff), to(#ccc)); "
   "        border-bottom: 1px solid #aaa; text-shadow: 0 1px #f4f4f4 } "
   ".project-name { font-size: 20px } "
   ".event { padding: 10px } "
   ".time { display:block; color: #666; font-size: 11px; margin-bottom: 3px }"
   ".uuid { -webkit-border-radius: 5px; font-family: monospace; "
   "         color: #555; background: #fff; padding: 0 5px } "
   ".ci .uuid { background: #CCF } "
   ".t .uuid { background: #CF6 } "
   ".w .uuid { background: #FC6 } "
   ".comment { margin-left: 5px } "
   ".user { color: #777; background: #f4f4f4; "
   "        font-style: oblique; padding: 0 5px } "
   ".odd { background: #E9F0FC } "
   ".count { padding: 10px; color: #777 } "
   "</style>"
   ];
  
  sql = "SELECT name, value from config";
  
  rc = sqlite3_prepare_v2(db, sql, -1, &st, 0);
  if (rc != SQLITE_OK) {
    fprintf(stderr, "QLFossil: SQL error (1)");
    goto out;
  }
  
  [html appendString:@"<div class=info>"];
  
  NSString *projectName = @"", 
           *projectDescription = @"", 
           *lastSyncURL = @"";
 
  while (sqlite3_step(st) == SQLITE_ROW) {
    key = (char *)sqlite3_column_text(st, 0);
    value = (char *)sqlite3_column_text(st, 1);
    if (key && value) {
      if (strcmp(key, "project-name") == 0) {
        projectName = [NSString stringWithUTF8String:value];
      } else if (strcmp(key, "project-description") == 0) {
        projectDescription = [NSString stringWithUTF8String:value];
      } else if (strcmp(key, "last-sync-url") == 0) {
        // remove username/password http://username:password@example.com
        NSMutableString *url = [NSMutableString stringWithUTF8String:value];
        NSString *protocol = @"";
        if ([url hasPrefix:@"https://"]) {
          protocol = @"https://";
        } else if ([url hasPrefix:@"http://"]) {
          protocol = @"http://";
        }
        if ([protocol length] > 0) {
          NSRange r = [url rangeOfString:@"@"];
          if (r.location != NSNotFound) {
            [url deleteCharactersInRange:NSMakeRange(0, r.location+r.length)];
          } else {
            [url deleteCharactersInRange:NSMakeRange(0, [protocol length])];  
          }
        }
        lastSyncURL = [NSString stringWithFormat:@"%@%@", protocol, url];
      }
    }
  }
  sqlite3_finalize(st);
  
  [html appendFormat:@"<div class='project-name'>%@</div>\n"
                      "<div class='project-description'>%@</div>\n"
                      "<div class='last-sync-url'><a href='%@'>%@</a></div>\n", 
                      projectName, 
                      projectDescription,
                      lastSyncURL, lastSyncURL];
  [html appendString:@"</div>"];
  
  sql = [[NSString stringWithFormat:
         @"SELECT bgcolor, type, datetime(mtime,'localtime') AS timestamp, "
          "substr(uuid,0,10) AS uuid, comment, user FROM event "
          "JOIN blob where blob.rid = event.objid "
          "ORDER BY mtime DESC limit %d", limit] UTF8String];

  rc = sqlite3_prepare_v2(db, sql, -1, &st, 0);
  if (rc != SQLITE_OK) {
    fprintf(stderr, "QLFossil: SQL error (2)");
    goto out;
  }

  BOOL isOdd = NO;
  uint64 num = 0;
  while (sqlite3_step(st) == SQLITE_ROW) {
    // 0 - bgcolor
    [html appendString:@"<div "];
    value = (char *)sqlite3_column_text(st, 0);
    if (value)
      [html appendFormat:@" style='background: %s' ", value];
    // 1 - type
    [html appendString:@"class='event"];
    value = (char *)sqlite3_column_text(st, 1);
    if (value)
      [html appendFormat:@" %s", value];
    if (isOdd)
      [html appendString:@" odd"];    
    [html appendString:@"'>\n"];    
    // 2 - timestamp
    value = (char *)sqlite3_column_text(st, 2);
    if (value)
      [html appendFormat:@"<span class=time>%s</span>\n", value];
    // 3 - uuid
    value = (char *)sqlite3_column_text(st, 3);
    if (value)
      [html appendFormat:@"<span class=uuid>%s</span>\n", value];    
    // 4 - comment
    value = (char *)sqlite3_column_text(st, 4);
    if (value)
      [html appendFormat:@"<span class=comment>%s</span>\n", value];    
    // 5 - user
    value = (char *)sqlite3_column_text(st, 5);
    if (value)
      [html appendFormat:@"<span class=user>%s</span>\n", value];
    [html appendString:@"</div>\n\n"];
    isOdd = !isOdd;
    num++;
  }
    
  sqlite3_finalize(st);
  
  
  sql = "SELECT count(*) FROM event";
  
  rc = sqlite3_prepare_v2(db, sql, -1, &st, 0);
  if (rc != SQLITE_OK) {
    fprintf(stderr, "QLFossil: SQL error (1)");
    goto out;
  }
  
  while (sqlite3_step(st) == SQLITE_ROW) {
    uint64 count = sqlite3_column_int64(st, 0);
    [html appendFormat:@"<div class='count'>Showed %d of %d events.</div>",
      num, count];
  }
  sqlite3_finalize(st);
  
  out:
  sqlite3_close(db);
  return html;
}  
