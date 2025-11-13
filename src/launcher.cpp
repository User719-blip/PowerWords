#include <iostream>
#include <string>
#include <sstream>
#include <cstdlib>

#ifdef _WIN32
#include <windows.h>
#else
#include <limits.h>
#include <unistd.h>
#endif

std::string getInstallPath(const char *argv0) {
#ifdef _WIN32
    char path[MAX_PATH];
    GetModuleFileNameA(NULL, path, MAX_PATH);
    std::string fullPath(path);
    size_t pos = fullPath.find_last_of("\\/");
    return (pos == std::string::npos) ? fullPath : fullPath.substr(0, pos);
#else
    char resolved[PATH_MAX];
    if (realpath(argv0, resolved)) {
        std::string fullPath(resolved);
        size_t pos = fullPath.find_last_of('/');
        return (pos == std::string::npos) ? fullPath : fullPath.substr(0, pos);
    }
    return ".";
#endif
}

void executeCommand(const std::string &command, const std::string &installPath)
{
#ifdef _WIN32
    std::string scriptPath = installPath + "\\..\\scripts\\win\\core.ps1";
    std::string fullCommand = "powershell -ExecutionPolicy Bypass -File \"" + scriptPath + "\" " + command;
    system(fullCommand.c_str());
#else
    // On macOS/Linux the main logic lives in scripts/mac/core.sh
    std::string scriptPath = installPath + "/../scripts/mac/core.sh";
    // Ensure the script is executed with bash
    std::string fullCommand = "/bin/bash \"" + scriptPath + "\" " + command;
    system(fullCommand.c_str());
#endif
}

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        std::cout << "Usage: launcher <command> [args...]\n";
        return 1;
    }

    std::ostringstream command;
    for (int i = 1; i < argc; ++i)
    {
        std::string arg = argv[i];
        // Quote each argument if it contains spaces
        if (arg.find(' ') != std::string::npos)
            command << "\"" << arg << "\"";
        else
            command << arg;
        if (i < argc - 1)
            command << " ";
    }

    std::string installPath = getInstallPath(argv[0]);
    executeCommand(command.str(), installPath);
    return 0;
}