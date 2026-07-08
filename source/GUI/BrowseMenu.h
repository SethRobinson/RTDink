#ifndef BrowseMenu_h__
#define BrowseMenu_h__
#include "BaseApp.h"
Entity * BrowseMenuCreate(Entity *pParentEnt);

//for AutoTester: read access to the downloaded DMOD list
int BrowseMenuGetDMODCount();
bool BrowseMenuGetDMODInfoByName(const std::string &name, std::string &urlOut, float &sizeOut);




#endif // BrowseMenu_h__