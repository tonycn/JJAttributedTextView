//
//  JJAttributedTextView.h
//
//  Created by Jianjun on 6/23/15.
//  Copyright (c) 2015 Jianjun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class JJAttributedTextView;

@protocol JJAttributedTextViewDelegate <NSObject>
- (void)replyTextViewDidTap:(JJAttributedTextView *)textView;
- (void)replyTextViewDidLongPress:(JJAttributedTextView *)textView;
- (void)replyTextView:(JJAttributedTextView *)textView didSelectLinkWithURL:(NSURL *)url;
@end


@interface JJAttributedTextView : UITextView
@property (nonatomic, strong) UIColor *highlightBackgroundColor;
@property (nonatomic, weak) id<JJAttributedTextViewDelegate> touchEventDelegate;
@property (nonatomic, strong) NSDictionary *defaultActiveLinkAttributes;
- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range activeAttributes:(NSDictionary *)attrs;
@end
