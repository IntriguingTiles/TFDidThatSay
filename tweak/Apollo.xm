
#import "Apollo.h"
#import "assets/TFHelper.h"

static BOOL isTFDeletedOnly;
static BOOL isApolloEnabled;
static CGFloat pushshiftRequestTimeoutValue;

%group Apollo

NSDictionary* apolloBodyAttributes = nil;
BOOL shouldAddUndeleteCell = NO;
id apolloCommentCell;
id apolloCommentController;

%hook ApolloButtonNode
%end

%hook IconActionTableViewCell
%end


%hook RKComment

-(BOOL) isDeleted{
	return NO;
}

-(BOOL) isModeratorRemoved{
	return NO;
}

%end


%hook MarkdownRenderer

+(id) attributedStringFromHTML:(id)arg1 attributes:(id) arg2 compact:(BOOL) arg3{

	apolloBodyAttributes = [arg2 copy];
	
	return %orig;
}

%end


%hook ActionController

-(id) tableView:(id) arg1 cellForRowAtIndexPath:(NSIndexPath *) arg2{
	
	if (shouldAddUndeleteCell){
		if ([arg2 row] == [self tableView:arg1 numberOfRowsInSection:0] - 1){
			
			id undeleteCell = [[objc_getClass("Apollo.IconActionTableViewCell") alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IconActionCell"];
			NSArray *visibleCells = [arg1 visibleCells];
			id prevCell = visibleCells[[visibleCells count] - 2];
			
			UIImageView *prevCellImageView = MSHookIvar<UIImageView *>(prevCell, "iconImageView");
			CGSize prevImageSize = [[prevCellImageView image] size];
			UIColor *menuColor = [prevCellImageView tintColor];
			
			UIImage *undeleteImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];
			CGFloat undeleteImageSizeValue = prevImageSize.width > prevImageSize.height ? prevImageSize.width : prevImageSize.height;
			
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(undeleteImageSizeValue, undeleteImageSizeValue), NO, 0);
			[undeleteImage drawInRect:CGRectMake(0, 0, undeleteImageSizeValue, undeleteImageSizeValue)];
			undeleteImage = [UIGraphicsGetImageFromCurrentImageContext() imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
			UIGraphicsEndImageContext();
			
			UILabel *undeleteLabel = MSHookIvar<UILabel *>(undeleteCell, "actionTitleLabel");
			UIImageView *undeleteImageView = MSHookIvar<UIImageView *>(undeleteCell, "iconImageView");
			
			undeleteLabel.text = @"TF Did That Say?";
			undeleteLabel.textColor = menuColor;
			
			undeleteImageView.image = undeleteImage;
			undeleteImageView.tintColor = menuColor;
			
			return undeleteCell;
		}
	}
	
	return %orig;	
}

-(void) tableView:(id) arg1 didSelectRowAtIndexPath:(NSIndexPath *)arg2{
	
	if (shouldAddUndeleteCell){
		if ([arg2 row] == [self tableView:arg1 numberOfRowsInSection:0] - 1){

			if (apolloCommentCell){
				[apolloCommentCell undeleteCellWasSelected];
			} else {
				[apolloCommentController undeleteCellWasSelected];
			}
		}
	} 
	
	%orig;
}

-(NSInteger) tableView:(id) arg1 numberOfRowsInSection:(NSInteger) arg2{
	
	if (shouldAddUndeleteCell){
		return %orig + 1;
	} else {
		return %orig;
	}
}

-(id) animationControllerForDismissedController:(id) arg1{
	
	shouldAddUndeleteCell = NO;
	
	return %orig;
}

%end


%hook CommentCellNode

-(void) moreOptionsTappedWithSender:(id) arg1{
	
	id commentBody = [MSHookIvar<id>(self, "comment") body];
	
	if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:commentBody isDeletedOnly:isTFDeletedOnly]){
		shouldAddUndeleteCell = YES;
		apolloCommentCell = self;
		apolloCommentController = nil;
	}
	
	%orig;
}

-(void) longPressedWithGestureRecognizer:(id) arg1{
	
	id commentBody = [MSHookIvar<id>(self, "comment") body];
	
	if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:commentBody isDeletedOnly:isTFDeletedOnly]){
		shouldAddUndeleteCell = YES;
		apolloCommentCell = self;
		apolloCommentController = nil;
	}
	
	%orig;
}

%new
-(void) undeleteCellWasSelected{

	id comment = MSHookIvar<id>(self, "comment");
	
	[%c(TFHelper) getUndeleteDataWithID:[[comment fullName] componentsSeparatedByString:@"_"][1] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
}

%new
-(void) completeUndeleteCommentAction:(NSDictionary *) data{
	
	id comment = MSHookIvar<id>(self, "comment");
	id bodyNode = MSHookIvar<id>(self, "bodyNode");
	id authorNode = MSHookIvar<id>(self, "authorNode");
	id authorTextNode = [authorNode subnodes][0];
	
	NSString *author = data[@"author"];
	NSString *body = data[@"body"];
	
	id prevAuthorAttributedString = [authorTextNode attributedString];
	NSDictionary *authorStringAttributes = [prevAuthorAttributedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [prevAuthorAttributedString length])];
	NSAttributedString *newAuthorAttributedString = [[NSAttributedString alloc] initWithString:author attributes:authorStringAttributes];

	[authorTextNode setAttributedText:newAuthorAttributedString];
	[authorTextNode setAttributedString:newAuthorAttributedString];
	
	[bodyNode setAttributedString:[%c(MarkdownRenderer) attributedStringFromMarkdown:body withAttributes:apolloBodyAttributes]];
	
	[comment setAuthor:author];
	[comment setBody:body];
}

%end


%hook CommentsViewController
%property(strong, nonatomic) id headerCellNode; 

-(void) moreOptionsBarButtonItemTappedWithSender:(id) arg1{
	
	RKLink *post = MSHookIvar<RKLink *>(self, "link");
	NSString *postBody = [post selfText];
	
	if ([post isSelfPost]){
		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:postBody isDeletedOnly:isTFDeletedOnly]){
			shouldAddUndeleteCell = YES;
			apolloCommentCell = nil;
			apolloCommentController = self;
		}
	}
	
	%orig;
}

%new
-(void) undeleteCellWasSelected{
	
	id post = MSHookIvar<id>(self, "link");
	
	[%c(TFHelper) getUndeleteDataWithID:[[post fullName] componentsSeparatedByString:@"_"][1] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
}

%new
-(void) completeUndeletePostAction:(NSDictionary *) data{
	
	id headerCellNode = [self headerCellNode];
	id bodyNode = MSHookIvar<id>(headerCellNode, "bodyNode");
	id postInfoNode = MSHookIvar<id>(headerCellNode, "postInfoNode");
	id authorNode = MSHookIvar<id>(postInfoNode, "authorButtonNode");
	id authorTextNode = [authorNode subnodes][0];
	
	NSString *author = data[@"author"];
	NSString *authorTextString = [NSString stringWithFormat:@"by %@", author];
	NSString *body = data[@"body"];
	
	id post = MSHookIvar<id>(self, "link");
	//MSHookIvar<NSString*>(post, "_author") = author; //Crashes when clicking on author name. You will have to search the author name to go find the profile.

	id prevAuthorAttributedString = [authorTextNode attributedString];
	NSDictionary *authorStringAttributes = [prevAuthorAttributedString attributesAtIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0, [prevAuthorAttributedString length])];
	NSAttributedString* newAuthorAttributedString = [[NSAttributedString alloc] initWithString:authorTextString attributes:authorStringAttributes];

	[authorTextNode setAttributedText:newAuthorAttributedString];
	[authorTextNode setAttributedString:newAuthorAttributedString];
	
	[bodyNode setAttributedString:[%c(MarkdownRenderer) attributedStringFromMarkdown:body withAttributes:apolloBodyAttributes]];
	[post setSelfText:body];
}

%end


%hook CommentsHeaderCellNode

-(void) didLoad{
	%orig;
	
	[[self closestViewController] setHeaderCellNode:self];
}

-(void) _layoutSublayouts{
	%orig;
	
	[[self closestViewController] setHeaderCellNode:self];
}

-(void) longPressedWithGestureRecognizer:(id) arg1{
	
	RKLink *post = MSHookIvar<RKLink *>(self, "link");
	NSString *postBody = [post selfText];
	
	if ([post isSelfPost]){
		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:postBody isDeletedOnly:isTFDeletedOnly]){
			shouldAddUndeleteCell = YES;
			apolloCommentCell = nil;
			apolloCommentController = self;
		}
	}
	
	%orig;
}

%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];
	
	if (prefs){
		
		if ([prefs objectForKey:@"isApolloEnabled"] != nil) {
			isApolloEnabled = [[prefs objectForKey:@"isApolloEnabled"] boolValue];
		} else {
			isApolloEnabled = YES;
		}
		
		if ([prefs objectForKey:@"isTFDeletedOnly"] != nil) {
			isTFDeletedOnly = [[prefs objectForKey:@"isTFDeletedOnly"] boolValue];
		} else {
			isTFDeletedOnly = YES;
		}
		
		if ([prefs objectForKey:@"requestTimeoutValue"] != nil){
			pushshiftRequestTimeoutValue = [[prefs objectForKey:@"requestTimeoutValue"] doubleValue];
		} else {
			pushshiftRequestTimeoutValue = 10;
		}

	} else {
		isApolloEnabled = YES;
		isTFDeletedOnly = YES;
		pushshiftRequestTimeoutValue = 10;
	}	
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  loadPrefs();
}


%ctor {
	loadPrefs();
	
	NSString* processName = [[NSProcessInfo processInfo] processName];
	
	if ([processName isEqualToString:@"Apollo"]){
		if (isApolloEnabled){
			
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			
			%init(Apollo, CommentsHeaderCellNode = objc_getClass("Apollo.CommentsHeaderCellNode"), CommentCellNode = objc_getClass("Apollo.CommentCellNode"), ApolloButtonNode = objc_getClass("Apollo.ApolloButtonNode"), ActionController = objc_getClass("Apollo.ActionController"), IconActionTableViewCell = objc_getClass("Apollo.IconActionTableViewCell"), CommentsViewController = objc_getClass("Apollo.CommentsViewController"));
		}
	}
}
