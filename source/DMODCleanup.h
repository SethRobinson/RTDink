#ifndef RTDINK_DMOD_CLEANUP_H
#define RTDINK_DMOD_CLEANUP_H

#include "util/SafeDelete.h"
#include <cstdlib>

// The menu supplies a full DMOD path from GetDMODRootPath() + one directory
// name. Only that immediate child may be deleted, never the storage root.
inline bool RemoveInstalledDMOD(const std::string& storageRoot,
    const std::string& dmodPath, const std::string& appBase)
{
    if (storageRoot.find('\0') != std::string::npos) return false;
#ifndef _WIN32
    if (storageRoot.find('\\') != std::string::npos) return false;
#endif
    std::string root = storageRoot;
    if (!root.empty() && root[root.size()-1] != '/' && root[root.size()-1] != '\\') root += '/';
    if (dmodPath.compare(0, root.size(), root) != 0) return false;
    const std::string child = dmodPath.substr(root.size());
    if (child.empty() || child == "." || child == ".." ||
        child.find_first_of("/\\:*?\r\n") != std::string::npos ||
        child.find('\0') != std::string::npos) return false;

    // Windows and Linux normally store DMODs in the relative "dmods/" dir.
    // Bind that to the app's data directory, never an arbitrary deletion cwd.
    // Windows "-game name" intentionally returns an empty relative root for
    // an app-local DMOD. Even then, require a checked app base and one child.
    if (!ProtonSafeDelete::IsAbsoluteChildPath(root))
    {
        if (!ProtonSafeDelete::IsAbsoluteChildPath(appBase)) return false;
        root = appBase + ((appBase[appBase.size()-1] == '/' ||
            appBase[appBase.size()-1] == '\\') ? "" : "/") + root;
    }
    while (!root.empty() && (root[root.size()-1] == '/' || root[root.size()-1] == '\\'))
        root.erase(root.size()-1);
    if (!ProtonSafeDelete::IsAbsoluteChildPath(root)) return false;

#ifndef _WIN32
    // OS-provided cache roots may use aliases (/var on iOS, /sdcard on Android).
    // Resolve only the selected storage root; a linked DMOD child still fails.
    char* physicalRoot = realpath(root.c_str(), NULL);
    if (!physicalRoot) return false;
    root = physicalRoot;
    free(physicalRoot);
#endif
    if (!ProtonSafeDelete::IsSafeDirectory(root)) return false;
    return ProtonSafeDelete::RemoveTree(root + "/" + child);
}

#endif
