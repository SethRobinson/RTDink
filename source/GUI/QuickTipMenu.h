#ifndef QuickTipMenu_h__
#define QuickTipMenu_h__
#include "PlatformSetup.h"
#include <string>
using std::string;
class Entity;

Entity * CreateQuickTipFirstTimeOnly(Entity *pParentEnt, string tipFileName, bool bRequireMoveMessages);
Entity * CreateQuickTip(Entity *pParentEnt, string tipFileName, bool bRequireMoveMessages);
#endif // QuickTipMenu_h__