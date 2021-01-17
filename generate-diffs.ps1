param ($old_version_folder, $new_version_folder);

if ([string]::IsNullOrEmpty($old_version_folder)) {
	Write-Host "old_version_folder was not provided! Exiting...";
	exit;	
}
if ([string]::IsNullOrEmpty($new_version_folder)) {
	Write-Host "new_version_folder was not provided! Exiting...";
	exit;	
}

Write-Output  "Installing tools..."
dotnet tool install ilspycmd -g;
npm install -g diff2html-cli;

Write-Output  "Started..."
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
New-Item -ItemType directory -Path $diff -Force | Out-Null;
New-Item -ItemType directory -Path $md -Force | Out-Null;
New-Item -ItemType directory -Path $html -Force | Out-Null;

$old_folders = Get-ChildItem -Path $old_version_folder;
$new_folders = Get-ChildItem -Path $new_version_folder;

$old_main_bin_path = [IO.Path]::Combine($old_version_folder, 'bannerlord.referenceassemblies.core.earlyaccess');
$new_main_bin_path = [IO.Path]::Combine($new_version_folder, 'bannerlord.referenceassemblies.core.earlyaccess');

$i = 0;
foreach ($key in $mappings.Keys) {
    $i++;
    $mapping = $mappings[$key];
    $old_folder = $old_folders[$i - 1];
    $new_folder = $new_folders[$i - 1];
	
	if ([string]::IsNullOrEmpty($old_folder)) {
	    Write-Host "old_folder was not found!";
	    continue;	
    }
	if ([string]::IsNullOrEmpty($new_folder)) {
	    Write-Host "old_folder was not found!";
	    continue;	
    }
	
    Write-Output  "Handling $mapping..."
	
    $old_path = [IO.Path]::Combine($old_version_folder, $old_folder);
    $new_path = [IO.Path]::Combine($new_version_folder, $new_folder);

    $old_files = Get-ChildItem -Path $($old_path + '/*.dll') -Recurse -Exclude $excludes;
    $new_files = Get-ChildItem -Path $($new_path + '/*.dll') -Recurse -Exclude $excludes;


    # generate source code based on the Public API
	Write-Output  "Generating Stable source code..."
    $old_files | ForEach-Object -Parallel {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($_);

        $old_folder  = [IO.Path]::Combine($($using:old), $($using:mapping), $fileWE);
        New-Item -ItemType directory -Path $old_folder -Force | Out-Null;

        Write-Output  "Generating for $fileWE...";
        ilspycmd "$($_.FullName)" --project --outputdir "$old_folder" --referencepath "$($using:old_main_bin_path)";
    }
	Write-Output  "Generating Beta source code..."
    $new_files | ForEach-Object -Parallel {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($_);

        $new_folder  = [IO.Path]::Combine($($using:new), $($using:mapping), $fileWE);
        New-Item -ItemType directory -Path $new_folder -Force | Out-Null;

        Write-Output  "Generating for $fileWE...";
        ilspycmd "$($_.FullName)" --project --outputdir "$new_folder" --referencepath "$($using:old_main_bin_path);";
    }


    # delete csproj files
	Write-Output  "Deleting csproj's..."
    foreach ($file in $old_files) {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($file);
        $old_folder = [IO.Path]::Combine($(Get-Location), "temp", "old", $mapping, $fileWE);
        $new_folder = [IO.Path]::Combine($(Get-Location), "temp", "new", $mapping, $fileWE);
        Get-ChildItem -Path $($old_folder + '/*.csproj') -Recurse -ErrorAction SilentlyContinue | foreach { Remove-Item -Path $_.FullName };
        Get-ChildItem -Path $($new_folder + '/*.csproj') -Recurse -ErrorAction SilentlyContinue | foreach { Remove-Item -Path $_.FullName };
    }
    foreach ($file in $new_files) {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($file);
        $old_folder = [IO.Path]::Combine($(Get-Location), "temp", "old", $mapping, $fileWE);
        $new_folder = [IO.Path]::Combine($(Get-Location), "temp", "new", $mapping, $fileWE);
        Get-ChildItem -Path $($old_folder + '/*.csproj') -Recurse -ErrorAction SilentlyContinue | foreach { Remove-Item -Path $_.FullName };
        Get-ChildItem -Path $($new_folder + '/*.csproj') -Recurse -ErrorAction SilentlyContinue | foreach { Remove-Item -Path $_.FullName };
    }


	# generate the diff, md and html files
	Write-Output  "Generating diff's..."
    foreach ($file in $old_files) {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($file);

        $old_folder = [IO.Path]::Combine($(Get-Location), "temp", "old", $mapping, $fileWE);
        $new_folder = [IO.Path]::Combine($(Get-Location), "temp", "new", $mapping, $fileWE);

        $diff_folder = $([IO.Path]::Combine($diff, $mapping));
        $diff_file = $([IO.Path]::Combine($diff_folder, $fileWE + '.diff'));
        New-Item -ItemType directory -Path $diff_folder -Force | Out-Null;

        $md_folder = $([IO.Path]::Combine($md, $mapping));
        $md_file = $([IO.Path]::Combine($md_folder, $mapping + '.md'));
        New-Item -ItemType directory -Path $md_folder -Force | Out-Null;

        $html_folder = $([IO.Path]::Combine($html, $mapping));
        $html_file = $([IO.Path]::Combine($html_folder, $fileWE + '.html'));
        New-Item -ItemType directory -Path $html_folder -Force | Out-Null;

        Write-Output  "Generating for $fileWE...";
        git diff --no-index "$old_folder" "$new_folder" --output $diff_file;
        New-Item -ItemType file -Path $md_file -Value $("$template" -f $(Get-Content -Path $diff_file -Raw)) -Force | Out-Null;
        diff2html -i file -- $diff_file -F $html_file;
    }
    foreach ($file in $new_files) {
        $fileWE = [IO.Path]::GetFileNameWithoutExtension($file);

        $old_folder = [IO.Path]::Combine($(Get-Location), "temp", "old", $mapping, $fileWE);
        $new_folder = [IO.Path]::Combine($(Get-Location), "temp", "new", $mapping, $fileWE);

        $diff_folder = $([IO.Path]::Combine($diff, $mapping));
        $diff_file = $([IO.Path]::Combine($diff_folder, $fileWE + '.diff'));
        New-Item -ItemType directory -Path $diff_folder -Force | Out-Null;

        $md_folder = $([IO.Path]::Combine($md, $mapping));
        $md_file = $([IO.Path]::Combine($md_folder, $fileWE + '.md'));
        New-Item -ItemType directory -Path $md_folder -Force | Out-Null;

        $html_folder = $([IO.Path]::Combine($html, $mapping));
        $html_file = $([IO.Path]::Combine($html_folder, $fileWE + '.html'));
        New-Item -ItemType directory -Path $html_folder -Force | Out-Null;

        Write-Output  "Generating for $fileWE...";
        git diff --no-index "$old_folder" "$new_folder" --output $diff_file;
        New-Item -ItemType file -Path $md_file -Value $("$template" -f $(Get-Content -Path $diff_file -Raw)) -Force | Out-Null;
        diff2html -i file -- $diff_file -F $html_file;
    }
	
	$i++;
}