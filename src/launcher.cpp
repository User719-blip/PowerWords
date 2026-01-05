#include <algorithm>
#include <conio.h>
#include <filesystem>
#include <iomanip>
#include <iostream>
#include <exception>
#include <sstream>
#include <string>
#include <system_error>
#include <vector>

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shellapi.h>

struct DirectoryEntry
{
    std::string name;
    std::filesystem::path path;
    bool isDirectory;
};

std::string getInstallPath()
{
    char path[MAX_PATH];
    GetModuleFileNameA(NULL, path, MAX_PATH);
    std::string fullPath(path);
    size_t pos = fullPath.find_last_of("\\/");
    return (pos == std::string::npos) ? fullPath : fullPath.substr(0, pos);
}

void executeCommand(const std::string &command)
{
    auto exeDir = std::filesystem::path(getInstallPath());
    std::vector<std::filesystem::path> candidates = {
        exeDir / "scripts" / "win" / "core.ps1",
        exeDir.parent_path() / "scripts" / "win" / "core.ps1"
    };

    std::filesystem::path scriptPath;
    for (const auto &candidate : candidates)
    {
        std::error_code ec;
        if (std::filesystem::exists(candidate, ec) && std::filesystem::is_regular_file(candidate, ec))
        {
            scriptPath = candidate.lexically_normal();
            break;
        }
    }

    if (scriptPath.empty())
    {
        std::cout << "Unable to locate scripts\\win\\core.ps1 near " << exeDir.string() << std::endl;
        return;
    }

    std::string fullCommand = "powershell -ExecutionPolicy Bypass -File \"" + scriptPath.string() + "\" " + command;
    system(fullCommand.c_str());
}

void clearConsole(HANDLE handle)
{
    CONSOLE_SCREEN_BUFFER_INFO csbi;
        
    if (!GetConsoleScreenBufferInfo(handle, &csbi))
        return;

    DWORD cellCount = csbi.dwSize.X * csbi.dwSize.Y;
    DWORD written = 0;
    COORD home{0, 0};

    FillConsoleOutputCharacterA(handle, ' ', cellCount, home, &written);
    FillConsoleOutputAttribute(handle, csbi.wAttributes, cellCount, home, &written);
    SetConsoleCursorPosition(handle, home);
}

int getConsoleWidth(HANDLE handle)
{
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    if (GetConsoleScreenBufferInfo(handle, &csbi))
        return csbi.dwSize.X;
    return 80;
}

std::vector<DirectoryEntry> collectDirectoryEntries(const std::filesystem::path &basePath, std::string &statusMessage)
{
    statusMessage.clear();
    std::vector<DirectoryEntry> entries;

    try
    {
        for (const auto &item : std::filesystem::directory_iterator(basePath))
        {
            std::error_code ec;
            bool isDir = item.is_directory(ec);
            bool isFile = item.is_regular_file(ec);

            if (!ec && (isDir || isFile))
            {
                entries.push_back({item.path().filename().string(), item.path(), isDir});
            }
        }

        std::sort(entries.begin(), entries.end(), [](const DirectoryEntry &lhs, const DirectoryEntry &rhs) {
            if (lhs.isDirectory != rhs.isDirectory)
            {
                return lhs.isDirectory && !rhs.isDirectory;
            }
            return _stricmp(lhs.name.c_str(), rhs.name.c_str()) < 0;
        });
    }
    catch (const std::filesystem::filesystem_error &ex)
    {
        statusMessage = "Error: " + std::string(ex.what());
    }

    return entries;
}

std::string truncateName(const std::string &name, std::size_t limit)
{
    if (limit < 4 || name.size() <= limit)
        return name;
    return name.substr(0, limit - 3) + "...";
}

bool isRootPath(const std::filesystem::path &path)
{
    auto normalized = path.lexically_normal();
    if (normalized.empty())
        return false;

    auto root = normalized.root_path();
    if (normalized.has_root_directory())
        root /= normalized.root_directory();

    if (root.empty())
        return normalized == std::filesystem::path("/");

    return normalized == root;
}

void renderDirectoryGrid(const std::filesystem::path &currentPath,
                         const std::vector<DirectoryEntry> &entries,
                         std::size_t selectedIndex,
                         HANDLE handle,
                         WORD defaultAttr,
                         const std::string &statusMessage)
{
    clearConsole(handle);

    SetConsoleTextAttribute(handle, defaultAttr | FOREGROUND_INTENSITY);
    std::cout << "Path: " << currentPath.string() << "\n";
    std::cout << "[Enter] open   [Backspace] up   [Esc] exit\n";
    SetConsoleTextAttribute(handle, defaultAttr);
    if (!statusMessage.empty())
    {
        std::cout << statusMessage << "\n";
    }

    int consoleWidth = getConsoleWidth(handle);
    int columnWidth = std::max(20, consoleWidth / 3);

    for (std::size_t i = 0; i < entries.size(); ++i)
    {
        const auto &entry = entries[i];
        std::string label = entry.name + (entry.isDirectory ? "\\" : "");
        label = truncateName(label, static_cast<std::size_t>(columnWidth - 2));

        if (i == selectedIndex)
        {
            SetConsoleTextAttribute(handle, BACKGROUND_BLUE | BACKGROUND_INTENSITY | FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE);
        }

        std::cout << std::left << std::setw(columnWidth) << label;

        SetConsoleTextAttribute(handle, defaultAttr);

        if ((i + 1) % 3 == 0)
        {
            std::cout << "\n";
        }
    }

    if (entries.empty())
    {
        std::cout << "(no entries)\n";
    }

    std::cout << std::endl;
}

int runDirectoryBrowser(const std::filesystem::path &startPath)
{
    std::filesystem::path currentPath = startPath;
    std::string statusMessage;
    std::size_t selectedIndex = 0;
    HANDLE handle = GetStdHandle(STD_OUTPUT_HANDLE);

    if (!std::filesystem::exists(currentPath))
    {
        std::cout << "Path not found: " << currentPath.string() << std::endl;
        return 1;
    }

    WORD defaultAttr = 0;
    {
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        if (GetConsoleScreenBufferInfo(handle, &csbi))
        {
            defaultAttr = csbi.wAttributes;
        }
    }

    std::vector<std::filesystem::path> history;

    while (true)
    {
        auto entries = collectDirectoryEntries(currentPath, statusMessage);

        if (entries.empty())
        {
            selectedIndex = 0;
        }
        else if (selectedIndex >= entries.size())
        {
            selectedIndex = entries.size() - 1;
        }

        renderDirectoryGrid(currentPath, entries, selectedIndex, handle, defaultAttr, statusMessage);

        int key = _getch();

        if (key == 224 || key == 0)
        {
            int arrow = _getch();
            if (!entries.empty())
            {
                switch (arrow)
                {
                case 72: // Up
                    if (selectedIndex >= 3)
                    {
                        selectedIndex -= 3;
                    }
                    break;
                case 80: // Down
                    if (selectedIndex + 3 < entries.size())
                    {
                        selectedIndex += 3;
                    }
                    break;
                case 75: // Left
                    if (selectedIndex > 0)
                    {
                        --selectedIndex;
                    }
                    break;
                case 77: // Right
                    if (selectedIndex + 1 < entries.size())
                    {
                        ++selectedIndex;
                    }
                    break;
                default:
                    break;
                }
            }
        }
        else if (key == '\r') // Enter
        {
            if (!entries.empty())
            {
                const auto &chosen = entries[selectedIndex];
                if (chosen.isDirectory)
                {
                    history.push_back(currentPath);
                    currentPath = chosen.path;
                    selectedIndex = 0;
                }
                else
                {
                    HINSTANCE opened = ShellExecuteA(nullptr, "open", chosen.path.string().c_str(), nullptr, nullptr, SW_SHOWNORMAL);
                    if (reinterpret_cast<INT_PTR>(opened) <= 32)
                    {
                        statusMessage = "Failed to open: " + chosen.name;
                    }
                    else
                    {
                        statusMessage = "Opened: " + chosen.name;
                    }
                }
            }
        }
        else if (key == 8) // Backspace
        {
            std::filesystem::path parent = currentPath.parent_path();
            if (!isRootPath(currentPath) && parent != currentPath)
            {
                history.push_back(currentPath);
                currentPath = parent;
                selectedIndex = 0;
            }
        }
        else if (key == 27) // Esc
        {
            break;
        }
    }

    return 0;
}

int main(int argc, char *argv[])
{
    if (argc > 1)
    {
        std::string commandLower = argv[1];
        std::transform(commandLower.begin(), commandLower.end(), commandLower.begin(),
                       [](unsigned char ch) { return static_cast<char>(std::tolower(ch)); });

        if (commandLower == "list" || commandLower == "path")
        {
            std::filesystem::path startPath =
                (argc > 2) ? std::filesystem::path(argv[2]) : std::filesystem::current_path();
            return runDirectoryBrowser(startPath);
        }
    }

    if (argc < 2)
    {
        std::cout << "Usage: launcher <command> [args...]" << std::endl;
        return 1;
    }

    std::string commandName = argv[1];
    if (commandName == "list")
    {
        std::filesystem::path targetPath;
        if (argc >= 3)
            targetPath = argv[2];
        else
        {
            std::error_code ec;
            targetPath = std::filesystem::current_path(ec);
            if (ec)
            {
                std::cout << "Failed to resolve current directory: " << ec.message() << std::endl;
                return 1;
            }
        }

        try
        {
            return runDirectoryBrowser(targetPath);
        }
        catch (const std::filesystem::filesystem_error &ex)
        {
            std::cout << "Filesystem error: " << ex.what() << std::endl;
            return 1;
        }
        catch (const std::exception &ex)
        {
            std::cout << "Error: " << ex.what() << std::endl;
            return 1;
        }
    }

    std::ostringstream command;
    for (int i = 1; i < argc; ++i)
    {
        std::string arg = argv[i];
        if (arg.find(' ') != std::string::npos)
            command << "\"" << arg << "\"";
        else
            command << arg;
        if (i < argc - 1)
            command << ' ';
    }

    executeCommand(command.str());
    return 0;
}
