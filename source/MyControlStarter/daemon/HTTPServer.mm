#import "HTTPServer.h"
#import "ScriptRunner.h"
#import "FileStore.h"
#import "ScreenCapture.h"
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>
#include <string.h>

@interface HTTPServer ()
@property(nonatomic) uint16_t port;
@property(nonatomic, copy) NSString *pairingToken;
@property(nonatomic, strong) ScreenCapture *screenCapture;
@end

@implementation HTTPServer

- (instancetype)initWithPort:(uint16_t)port {
    if ((self=[super init])) {
        _port=port;
        _pairingToken=[self loadOrCreatePairingToken];
        _screenCapture=[ScreenCapture new];
    }
    return self;
}

static NSString *jsonString(id obj){NSData*d=[NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];return [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding]?:@"{}";}
static NSString *urlDecode(NSString*s){return [s stringByRemovingPercentEncoding]?:s;}
static NSDictionary *parseQuery(NSString*q){NSMutableDictionary*m=[NSMutableDictionary dictionary];for(NSString*p in[q componentsSeparatedByString:@"&"]){NSRange e=[p rangeOfString:@"="];if(e.location==NSNotFound){if(p.length)m[urlDecode(p)]=@"";}else m[urlDecode([p substringToIndex:e.location])]=urlDecode([p substringFromIndex:e.location+1]);}return m;}
static NSDictionary *parseHeaders(NSArray<NSString*>*lines){NSMutableDictionary*h=[NSMutableDictionary dictionary];for(NSUInteger i=1;i<lines.count;i++){NSString*l=lines[i];if(!l.length)break;NSRange c=[l rangeOfString:@":"];if(c.location==NSNotFound)continue;NSString*k=[[[l substringToIndex:c.location]stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]lowercaseString];NSString*v=[[l substringFromIndex:c.location+1]stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];h[k]=v;}return h;}
- (NSString*)tokenPath{return [[FileStore baseDirectory]stringByAppendingPathComponent:@"token.txt"];}
- (NSString*)loadOrCreatePairingToken{[FileStore ensureDirectories];NSString*p=[self tokenPath];NSString*e=[[NSString stringWithContentsOfFile:p encoding:NSUTF8StringEncoding error:nil]stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];if(e.length>=16)return e;NSString*t=[[[NSUUID UUID].UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""]lowercaseString];[t writeToFile:p atomically:YES encoding:NSUTF8StringEncoding error:nil];chmod(p.fileSystemRepresentation,0644);return t;}
- (BOOL)isAuthorized:(NSDictionary*)headers query:(NSDictionary*)query{NSString*p=headers[@"x-mycontrol-token"]?:query[@"token"]?:@"";return p.length&&[p isEqualToString:self.pairingToken];}
- (NSData*)indexHTML{NSString*p=[[FileStore webDirectory]stringByAppendingPathComponent:@"index.html"];NSData*d=[NSData dataWithContentsOfFile:p];return d?:[@"<html><body><h1>MyControl</h1></body></html>" dataUsingEncoding:NSUTF8StringEncoding];}
- (void)sendResponse:(int)fd status:(NSString*)status type:(NSString*)type body:(NSData*)body{NSString*h=[NSString stringWithFormat:@"HTTP/1.1 %@\r\nContent-Type: %@\r\nContent-Length: %lu\r\nConnection: close\r\nCache-Control: no-store\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Headers: Content-Type, X-MyControl-Token\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\n\r\n",status,type,(unsigned long)body.length];NSData*hd=[h dataUsingEncoding:NSUTF8StringEncoding];send(fd,hd.bytes,hd.length,0);if(body.length)send(fd,body.bytes,body.length,0);}
- (void)sendJSON:(int)fd status:(NSString*)status object:(NSDictionary*)object{[self sendResponse:fd status:status type:@"application/json" body:[jsonString(object)dataUsingEncoding:NSUTF8StringEncoding]];}

- (void)handleClient:(int)fd {
    NSMutableData*req=[NSMutableData data];uint8_t buf[4096];ssize_t n;NSInteger contentLength=0;
    while((n=recv(fd,buf,sizeof(buf),0))>0){[req appendBytes:buf length:(NSUInteger)n];NSString*tmp=[[NSString alloc]initWithData:req encoding:NSUTF8StringEncoding];if(!tmp)continue;NSRange he=[tmp rangeOfString:@"\r\n\r\n"];if(he.location!=NSNotFound){NSRegularExpression*re=[NSRegularExpression regularExpressionWithPattern:@"Content-Length:\\s*(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil];NSTextCheckingResult*m=[re firstMatchInString:tmp options:0 range:NSMakeRange(0,he.location)];if(m.numberOfRanges>1)contentLength=[[tmp substringWithRange:[m rangeAtIndex:1]]integerValue];if(req.length>=he.location+he.length+(NSUInteger)contentLength)break;}}
    NSString*raw=[[NSString alloc]initWithData:req encoding:NSUTF8StringEncoding]?:@"";NSArray*lines=[raw componentsSeparatedByString:@"\r\n"];NSArray*parts=[(lines.firstObject?:@"")componentsSeparatedByString:@" "];NSString*method=parts.count>0?parts[0]:@"GET";NSString*target=parts.count>1?parts[1]:@"/";NSString*path=target,*qs=@"";NSRange qr=[target rangeOfString:@"?"];if(qr.location!=NSNotFound){path=[target substringToIndex:qr.location];qs=[target substringFromIndex:qr.location+1];}NSDictionary*query=parseQuery(qs),*headers=parseHeaders(lines);NSRange sp=[raw rangeOfString:@"\r\n\r\n"];NSString*body=sp.location!=NSNotFound?[raw substringFromIndex:sp.location+sp.length]:@"";
    if([method isEqualToString:@"OPTIONS"]){[self sendResponse:fd status:@"204 No Content" type:@"text/plain" body:[NSData data]];return;}
    if([path isEqualToString:@"/"]){[self sendResponse:fd status:@"200 OK" type:@"text/html; charset=utf-8" body:[self indexHTML]];return;}
    if([path isEqualToString:@"/api/status"]){CGSize pt=self.screenCapture.pointSize,px=self.screenCapture.pixelSize;[self sendJSON:fd status:@"200 OK" object:@{@"ok":@YES,@"name":@"MyControl",@"version":@"0.3.0",@"port":@(self.port),@"screenCapture":@(self.screenCapture.available),@"touch":@NO,@"pointWidth":@(pt.width),@"pointHeight":@(pt.height),@"pixelWidth":@(px.width),@"pixelHeight":@(px.height)}];return;}
    if(![self isAuthorized:headers query:query]){[self sendJSON:fd status:@"401 Unauthorized" object:@{@"ok":@NO,@"error":@"Invalid pairing token"}];return;}
    if([path isEqualToString:@"/api/screenshot"]&&[method isEqualToString:@"GET"]){NSError*e=nil;NSData*j=[self.screenCapture captureJPEGWithQuality:0.55 error:&e];if(j.length)[self sendResponse:fd status:@"200 OK" type:@"image/jpeg" body:j];else[self sendJSON:fd status:@"500 Internal Server Error" object:@{@"ok":@NO,@"error":e.localizedDescription?:@"Screenshot failed"}];return;}
    if([path isEqualToString:@"/api/scripts"]&&[method isEqualToString:@"GET"]){[self sendJSON:fd status:@"200 OK" object:@{@"ok":@YES,@"scripts":[FileStore listScripts]}];return;}
    if([path isEqualToString:@"/api/save"]&&[method isEqualToString:@"POST"]){NSError*e=nil;BOOL ok=[FileStore saveScriptNamed:query[@"name"]?:@"script.lua" content:body error:&e];[self sendJSON:fd status:ok?@"200 OK":@"500 Internal Server Error" object:@{@"ok":@(ok),@"error":e.localizedDescription?:@""}];return;}
    if([path isEqualToString:@"/api/load"]&&[method isEqualToString:@"GET"]){NSError*e=nil;NSString*c=[FileStore loadScriptNamed:query[@"name"]?:@"script.lua" error:&e]?:@"";[self sendJSON:fd status:e?@"404 Not Found":@"200 OK" object:@{@"ok":@(e==nil),@"content":c,@"error":e.localizedDescription?:@""}];return;}
    if([path isEqualToString:@"/api/run"]&&[method isEqualToString:@"POST"]){[self sendJSON:fd status:@"200 OK" object:[ScriptRunner runLuaSource:body]];return;}
    [self sendResponse:fd status:@"404 Not Found" type:@"text/plain" body:[@"Not found" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)start{[FileStore ensureDirectories];int server=socket(AF_INET,SOCK_STREAM,0);if(server<0)return;int yes=1;setsockopt(server,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(yes));struct sockaddr_in addr;memset(&addr,0,sizeof(addr));addr.sin_family=AF_INET;addr.sin_port=htons(self.port);addr.sin_addr.s_addr=INADDR_ANY;if(bind(server,(struct sockaddr*)&addr,sizeof(addr))!=0||listen(server,8)!=0){close(server);return;}while(1){int client=accept(server,NULL,NULL);if(client<0)continue;dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{@autoreleasepool{[self handleClient:client];close(client);}});}}
@end
