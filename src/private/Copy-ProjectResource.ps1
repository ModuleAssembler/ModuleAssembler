function Copy-ProjectResource {
    <#
    .SYNOPSIS
        Copy resources to module build.

    .DESCRIPTION
        Copies the contents of the resources folder, to the resources folder in the built module or optionally its root.

    .EXAMPLE
        Copy resource files to built module.
        Copy-ProjectResource
    #>

    [CmdletBinding()]
    param ()

    begin {
        $data = Get-MAProjectInfo
        $resFolder = [System.IO.Path]::Combine($data.ProjectRoot, 'src', 'resources')

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
    }

    process {
        if ($data.copyResourcesToModuleRoot) {
            # Copy the resources folder content to the OutputModuleDir root
            foreach ($item in $items) {
                Write-Verbose "Copying $($item.Name)"
                Copy-Item -Path $item.FullName -Destination ($data.OutputModuleDir) -Recurse -Force -ErrorAction Stop
            }
        } else {
            # Copy the resources folder content to the OutputModuleDir resource folder
            if (Get-ChildItem $resFolder -ErrorAction SilentlyContinue) {
                Write-Verbose 'Copying resources folder.'
                Copy-Item -Path $resFolder -Destination ($data.OutputModuleDir) -Recurse -Force -ErrorAction Stop
            }
        }
    }

    end {
        Write-Verbose 'COMPLETE: Copying of Module Resources.'
    }
}
