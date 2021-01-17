param ($old_version_folder, $new_version_folder);

if ([string]::IsNullOrEmpty($old_version_folder)) {
	Write-Host "old_version_folder was not provided! Exiting...";
	exit;	
}
if ([string]::IsNullOrEmpty($new_version_folder)) {
	Write-Host "new_version_folder was not provided! Exiting...";
	exit;	
}

dotnet tool install ilspycmd -g;
npm install -g diff2html-cli;

$mappings = @{};
$mappings.Add('bannerlord.referenceassemblies.core.earlyaccess', 'Core');
$mappings.Add('bannerlord.referenceassemblies.native.earlyaccess', 'Native');
$mappings.Add('bannerlord.referenceassemblies.sandbox.earlyaccess', 'SandBox');
$mappings.Add('bannerlord.referenceassemblies.storymode.earlyaccess', 'StoryMode');
$mappings.Add('bannerlord.referenceassemblies.custombattle.earlyaccess', 'CustomBattle');

$excludes = @(
    '*AutoGenerated*',
    '*BattlEye*');

$old  = [IO.Path]::Combine($(Get-Location), "temp", "old" );
$new  = [IO.Path]::Combine($(Get-Location), "temp", "new" );
$diff = [IO.Path]::Combine($(Get-Location), "temp", "diff");
$md   = [IO.Path]::Combine($(Get-Location), "temp", "md"  );
$html = [IO.Path]::Combine($(Get-Location), "temp", "html");
New-Item -ItemType directory -Path $diff -Force;
New-Item -ItemType directory -Path $md -Force;
New-Item -ItemType directory -Path $html -Force;

$old_folders = Get-ChildItem -Path $old_version_folder;
$new_folders = Get-ChildItem -Path $new_version_folder;

for ($i = 0; $i -lt $mappings.Length; $i++) {
    $mapping = $mappings["$folder"];
    $old_folder = $old_folders[$i];
    $new_folder = $new_folders[$i];

    $old_path = [IO.Path]::Combine($old_version_folder, $old_folder);
    $new_path = [IO.Path]::Combine($new_version_folder, $new_folder);

    $old_files = Get-ChildItem -Path $($old_path + '/*.dll') -Recurse -Exclude $excludes;
    $new_files = Get-ChildItem -Path $($new_path + '/*.dll') -Recurse -Exclude $excludes;


    # generate source code based on the Public API
    foreach ($file in $old_files) {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($file);

        $old_folder  = [IO.Path]::Combine("$old", $mapping,  $fileWE);
        New-Item -ItemType directory -Path $old_folder -Force;

        ilspycmd "$($file.FullName)" --project --outputdir "$old_folder" --referencepath "$old_main_bin_path";
    }
    foreach ($file in $new_files) {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($file);

        $new_folder  = [IO.Path]::Combine("$new", $mapping,  $fileWE);
        New-Item -ItemType directory -Path $new_folder -Force;

        ilspycmd "$($file.FullName)" --project --outputdir "$new_folder" --referencepath "$new_main_bin_path";
    }


    # delete csproj files
    foreach ($file in $old_files) {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($file);
        $old_folder = [IO.Path]::Combine($(Get-Location), "temp", "old", $mapping, $fileWE);
        $new_folder = [IO.Path]::Combine($(Get-Location), "temp", "new", $mapping, $fileWE);
        Get-ChildItem -Path $($old_folder + '/*.csproj') -Recurse | foreach { Remove-Item -Path $_.FullName };
        Get-ChildItem -Path $($new_folder + '/*.csproj') -Recurse | foreach { Remove-Item -Path $_.FullName };
    }
    foreach ($file in $new_files) {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($file);
        $old_folder = [IO.Path]::Combine($(Get-Location), "temp", "old", $mapping, $fileWE);
        $new_folder = [IO.Path]::Combine($(Get-Location), "temp", "new", $mapping, $fileWE);
        Get-ChildItem -Path $($old_folder + '/*.csproj') -Recurse | foreach { Remove-Item -Path $_.FullName };
        Get-ChildItem -Path $($new_folder + '/*.csproj') -Recurse | foreach { Remove-Item -Path $_.FullName };
    }


	# generate the diff, md and html files
    foreach ($file in $old_files) {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($file);

        $old_folder = [IO.Path]::Combine($(Get-Location), "temp", "old", $mapping, $fileWE);
        $new_folder = [IO.Path]::Combine($(Get-Location), "temp", "new", $mapping, $fileWE);

        $diff_folder = $([IO.Path]::Combine($diff, $mapping));
        $diff_file = $([IO.Path]::Combine($diff_folder, $fileWE + '.diff'));
        New-Item -ItemType directory -Path $diff_folder -Force;

        $md_folder = $([IO.Path]::Combine($md, $mapping));
        $md_file = $([IO.Path]::Combine($md_folder, $mapping + '.md'));
        New-Item -ItemType directory -Path $md_folder -Force;

        $html_folder = $([IO.Path]::Combine($html, $mapping));
        $html_file = $([IO.Path]::Combine($html_folder, $fileWE + '.html'));
        New-Item -ItemType directory -Path $html_folder -Force;

        git diff --no-index "$old_folder" "$new_folder" --output $diff_file;
        New-Item -ItemType file -Path $md_file -Value $("$template" -f $(Get-Content -Path $diff_file -Raw)) -Force;
        diff2html -s side -i file -- $diff_file -F $html_file;
    }
    foreach ($file in $new_files) {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($file);

        $old_folder = [IO.Path]::Combine($(Get-Location), "temp", "old", $mapping, $fileWE);
        $new_folder = [IO.Path]::Combine($(Get-Location), "temp", "new", $mapping, $fileWE);

        $diff_folder = $([IO.Path]::Combine($diff, $mapping));
        $diff_file = $([IO.Path]::Combine($diff_folder, $fileWE + '.diff'));
        New-Item -ItemType directory -Path $diff_folder -Force;

        $md_folder = $([IO.Path]::Combine($md, $mapping));
        $md_file = $([IO.Path]::Combine($md_folder, $fileWE + '.md'));
        New-Item -ItemType directory -Path $md_folder -Force;

        $html_folder = $([IO.Path]::Combine($html, $mapping));
        $html_file = $([IO.Path]::Combine($html_folder, $fileWE + '.html'));
        New-Item -ItemType directory -Path $html_folder -Force;

        git diff --no-index "$old_folder" "$new_folder" --output $diff_file;
        New-Item -ItemType file -Path $md_file -Value $("$template" -f $(Get-Content -Path $diff_file -Raw)) -Force;
        diff2html -s side -i file -- $diff_file -F $html_file;
    }
}