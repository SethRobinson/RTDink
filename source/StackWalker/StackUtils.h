#pragma once
#include <PlatformSetup.h>
#ifdef _WIN32
#include "StackWalker.h"
#else
#include "StackWalker_stub.h"
#endif

void InitUnhandledExceptionFilter();