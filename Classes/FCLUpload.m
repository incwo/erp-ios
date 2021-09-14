#import "FCLUpload.h"
#import "OAHTTPDownload.h"
#import "FCLField.h"
#import "FCLSession.h"

@implementation FCLUpload

- (NSMutableURLRequest*) request
{
    NSParameterAssert(self.session);
    NSParameterAssert(self.fileId);
    
    NSData* imageData = nil;
    
    if (self.image)
    {
        imageData = UIImageJPEGRepresentation(self.image, 0.7);
        if (!imageData)
        {
            NSLog(@"Upload: cannot convert UIImage to NSData (JPEG)!");
            return nil;
        }
    }
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/upload_files.xml", self.session.baseURL, self.fileId]];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey] forHTTPHeaderField:@"X_FACILE_VERSION"];
    
    [request setHTTPMethod:@"POST"];
    
    NSMutableData* postData = [NSMutableData data];
    
    [postData appendData:[@"<upload_file>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];

    [postData appendData:[[NSString stringWithFormat:@"<object_zname>%@</object_zname>", self.categoryKey] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];

    if (imageData)
    {
        [postData appendData:[@"<upload_file_name>iphone-picture.jpg</upload_file_name>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
        
        [postData appendData:[[NSString stringWithFormat:@"<upload_file_size>%lu</upload_file_size>", (unsigned long)[imageData length]] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
        
        [postData appendData:[@"<file_data_base64>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
        [postData appendData:[imageData base64EncodedDataWithOptions:0]];
        [postData appendData:[@"</file_data_base64>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
    }
    
    NSMutableString* fieldsTag = [NSMutableString string];
    [fieldsTag appendString:@"<les_champs>"];
    for (FCLField* field in self.fields)
    {
        if(field.type == FCLFieldTypeSignature)
        {
            NSData* signatureData = UIImageJPEGRepresentation([field image], 0.7);
            /*
             <my_signature>
                <file_name>signature.png</file_name>
                <file_size>size in octets of the file</file_size>
                <file_data_base64>Base-64 encoded data for the image...</file_data_base64>
             </my_signature>
             */
            if (signatureData)
            {
                [fieldsTag appendFormat:@"<%@>", field.key];
                [fieldsTag appendFormat:@"<file_name>%@.png</file_name>\n", field.key];
                [fieldsTag appendFormat:@"<file_size>%lu</file_size>\n", (unsigned long)[signatureData length]];
                [fieldsTag appendFormat:@"<file_data_base64>%@</file_data_base64>\n", [signatureData base64EncodedStringWithOptions:0]];
                [fieldsTag appendFormat:@"</%@>", field.key];
            }
        }
        else
        {
            NSString* value = [field value];
            if (!value) value = @"";
            [fieldsTag appendFormat:@"<%@>%@</%@>", field.key, value, field.key];
        }
        
        field.image = nil; // clear the data so it's not reused in the next upload.
    }
    [fieldsTag appendString:@"</les_champs>"];
    //NSLog(@"FCLUpload: fieldsTag: %@", fieldsTag);
    [postData appendData:[fieldsTag dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
    [postData appendData:[@"</upload_file>" dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO]];
    
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[postData length]] forHTTPHeaderField:@"Content-Length"];
    NSString* contentType = @"application/xml";
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];

    [request setBasicAuthHeadersForSession:self.session];
    [request setHTTPBody:postData];
    
    NSLog(@"Upload: Content-Length: %lu", (unsigned long)[postData length]);
    
    return request;
}

- (OAHTTPDownload *) OAHTTPDownload
{
    OAHTTPDownload* download = [OAHTTPDownload downloadWithRequest:[self request]];
    download.username = self.session.username;
    download.password = self.session.password;
    download.shouldAllowSelfSignedCert = YES;
    return download;
}

@end
