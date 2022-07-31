#!/usr/bin/env dotnet-script

#r "nuget: CliWrap, 3.4.4"

using CliWrap;

var binDirectory = Path.Combine("bin", "Win64_Shipping_Client");
var modulesDirectory = "Modules";

var oldSrc = "old_src";
var newSrc = "new_src";

var oldPath = "old";
var newPath = "new";

var oldBinPath = Path.Combine(oldPath, binDirectory);
var newBinPath = Path.Combine(newPath, binDirectory);

var stdOut = Console.OpenStandardOutput();
var stdErr = Console.OpenStandardError();

await Cli.Wrap("dotnet")
    .WithArguments($"depotdownloader/DepotDownloader.dll -app 261550 -depot 261551 -beta {Args[0]} -username {Args[2]} -password {Args[3]} -filelist FileFilters.regexp -dir {oldPath}")
    .WithStandardOutputPipe(PipeTarget.ToStream(stdOut))
    .WithStandardErrorPipe(PipeTarget.ToStream(stdErr))
    .ExecuteAsync();

await Cli.Wrap("dotnet")
    .WithArguments($"depotdownloader/DepotDownloader.dll -app 261550 -depot 261551 -beta {Args[1]} -username {Args[2]} -password {Args[3]} -filelist FileFilters.regexp -dir {newPath}")
    .WithStandardOutputPipe(PipeTarget.ToStream(stdOut))
    .WithStandardErrorPipe(PipeTarget.ToStream(stdErr))
    .ExecuteAsync();

if (!Directory.Exists(oldPath))
{
    Console.WriteLine("'old' directory missing!");
    return 1;
}
if (!Directory.Exists(oldBinPath))
{
    Console.WriteLine("'old' bin directory missing!");
    return 1;
}

if (!Directory.Exists(newPath))
{
    Console.WriteLine("'new' directory missing!");
    return 1;
}
if (!Directory.Exists(newBinPath))
{
    Console.WriteLine("'new' bin directory missing!");
    return 1;
}

// bin folder first
await DecompileFile("TaleWorlds.*", oldBinPath, oldBinPath, Path.Combine(oldSrc, binDirectory), stdOut, stdErr);
await DecompileFile("TaleWorlds.*", newBinPath, newBinPath, Path.Combine(newSrc, binDirectory), stdOut, stdErr);
await DiffDirectories(Path.Combine(oldSrc, binDirectory), Path.Combine(newSrc, binDirectory), "html");

var oldModules = Directory.GetDirectories(Path.Combine(oldPath, modulesDirectory));
var newModules = Directory.GetDirectories(Path.Combine(newPath, modulesDirectory));
foreach (var module in oldModules)
{
    var moduleBinPath = Path.Combine(module, binDirectory);
    if (!Directory.Exists(moduleBinPath)) continue;

    var moduleDirectoryName = new DirectoryInfo(module).Name;
    await DecompileFile("*", moduleBinPath, oldBinPath, Path.Combine(oldSrc, modulesDirectory, moduleDirectoryName, binDirectory), stdOut, stdErr);
}
foreach (var module in newModules)
{
    var moduleBinPath = Path.Combine(module, binDirectory);
    if (!Directory.Exists(moduleBinPath)) continue;

    var moduleDirectoryName = new DirectoryInfo(module).Name;
    await DecompileFile("*", moduleBinPath, newBinPath, Path.Combine(newSrc, modulesDirectory, moduleDirectoryName, binDirectory), stdOut, stdErr);
}
foreach (var module in oldModules)
{
    var moduleDirectoryName = new DirectoryInfo(module).Name;
    var oldModuleSrc = Path.Combine(oldSrc, modulesDirectory, moduleDirectoryName, binDirectory);
    var newModuleSrc = Path.Combine(newSrc, modulesDirectory, moduleDirectoryName, binDirectory);
    if (!Directory.Exists(newModuleSrc)) Directory.CreateDirectory(newModuleSrc);
    await DiffDirectories(oldModuleSrc, newModuleSrc, Path.Combine("html", modulesDirectory, moduleDirectoryName));
}
foreach (var module in newModules)
{
    var moduleDirectoryName = new DirectoryInfo(module).Name;
    var oldModuleSrc = Path.Combine(oldSrc, modulesDirectory, moduleDirectoryName, binDirectory);
    var newModuleSrc = Path.Combine(newSrc, modulesDirectory, moduleDirectoryName, binDirectory);
    if (!Directory.Exists(oldModuleSrc)) Directory.CreateDirectory(oldModuleSrc);
    await DiffDirectories(oldModuleSrc, newModuleSrc, Path.Combine("html", modulesDirectory, moduleDirectoryName));
}

await Cli.Wrap("tree")
    .WithArguments($"./html -H {Args[4]}  --noreport --charset utf-8 -o ./html/index.html")
    .WithStandardOutputPipe(PipeTarget.ToStream(stdOut))
    .WithStandardErrorPipe(PipeTarget.ToStream(stdErr))
    .ExecuteAsync();



static async Task DecompileFile(string filter, string binPath, string referencePath, string outputPath, Stream stdOut, Stream stdErr)
{
    if (!Directory.Exists(outputPath)) Directory.CreateDirectory(outputPath);

    foreach (var file in Directory.GetFiles(binPath, filter, SearchOption.TopDirectoryOnly))
    {
        if (file.Contains("AutoGenerated") || file.Contains("BattlEye")) continue;

        Console.WriteLine($"Decompiling {file}");
        await Cli.Wrap("ilspycmd")
            .WithArguments($"{file} --project --outputdir {outputPath} --referencepath {referencePath}")
            .WithStandardOutputPipe(PipeTarget.ToStream(stdOut))
            .WithStandardErrorPipe(PipeTarget.ToStream(stdErr))
            .WithValidation(CommandResultValidation.None)
            .ExecuteAsync();
    }
}
static async Task DiffDirectories(string oldSrc, string newSrc, string outputPath)
{
    if (!Directory.Exists(outputPath)) Directory.CreateDirectory(outputPath);

    var visited = new HashSet<string>();
    foreach (var directory in Directory.GetDirectories(oldSrc))
    {
        var directoryName = new DirectoryInfo(directory).Name;

        if (visited.Contains(directoryName)) continue;
        visited.Add(directoryName);

        var oldPath = Path.Combine(oldSrc, directoryName);
        var newPath = Path.Combine(newSrc, directoryName);
        if (!Directory.Exists(oldPath)) Directory.CreateDirectory(oldPath);
        if (!Directory.Exists(newPath)) Directory.CreateDirectory(newPath);

        Console.WriteLine($"Diffing {directory}");
        var cmd =
            Cli.Wrap("diff")
                .WithArguments($"-ur {oldPath} {newPath}")
                .WithValidation(CommandResultValidation.None)
            |
            Cli.Wrap("diff2html")
                .WithArguments($"-s side -i stdin -F {Path.Combine(outputPath, $"{directoryName}.html")}")
                .WithValidation(CommandResultValidation.None);
        await cmd.ExecuteAsync();
    }
    foreach (var directory in Directory.GetDirectories(newSrc))
    {
        var directoryName = new DirectoryInfo(directory).Name;

        if (visited.Contains(directoryName)) continue;
        visited.Add(directoryName);

        var oldPath = Path.Combine(oldSrc, directoryName);
        var newPath = Path.Combine(newSrc, directoryName);
        if (!Directory.Exists(oldPath)) Directory.CreateDirectory(oldPath);
        if (!Directory.Exists(newPath)) Directory.CreateDirectory(newPath);

        Console.WriteLine($"Diffing {directory}");
        var cmd =
            Cli.Wrap("diff")
                .WithArguments($"-ur {oldPath} {newPath}")
                .WithValidation(CommandResultValidation.None)
            |
            Cli.Wrap("diff2html")
                .WithArguments($"-s side -i stdin -F {Path.Combine(outputPath, $"{directoryName}.html")}")
                .WithValidation(CommandResultValidation.None);
        await cmd.ExecuteAsync();
    }
}