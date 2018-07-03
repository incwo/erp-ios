#import "PMultipartData.h"

@interface PMultipartData ()

@property NSMutableData *mutableData;
@property BOOL started;
@property BOOL finished;

@end

@implementation PMultipartData

- (id) init
{
	if (self = [super init])
	{
		_mutableData = [[NSMutableData alloc] init];
		_boundary = @"PMultipartData83c4lq15a4Snje4na2h5kqt8lqr97sp219"; // truly random boundary
	}
	return self;
}

@synthesize boundary = _boundary;
- (void) setBoundary:(NSString *)boundary
{
	if (_boundary == boundary || boundary.length < 1) return;
	
	NSAssert(!self.finished, @"PMultipartData is finished, cannot change boundary!");
	NSAssert(!self.started,  @"PMultipartData is started, cannot change boundary!");
	
	_boundary = boundary;
}

- (NSString*) contentType
{
	return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary];
}

// Appends text/plain values.
- (void) addString:(NSString*)string forKey:(NSString*)key
{
	if (!string || key.length == 0) return;
	
	NSAssert(!self.finished, @"PMultipartData is finished, cannot add more data!");
	
	// Note: content-type for strings is not included per http://www.faqs.org/rfcs/rfc2388.html
	// If content-type is added, the parameter will be treated like an uploaded file.
	[self.mutableData appendData:[[NSString stringWithFormat:@"%@--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\nContent-Transfer-Encoding: binary\r\n\r\n",
					   self.started ? @"\r\n" : @"", self.boundary, key]
					  dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
	[self.mutableData appendData:[string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
	
	self.started = YES;
}

// Appends string values and keys using addString:forKey:
- (void) addDictionary:(NSDictionary*)dict
{
	NSAssert(!self.finished, @"PMultipartData is finished, cannot add more data!");
	
	for (NSString* key in dict)
	{
		[self addString:dict[key] forKey:key];
	}
}

// Appends arbitrary file data. Filename is optional.
- (void) addData:(NSData*)fileData mimeType:(NSString*)mimeType filename:(NSString*)filename forKey:(NSString*)key
{
	NSAssert(!self.finished, @"PMultipartData is finished, cannot add more data!");
	
	NSString* header = [NSString stringWithFormat:@"%@--%@\r\nContent-Disposition: form-data; name=\"file\"%@\r\nContent-Type: %@\r\nContent-Transfer-Encoding: binary\r\n\r\n", self.started ? @"\r\n" : @"", self.boundary, filename.length > 0 ? [NSString stringWithFormat:@"; filename=\"%@\"", filename] : @"", mimeType];
	
	[self.mutableData appendData:[header dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
	[self.mutableData appendData:fileData];
	self.started = YES;
}

- (NSData *) data
{
	if (!self.finished && self.started)
	{
		[self.mutableData appendData:[[NSString stringWithFormat:@"\r\n--%@--", self.boundary] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
		self.finished = YES;
	}
	return self.mutableData;
}

@end
