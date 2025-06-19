#include <iostream>
#include <string>
#include <windows.h>

// Forward declaration
std::string getInstallPath();
void executeCommand(const std::string &command)
{
    std::string fullCommand = "powershell -ExecutionPolicy Bypass -File \"" +
        getInstallPath() + "\\..\\scripts\\win\\core.ps1\" " + command + "\"";
    system(fullCommand.c_str());
}

std::string getInstallPath()
{
    wchar_t path[MAX_PATH];
    GetModuleFileNameW(NULL, path, MAX_PATH);
    std::wstring wpath(path);
    std::wstring::size_type pos = wpath.find_last_of(L"\\/");
    std::wstring wdir = wpath.substr(0, pos);
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, wdir.c_str(), (int)wdir.size(), NULL, 0, NULL, NULL);
    std::string dir(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, wdir.c_str(), (int)wdir.size(), &dir[0], size_needed, NULL, NULL);
    return dir;
}

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        std::cout << "Usage: launcher <command> [args...]\n";
        return 1;
    }

    std::string command;
    for (int i = 1; i < argc; ++i)
    {
        command += argv[i];
        if (i < argc - 1)
            command += " ";
    }

    executeCommand(command);
    return 0;
}