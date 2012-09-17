//
//  config.h
//  emptyExample
//
//  Created by Samuel Luescher on 9/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef emptyExample_config_h
#define emptyExample_config_h

#include "TargetConditionals.h"

#if (TARGET_OS_IPHONE)

#define OVERHEAD_HOST "18.85.58.59"

#define LINE_WIDTH_GRID_SUBDIV 2
#define LINE_WIDTH_GRID_WHOLE 4

#else

#define LINE_WIDTH_GRID_SUBDIV 1
#define LINE_WIDTH_GRID_WHOLE 2

#endif




#endif
