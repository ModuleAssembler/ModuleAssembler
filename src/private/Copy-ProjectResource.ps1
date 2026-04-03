function Copy-ProjectResource {
    <#
    .SYNOPSIS
        Copy resources to module build.

    .DESCRIPTION
        Copies the contents of the resources folder, to the resources folder in the built module or optionally its root.

    .EXAMPLE
        Copy-ProjectResource

        Copy resource files to built module.
    #>

    [CmdletBinding()]
    param ()

    begin {
        $data = Get-MAProjectInfo
        $resFolder = [System.IO.Path]::Combine($data.ProjectRoot, 'src', 'resources')
    }

    process {
        if (Test-Path $resFolder) {
            $items = Get-ChildItem -Path $resFolder -ErrorAction SilentlyContinue
            if ($items) {
                Write-Verbose 'START: Copying of Module Resources.'
            } else {
                Write-Verbose 'No items present in Resources folder to copy for this module.'
                return
            }

        } else {
            return
        }

        if ($data.CopyResourcesToModuleRoot) {
            # Copy the resources folder content to the OutputModuleDir root
            foreach ($item in $items) {
                Write-Verbose "Copying $($item.Name)"
                Copy-Item -Path $item.FullName -Destination ($data.OutputModuleDir) -Recurse -Force -ErrorAction Stop
            }
        } else {
            # Copy the resources folder content to the OutputModuleDir resource folder
            Write-Verbose 'Copying resources folder.'
            Copy-Item -Path $items -Destination ($data.OutputModuleDir) -Recurse -Force -ErrorAction Stop
        }

        Write-Verbose 'COMPLETE: Copying of Module Resources.'
    }
}
