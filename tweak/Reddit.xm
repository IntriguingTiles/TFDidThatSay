
#import "Reddit.h"

%group Reddit_v4_current

%hook CommentTreeNode
%property(assign,nonatomic)id commentTreeHeaderNode;
%property(assign,nonatomic)id commentTreeCommandBarNode;
%end

%hook CommentTreeHeaderView

-(void) layoutSubviews{
	%orig;
	
	[[self commentTreeNode] setCommentTreeHeaderNode:self];
}

%end

%hook CommentTreeHeaderNode

-(void) didLoad{
	%orig;
	
	[[self commentTreeNode] setCommentTreeHeaderNode:self];
}
%end


%hook CommentTreeCommandBarNode

-(void) didLoad{
	%orig;

	[[self commentTreeNode] setCommentTreeCommandBarNode:self];
}
%end


%hook CommentActionSheetViewController

-(void) setItems:(id) arg1{

	UIImage* origImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

	CGSize existingImageSize = [[arg1[0] leftIconImage] size];
	CGFloat scale = origImage.size.width / existingImageSize.width;

	UIImage *newImage = [UIImage imageWithCGImage:[origImage CGImage] scale:scale orientation:origImage.imageOrientation];

	id undeleteItem = [[%c(RUIActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self comment]];

	%orig([arg1 arrayByAddingObject:undeleteItem]);
	
	[undeleteItem release];

}

-(void) handleDidSelectActionSheetItem:(id) arg1{
	%orig;
	
	if ([[arg1 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];	
		
		id commentTreeNode = [self commentTreeNode];
		Comment *comment = [commentTreeNode comment];

		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		NSOperationQueue *queue = [[NSOperationQueue alloc] init];

		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[[comment pk] componentsSeparatedByString:@"_"][1]]]];
		[request setHTTPMethod:@"GET"];		

		[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		
			NSString *author = @"[author]";
			NSString *body = @"[body]";

			if (data != nil && error == nil){
				id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
				if ([[jsonData objectForKey:@"data"] count] != 0){
					author = [[jsonData objectForKey:@"data"][0] objectForKey:@"author"];
					body = [[jsonData objectForKey:@"data"][0] objectForKey:@"body"];
					if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
						body = @"[pushshift was unable to archive this]";
					}
				} else {
					body = @"[pushshift has not archived this yet]";
				}
			} else if (error != nil || data == nil){
				body = @"[an error occured]";
			}
			
			NSArray* appVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] componentsSeparatedByString:@"."];
			
			NSMutableAttributedString *bodyMutableAttributedText;
			
			id themeManager;
			id isNightMode;
			id textColor;
			
			if ([appVersion[1] integerValue] >= 45){
				themeManager = [[%c(ThemeManager) alloc] initWithAppSettings:[%c(AppSettings) sharedSettings]];
				isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
				
				if (isNightMode) {
					textColor = [[themeManager darkTheme] bodyTextColor];
				} else{
					textColor = [[themeManager lightTheme] bodyTextColor];
				}
				
				[themeManager release];
				
				
			} else if ([appVersion[1] integerValue] >= 37){
				themeManager  = [[%c(ThemeManager) alloc] initWithTraitCollection:nil appSettings:[%c(AppSettings) sharedSettings]];
				isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
				
				if (isNightMode) {
					textColor = [[themeManager nightTheme] bodyTextColor];
				} else{
					textColor = [[themeManager dayTheme] bodyTextColor];
				}
				
				[themeManager release];
				
			} else {
				themeManager  = [%c(ThemeManager) sharedManager];
				isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
				
				if (isNightMode) {
					textColor = [[themeManager nightTheme] bodyTextColor];
				} else{
					textColor = [[themeManager dayTheme] bodyTextColor];
				}
			}
			
			bodyMutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[%c(NSAttributedStringMarkdownParser) attributedStringUsingCurrentConfig:body]];

			[bodyMutableAttributedText beginEditing];
			[bodyMutableAttributedText enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, bodyMutableAttributedText.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
				[bodyMutableAttributedText removeAttribute:NSForegroundColorAttributeName range:range]; 
				[bodyMutableAttributedText addAttribute:NSForegroundColorAttributeName value:textColor range:range];
			}];
			[bodyMutableAttributedText endEditing];
			
			[comment setAuthor:author];
			[comment setBodyText:body];
			[comment setBodyRichTextAttributed:bodyMutableAttributedText];
			[comment setBodyAttributedText:bodyMutableAttributedText];
			
			[[commentTreeNode commentTreeHeaderNode] performSelectorOnMainThread:@selector(updateContentViewsForData:) withObject:comment waitUntilDone:NO];

			[request release];
			[queue release];
			[bodyMutableAttributedText release];
			
		}];	
	}
}
%end


%hook PostDetailViewController
%property(strong,nonatomic) id feedPostTextWithThumbnailNode;
%property(strong,nonatomic) id feedPostDetailCellNode;
%end

%hook FeedPostDetailCellNode

-(void) didLoad{
	%orig;
	
	[[[self delegate] viewController] setFeedPostDetailCellNode:self];
}
%end

%hook PostActionSheetViewController

-(void) setItems:(id) arg1{
	
	Post *post = [self post];
	
	if ([post isSelfPost]){

		UIImage* origImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

		CGSize existingImageSize = [[arg1[0] leftIconImage] size];
		CGFloat scale = origImage.size.width / existingImageSize.width;

		UIImage *newImage = [UIImage imageWithCGImage:[origImage CGImage] scale:scale orientation:origImage.imageOrientation];

		id undeleteItem = [[%c(RUIActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self post]];

		arg1 = [arg1 arrayByAddingObject:undeleteItem];
		
		[undeleteItem release];
	}
	
	%orig;
}


-(void) handleDidSelectActionSheetItem:(id) arg1{
	%orig;
	
	if ([[arg1 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];
		
		Post *post = [self post];
		
		if ([post isSelfPost]){
			
			NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
			NSOperationQueue *queue = [[NSOperationQueue alloc] init];

			[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext",[[post pk] componentsSeparatedByString:@"_"][1]]]];
			[request setHTTPMethod:@"GET"];		

			[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
				
				NSString *author = @"[author]";
				NSString *body = @"[body]";
				
				if (data != nil && error == nil){
					id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
					if ([[jsonData objectForKey:@"data"] count] != 0){
						author = [[jsonData objectForKey:@"data"][0] objectForKey:@"author"];
						body = [[jsonData objectForKey:@"data"][0] objectForKey:@"selftext"];
						if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
							body = @"[pushshift was unable to archive this]";
						} 
					} else {
						body = @"[pushshift has not archived this yet]";
					}
				} else if (error != nil || data == nil){
					body = @"[an error occured]";
				}				
				
				NSArray* appVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] componentsSeparatedByString:@"."];
				
				id themeManager;
				id isNightMode;
				id textColor;
				
				if ([appVersion[1] integerValue] >= 45){
					themeManager = [[%c(ThemeManager) alloc] initWithAppSettings:[%c(AppSettings) sharedSettings]];
					isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
					
					if (isNightMode) {
						textColor = [[themeManager darkTheme] bodyTextColor];
					} else{
						textColor = [[themeManager lightTheme] bodyTextColor];
					}
					
					[themeManager release];
					
				} else if ([appVersion[1] integerValue] >= 37){
					themeManager  = [[%c(ThemeManager) alloc] initWithTraitCollection:nil appSettings:[%c(AppSettings) sharedSettings]];
					isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
					
					if (isNightMode) {
						textColor = [[themeManager nightTheme] bodyTextColor];
					} else{
						textColor = [[themeManager dayTheme] bodyTextColor];
					}
					
					[themeManager release];
					
				} else {
					themeManager  = [%c(ThemeManager) sharedManager];
					isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
					
					if (isNightMode) {
						textColor = [[themeManager nightTheme] bodyTextColor];
					} else{
						textColor = [[themeManager dayTheme] bodyTextColor];
					}
				}			

				NSMutableAttributedString *bodyMutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[%c(NSAttributedStringMarkdownParser) attributedStringUsingCurrentConfig:body]];

				[bodyMutableAttributedText beginEditing];
				[bodyMutableAttributedText enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, bodyMutableAttributedText.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
					[bodyMutableAttributedText removeAttribute:NSForegroundColorAttributeName range:range]; 
					[bodyMutableAttributedText addAttribute:NSForegroundColorAttributeName value:textColor range:range];
				}];
				[bodyMutableAttributedText endEditing];

				[post setSelfText:body];
				[post setAuthor:author];
				[post setSelfPostRichTextAttributed:bodyMutableAttributedText];
				[post setPreviewFeedPostTextString:bodyMutableAttributedText];
				
				if ([appVersion[1] integerValue] >= 44){
					[[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] contentNode] configureSelfTextNode];
				} else if ([appVersion[1] integerValue] >= 38) {
					[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] configureSelfTextNode];
				} else {
					[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] configureSelfTextNode];
					[[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] titleNode] configureNodes];
				}
				
				[request release];
				[queue release];
				[bodyMutableAttributedText release];
			}];			
		}	
	}
}
%end

%end



%group Reddit_v4_ios10

%hook CommentsViewController

%new 
-(void) updateComments{
	[self reloadCommentsWithNewCommentsHighlight:NO autoScroll:NO animated:NO];
}

%new 
-(void) updatePostText{
	[self reloadPostSection:YES];
}

%end

%hook CommentActionSheetViewController

-(void) setItems:(id) arg1{

	UIImage* origImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

	CGSize existingImageSize = [[arg1[0] leftIconImage] size];
	CGFloat scale = origImage.size.width / existingImageSize.width;

	UIImage *newImage = [UIImage imageWithCGImage:[origImage CGImage] scale:scale orientation:origImage.imageOrientation];

	id undeleteItem = [[%c(RUIActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self comment]];

	%orig([arg1 arrayByAddingObject:undeleteItem]);
	
	[undeleteItem release];
}

-(void) handleDidSelectActionSheetItem:(id) arg1{
	%orig;
	
	if ([[arg1 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];	
		
		Comment *comment = [self comment];

		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		NSOperationQueue *queue = [[NSOperationQueue alloc] init];

		[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[[comment pk] componentsSeparatedByString:@"_"][1]]]];
		[request setHTTPMethod:@"GET"];		

		[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		
			NSString *author = @"[author]";
			NSString *body = @"[body]";

			if (data != nil && error == nil){
				id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
				if ([[jsonData objectForKey:@"data"] count] != 0){
					author = [[jsonData objectForKey:@"data"][0] objectForKey:@"author"];
					body = [[jsonData objectForKey:@"data"][0] objectForKey:@"body"];
					if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
						body = @"[pushshift was unable to archive this]";
					}
				} else {
					body = @"[pushshift has not archived this yet]";
				}
			} else if (error != nil || data == nil){
				body = @"[an error occured]";
			}
			
			NSMutableAttributedString *bodyMutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[%c(NSAttributedStringMarkdownParser) attributedStringUsingCurrentConfig:body]];

			[comment setAuthor:author];
			[comment setBodyText:body];
			[comment setBodyRichTextAttributed:bodyMutableAttributedText];
			[comment setBodyAttributedText:bodyMutableAttributedText];
			
			[[self commentActionSheetDelegate] performSelectorOnMainThread:@selector(updateComments) withObject:nil waitUntilDone:NO];

			[request release];
			[queue release];
			[bodyMutableAttributedText release];
		}];	
	}
}
%end


%hook PostActionSheetViewController

-(void) setItems:(id) arg1{
	
	Post *post = [self post];
	
	if ([post isSelfPost]){

		UIImage* origImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

		CGSize existingImageSize = [[arg1[0] leftIconImage] size];
		CGFloat scale = origImage.size.width / existingImageSize.width;

		UIImage *newImage = [UIImage imageWithCGImage:[origImage CGImage] scale:scale orientation:origImage.imageOrientation];

		id undeleteItem = [[%c(RUIActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self post]];

		arg1 = [arg1 arrayByAddingObject:undeleteItem];
		
		[undeleteItem release];
	}
	
	%orig;
}


-(void) handleDidSelectActionSheetItem:(id) arg1{
	%orig;
	
	if ([[arg1 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];
		
		Post *post = [self post];
		
		if ([post isSelfPost]){
			
			NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
			NSOperationQueue *queue = [[NSOperationQueue alloc] init];

			[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/submission/?ids=%@&fields=author,selftext",[[post pk] componentsSeparatedByString:@"_"][1]]]];
			[request setHTTPMethod:@"GET"];		

			[NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
				
				NSString *author = @"[author]";
				NSString *body = @"[body]";
				
				if (data != nil && error == nil){
					id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
					if ([[jsonData objectForKey:@"data"] count] != 0){
						author = [[jsonData objectForKey:@"data"][0] objectForKey:@"author"];
						body = [[jsonData objectForKey:@"data"][0] objectForKey:@"selftext"];
						if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
							body = @"[pushshift was unable to archive this]";
						} 
					} else {
						body = @"[pushshift has not archived this yet]";
					}
				} else if (error != nil || data == nil){
					body = @"[an error occured]";
				}				
				
				NSMutableAttributedString *bodyMutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[%c(NSAttributedStringMarkdownParser) attributedStringUsingCurrentConfig:body]];
				
				[post setSelfText:body];
				[post setAuthor:author];
				[post setSelfPostRichTextAttributed:bodyMutableAttributedText];
				[post setPreviewFeedPostTextString:bodyMutableAttributedText];
				
				[[self postActionSheetDelegate] performSelectorOnMainThread:@selector(updatePostText) withObject:nil waitUntilDone:NO];
				
				[request release];
				[queue release];
				[bodyMutableAttributedText release];
			}];			
		}	
	}
}
%end

%end



%group Reddit_v3

%hook CommentView

%new
-(void) buttonAction {

	id commentsViewController = [self delegate];
	id comment = [self comment];

	NSError* error;

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[comment pkWithoutPrefix]]]];
	[request setHTTPMethod:@"GET"];

	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];

	NSString *author = @"[author]";
	NSString *body = @"[body]";

	if (data != nil && error == nil){
		
		id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
		   
		author = [[jsonData objectForKey:@"data"][0] objectForKey:@"author"];
		body = [[jsonData objectForKey:@"data"][0] objectForKey:@"body"];
		   
		if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
			body = @"[comment was unable to be archived]";
		}
		
	} else if (error != nil || data == nil){
		body = @"[an error occured]";
	}

	[comment setValue:author forKey:@"author"];

	[comment setValue:[%c(MarkDownParser) attributedStringFromMarkdownString: body] forKey:@"bodyAttributedText"];
	[comment setValue:body forKey:@"bodyText"];

	[commentsViewController reloadCommentsWithNewCommentsHighlight:NO autoScroll:NO animated:NO];
}


-(id) initWithFrame:(id)arg1{
	id orig = %orig;
	id commandView = [self commandView];

	UIButton *undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[undeleteButton addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];

	UIImage* undeleteImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];
	
	[undeleteButton setImage:undeleteImage forState:UIControlStateNormal];

	[commandView setUndeleteButton:undeleteButton];
	[commandView addSubview:undeleteButton];

	return orig;
}


%end


%hook CommentCommandView
%property (assign, nonatomic) id undeleteButton;

-(void) layoutSubviews{
	%orig;

	UIButton *button = [self undeleteButton];

	button.frame = CGRectMake([[self overflowButton ] frame].origin.x - 32, 0, 32, 32);
}
%end

%end




%ctor{
	
	NSString* processName = [[NSProcessInfo processInfo] processName];
	NSArray* appVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] componentsSeparatedByString:@"."];
	
	if ([processName isEqualToString:@"Reddit"]){			
		if ([appVersion[0] isEqualToString:@"4"]){
			if ([appVersion[1] integerValue] <= 32){
				%init(Reddit_v4_ios10);
			} else{
				%init(Reddit_v4_current);
			}	
		} else if ([appVersion[0] isEqualToString:@"3"]) {
			%init(Reddit_v3);
		}
	}
}




