#include <iostream>
#include <string>
#include <windows.h>

void executeCommand(const std::string& command) {
    std::string fullCommand = "powershell -ExecutionPolicy Bypass -File \"" + 
        getInstallPath() + "\\scripts\\main.ps1\" " + command + "\"";
    system(fullCommand.c_str());
}

std::string getInstallPath() {
    char path[MAX_PATH];
    GetModuleFileName(NULL, path, MAX_PATH);
    std::string::size_type pos = std::string(path).find_last_of("\\/");
    return std::string(path).substr(0, pos);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cout << "Usage: launcher <command> [args...]\n";
        return 1;
    }

    std::string command;
    for (int i = 1; i < argc; ++i) {
        command += argv[i];
        if (i < argc - 1) command += " ";
    }

    executeCommand(command);
    return 0;
}
