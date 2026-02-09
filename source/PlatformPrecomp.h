#pragma once

#ifdef _WIN32
  #define strncasecmp _strnicmp
#endif

#include "PlatformSetup.h"
#ifndef _CONSOLE
#include "BaseApp.h"
#endif
