//
//  SLAnimatedRocketView.m
//  Smart Launch
//
//  Created by J. HOWARD SMART on 11/25/12.
//  Copyright (c) 2012 J. HOWARD SMART. All rights reserved.
//

#import "SLAnimatedRocketView.h"
#import "SLDefinitions.h"

@implementation SLAnimatedRocketView

-(void)startFresh{
    UIImageView *goblin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:VERTICAL_ROCKET_PIC_NAME]];
    CGPoint orig = CGPointMake(goblin.bounds.size.width + 10, goblin.bounds.size.height + 10);
    CGSize s = self.bounds.size;
    CGRect frame = CGRectMake(s.width - orig.x, s.height - orig.y, goblin.bounds.size.width, goblin.bounds.size.height);
    [goblin setFrame:frame];
    [self addSubview:goblin];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self startFresh];
    }
    return self;
}

- (void)awakeFromNib{
    [self startFresh];
}

- (void)tiltRocketToAngle:(float)angle{
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
