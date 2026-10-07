#include "../source/DMODCleanup.h"
#include <fstream>
#include <iostream>

static void Require(bool value, const char* message)
{
    if (!value) { std::cerr << message << std::endl; std::exit(1); }
}

static void MakeDir(const std::string& path)
{
#ifdef _WIN32
    Require(CreateDirectoryA(path.c_str(), NULL) != 0, "mkdir failed");
#else
    Require(mkdir(path.c_str(), 0700) == 0, "mkdir failed");
#endif
}

static void MakeDMOD(const std::string& path)
{
    MakeDir(path);
    MakeDir(path + "/story");
    MakeDir(path + "/graphics");
    MakeDir(path + "/empty");
    std::ofstream((path + "/dmod.diz").c_str()) << "test DMOD";
    std::ofstream((path + "/story/main.c").c_str()) << "test script";
    std::ofstream((path + "/save1.dat").c_str()) << "test save";
}

int main(int argc, char** argv)
{
    Require(argc == 2, "Pass an isolated absolute deletion-safety fixture");
    const std::string fixture = argv[1];
    Require(fixture.find("deletion-safety") != std::string::npos &&
        ProtonSafeDelete::IsSafeDirectory(fixture), "Invalid fixture");
    MakeDir(fixture + "/app");
    MakeDir(fixture + "/app/dmods");
    MakeDir(fixture + "/elsewhere");
    std::ofstream((fixture + "/elsewhere/keep.txt").c_str()) << "sentinel";
#ifdef _WIN32
    Require(SetCurrentDirectoryA((fixture + "/elsewhere").c_str()) != 0, "chdir failed");
#else
    Require(chdir((fixture + "/elsewhere").c_str()) == 0, "chdir failed");
#endif
    const std::string app = fixture + "/app/";
    const std::string root = app + "dmods/";
    MakeDMOD(root + "Cycles of Evil");
    Require(RemoveInstalledDMOD("dmods/", "dmods/Cycles of Evil", app), "Relative DMOD uninstall failed");
    Require(!ProtonSafeDelete::IsSafeDirectory(root + "Cycles of Evil"), "DMOD directory left behind");
    MakeDMOD(root + "abcdefgh");
    Require(RemoveInstalledDMOD(root, root + "abcdefgh", ""), "Absolute cache DMOD uninstall failed");
    Require(!ProtonSafeDelete::IsSafeDirectory(root + "abcdefgh"), "Absolute DMOD left behind");
    MakeDMOD(app + "local-dmod");
    Require(RemoveInstalledDMOD("", "local-dmod", app), "App-local -game DMOD uninstall failed");
    Require(!ProtonSafeDelete::IsSafeDirectory(app + "local-dmod"), "App-local DMOD left behind");
    Require(!RemoveInstalledDMOD("", "", app), "Accepted empty target");
    Require(!RemoveInstalledDMOD("", "anything", ""), "Accepted empty storage and app base");
    Require(!RemoveInstalledDMOD("dmods/", "dmods/anything", ""), "Accepted empty app base");
    Require(!RemoveInstalledDMOD(root, root, app), "Accepted storage root");
    Require(!RemoveInstalledDMOD(root, root + "../..", app), "Accepted traversal");
    Require(!RemoveInstalledDMOD(root, root + "nested/child", app), "Accepted non-immediate child");
    Require(!RemoveInstalledDMOD(root, fixture + "/elsewhere", app), "Accepted outside directory");
    Require(!RemoveInstalledDMOD(root, root + "missing", app), "Missing DMOD reported success");
#ifndef _WIN32
    Require(symlink(root.c_str(), (fixture + "/cache-alias").c_str()) == 0, "Root alias failed");
    MakeDMOD(root + "mobile");
    const std::string alias = fixture + "/cache-alias/";
    Require(RemoveInstalledDMOD(alias, alias + "mobile", ""), "OS cache alias cleanup failed");
    Require(symlink((fixture + "/elsewhere").c_str(), (root + "redirect").c_str()) == 0, "DMOD link failed");
    Require(!RemoveInstalledDMOD(root, root + "redirect", ""), "Followed linked DMOD");
#endif
    Require(std::ifstream((fixture + "/elsewhere/keep.txt").c_str()).good(), "Outside sentinel deleted");
    Require(ProtonSafeDelete::IsSafeDirectory(root), "Deleted the DMOD storage root");
    std::cout << "RTDink uninstall and autotest cleanup tests passed" << std::endl;
}
