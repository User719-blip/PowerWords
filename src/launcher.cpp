#include <iostream>
#include <string>
#include <windows.h>

// Forward declaration

#include <sstream>
// ...existing code...
std::string getInstallPath() {
    char path[MAX_PATH];
    GetModuleFileNameA(NULL, path, MAX_PATH);
    std::string fullPath(path);
    size_t pos = fullPath.find_last_of("\\/");
    return (pos == std::string::npos) ? fullPath : fullPath.substr(0, pos);
}
void executeCommand(const std::string &command)
{
    std::string scriptPath = getInstallPath() + "\\..\\scripts\\win\\core.ps1";
    // Quote the script path
    std::string fullCommand = "powershell -ExecutionPolicy Bypass -File \"" + scriptPath + "\" " + command;
    system(fullCommand.c_str());
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
        // Quote each argument if it contains spaces
        std::string arg = argv[i];
        if (arg.find(' ') != std::string::npos)
            command << "\"" << arg << "\"";
        else
            command << arg;
        if (i < argc - 1)
            command << " ";
    }

    executeCommand(command.str());
    return 0;
}