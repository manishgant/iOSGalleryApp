//
//  TwitterViewController.m
//  manantha_Universal_Multimedia
//
//  Created by Manishgant on 7/14/15.
//  Copyright (c) 2015 Manishgant. All rights reserved.
//

#import "TwitterViewCOntroller.h"
#import "TweetDisplayView.h"

@interface TwitterViewController()

@end

@implementation TwitterViewController


/*
 When view is about to appear, get the tweets
 from user timeline and display them in a
 TableView
 */

-(void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self getTimelineTweets];
    
}

/*
 Get the number of rows in the TableView
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataSource.count;
}

/*
 Construct each cell in the Tableview with text from the tweet
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [self.tweetTableView
                             dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *tweet = _dataSource[[indexPath row]];
    cell.textLabel.numberOfLines = 0;
    [cell.textLabel setText: tweet[@"text"]];
    
    NSString *string = cell.textLabel.text;
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *matches = [linkDetector matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    if ((matches.count == 1)) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    matches = nil;
    return cell;
    
}

/*
 Alter the height of the cell in Tableview based on
 text content. Wrap the text of the content in the cell
 */

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

/*
 When the user selects a row on the tableview, perform a segue
 to display the tweet in a webview. Perform this only on tweets
 which have media attached. Use NSDataDetector to identify tweets
 with media URL and display only those in the webview
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *string = cell.textLabel.text;
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *matches = [linkDetector matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    for (NSTextCheckingResult *match in matches) {
        if ([match resultType] == NSTextCheckingTypeLink) {
            NSURL *url = [match URL];
            NSLog(@"found URL: %@", url);
            self->_imageURL = url;
            
            // Perform Segue to webview with URL data
            [self performSegueWithIdentifier:@"displayImage" sender:self->_imageURL];
            
        } else if(!([matches count] != 1)){
            [self timelineNoImageExeptionThrow];
        }
        matches = nil;
    }
    
}

/*
 Use Twitter REST API to get the tweets from user timeline
 Use asynchronous blocks to perform this operation in the background
 as this is a time consuming process
 */

- (void)getTimelineTweets {
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [account
                                  accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        [account requestAccessToAccountsWithType:accountType
                                         options:nil completion:^(BOOL granted, NSError *error)
         {
             if (granted == YES)
             {
                 NSArray *arrayOfAccounts = [account
                                             accountsWithAccountType:accountType];
                 
                 if ([arrayOfAccounts count] > 0)
                 {
                     ACAccount *twitterAccount = [arrayOfAccounts lastObject];
                     
                     NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/user_timeline.json"];
                     
                     NSMutableDictionary *parameters =
                     [[NSMutableDictionary alloc] init];
                     [parameters setObject:@"50" forKey:@"count"];
                     [parameters setObject:@"1" forKey:@"include_entities"];
                     
                     SLRequest *postRequest = [SLRequest
                                               requestForServiceType:SLServiceTypeTwitter
                                               requestMethod:SLRequestMethodGET
                                               URL:requestURL parameters:parameters];
                     
                     postRequest.account = twitterAccount;
                     
                     [postRequest performRequestWithHandler:
                      ^(NSData *responseData, NSHTTPURLResponse
                        *urlResponse, NSError *error)
                      {
                          self.dataSource = [NSJSONSerialization
                                             JSONObjectWithData:responseData
                                             options:NSJSONReadingMutableLeaves
                                             error:&error];
                          
                          if (self.dataSource.count != 0) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [self.tweetTableView reloadData];
                              });
                          }
                      }];
                 }
             } else {
                 // Handle failure to get account access
                 NSString *message = @"It seems that you have not yet allowed your app to use Twitter account. Please go to Settings to allow access ";
                 [self twitterExceptionHandling:message];
                 
             }
         }];
    } else {
        
        // Handle failure to get account access
        NSString *message = @"It seems that you have not yet added a Twitter account. Please go to Settings and add an account";
        [self twitterExceptionHandling:message];
        
    }
    
}

/*
 Exception Handling in case the user has not added a twitter account
 or has not authorized the app to use twitter credentials
 */

-(void)twitterExceptionHandling:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Oops!!!" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"User pressed Cancel");
                                   }];
    
    UIAlertAction *settingsAction = [UIAlertAction
                                     actionWithTitle:NSLocalizedString(@"Settings", @"Settings action")
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction *action)
                                     {
                                         NSLog(@"Settings Pressed");
                                         
                                         //code for opening settings app in iOS 8
                                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                         
                                     }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:settingsAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

/*
 Throw a message when the user selects a tweet with no media to show
 */

-(void)timelineNoImageExeptionThrow {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"No Image" message:@"This tweet has no image to display" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"User pressed OK");
                                   }];
    
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

/*
 Bundle the media URL data to display in the Webview
 */
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    TwitterDisplayView *view = [segue destinationViewController];
    view.imageURL = self->_imageURL;
}


@end