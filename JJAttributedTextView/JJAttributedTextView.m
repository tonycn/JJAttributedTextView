//
//  JJAttributedTextView.m
//
//  Created by Jianjun on 6/23/15.
//  Copyright (c) 2015 Jianjun. All rights reserved.
//

#import "JJAttributedTextView.h"

#import <objc/runtime.h>

@interface NSTextCheckingResult (JJ_APP)
- (NSDictionary *)JJ_textAttributes;
- (void)JJ_setTextAttributes:(NSDictionary *)attributes;
@end

@implementation NSTextCheckingResult (JJ_APP)
- (NSDictionary *)JJ_textAttributes
{
    const void * key = @selector(JJ_textAttributes);
    return objc_getAssociatedObject(self, key);
}

- (void)JJ_setTextAttributes:(NSDictionary *)attributes
{
    const void * key = @selector(JJ_textAttributes);
    objc_setAssociatedObject(self, key, attributes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface JJAttributedTextView () <NSLayoutManagerDelegate>
@property (nonatomic, strong) NSMutableArray *linksInText;
@property (nonatomic, strong) NSTextCheckingResult *activeLink;
@property (nonatomic, strong) NSAttributedString *inactiveAttributedText;
@property (nonatomic) CFTimeInterval touchBeginTime;
@property (nonatomic) NSLock *drawingRectLock;
@property (nonatomic, strong) NSAttributedString *originAttributedString;
@property (nonatomic, strong) NSAttributedString *activeAttributedString;
@end

@implementation JJAttributedTextView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSAssert(self.layoutManager, @"self.layoutManager should exist.");
        [self initViewSettings];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initViewSettings];
}

- (void)initViewSettings
{
    self.linksInText = [NSMutableArray array];
    self.selectable = NO;
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0;
    self.layoutManager.usesFontLeading = NO;
    self.layoutManager.delegate = self;
    self.drawingRectLock = [[NSLock alloc] init];
}

- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range activeAttributes:(NSDictionary *)attrs
{
    if (url == nil) {
        return;
    }
    NSTextCheckingResult *result = [NSTextCheckingResult linkCheckingResultWithRange:range URL:url];
    [result JJ_setTextAttributes:attrs];
    [self.linksInText addObject:result];
}

- (NSTextCheckingResult *)linkAtPoint:(CGPoint)point
{
    point.x -= self.textContainerInset.left;
    point.y -= self.textContainerInset.top;
    
    NSLayoutManager *layoutManager = self.layoutManager;
    
    NSUInteger characterIndex = [layoutManager characterIndexForPoint:point
                                                      inTextContainer:self.textContainer
                             fractionOfDistanceBetweenInsertionPoints:NULL];
    
    if (characterIndex < self.textStorage.length) {
        for (NSTextCheckingResult *linkResult in self.linksInText) {
            if (characterIndex >= linkResult.range.location
                && characterIndex < linkResult.range.location + linkResult.range.length) {
                return linkResult;
            }
        }
    }
    return nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchBeginTime = CACurrentMediaTime();
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    self.activeLink = [self linkAtPoint:point];
    if (self.activeLink == nil && self.highlightBackgroundColor) {
        self.backgroundColor = self.highlightBackgroundColor;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf.touchBeginTime > 0) {
            [weakSelf.touchEventDelegate replyTextViewDidLongPress:self];
        }
    });
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.backgroundColor = [UIColor clearColor];
    });
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    self.activeLink = [self linkAtPoint:point];
    if (self.activeLink) {
        [self.touchEventDelegate replyTextView:self didSelectLinkWithURL:self.activeLink.URL];
        self.activeLink = nil;
    } else {
        NSUInteger tapCount = touch.tapCount;
        if (tapCount == 0) {
            [[self nextResponder] touchesEnded:touches withEvent:event];
        } else if (tapCount == 1) {
            [self.touchEventDelegate replyTextViewDidTap:self];
        }
    }
    self.touchBeginTime = 0;
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.backgroundColor = [UIColor clearColor];
    self.activeLink = nil;
    self.touchBeginTime = 0;
}

- (void)setActiveLink:(NSTextCheckingResult *)activeLink
{
    _activeLink = activeLink;
    
    if ([activeLink JJ_textAttributes] || self.defaultActiveLinkAttributes) {
        [self setNeedsDisplay];
    }
    if (_activeLink == nil) {
        if (self.originAttributedString) {
            self.attributedText = self.originAttributedString;
            self.originAttributedString = nil;
        }
        self.activeAttributedString = nil;
    } else {
        if (self.activeAttributedString == nil) {
            self.originAttributedString = self.attributedText;
        }
    }
}

- (void)drawRect:(CGRect)rect
{
    if (![self.drawingRectLock tryLock]) {
        return;
    }
    NSDictionary *attrs = [self.activeLink JJ_textAttributes];
    if (attrs == nil) {
        attrs = self.defaultActiveLinkAttributes;
    }
    if (self.activeLink && attrs && self.activeAttributedString == nil) {
        if (attrs.count > 0) {
            NSMutableAttributedString *activeLinkText = [self.originAttributedString mutableCopy];
            [activeLinkText addAttributes:attrs range:self.activeLink.range];
            self.activeAttributedString = activeLinkText;
            self.attributedText = activeLinkText;
            [super drawRect:rect];
        } else {
            [super drawRect:rect];            
        }
    } else {
        [super drawRect:rect];
    }
    [self.drawingRectLock unlock];
}

@end
