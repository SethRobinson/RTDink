#pragma once
#include <PlatformSetup.h>

#if defined(_WIN32)
#include "StackWalker.h"
void InitUnhandledExceptionFilter();
#else
inline void InitUnhandledExceptionFilter() {}
#endif