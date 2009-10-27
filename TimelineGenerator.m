#import <Foundation/Foundation.h>
#import <sqlite3.h>

NSMutableString *HTMLTimelineForDatabase(const char *database)
{
  sqlite3 *db;
  int rc;
  char *sql;
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
   "</style>"
   ];
  
  sql = "SELECT name, value from config";
  
  rc = sqlite3_prepare_v2(db, sql, -1, &st, 0);
  if (rc != SQLITE_OK) {
    fprintf(stderr, "QLFossil: SQL error");
    goto out;
  }
  
  if (rc != SQLITE_OK) {
    fprintf(stderr, "QLFossil: SQL error");
    goto out;
  }
  
  [html appendString:@"<div class=info>"];
  
  while (sqlite3_step(st) == SQLITE_ROW) {
    key = (char *)sqlite3_column_text(st, 0);
    value = (char *)sqlite3_column_text(st, 1);
    if (key && value && 
        (strstr(key, "project-name") == key ||
         strstr(key, "project-description") == key /*||
                                                    strstr(key, "last-sync-url") == key*/)) {
                                                      [html appendFormat:@"<div class='%s'>%s</div>", key, value];
                                                    }
  }
  sqlite3_finalize(st);
  
  [html appendString:@"</div>"];
  
  sql = "SELECT bgcolor, type, datetime(mtime,'localtime') AS timestamp, "
  "substr(uuid,0,10) AS uuid, comment, user FROM event "
  "JOIN blob where blob.rid = event.objid "
  "ORDER BY mtime DESC limit 20";
  
  rc = sqlite3_prepare_v2(db, sql, -1, &st, 0);
  
  BOOL isOdd = NO;
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
  }
  
  //printf("%s", [html UTF8String]);
  
  sqlite3_finalize(st);
  
  out:
  sqlite3_close(db);
  return html;
}  
