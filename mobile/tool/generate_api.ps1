# Windows wrapper: runs generate_api.sh through Git Bash (same pinned generator command).
$root = Resolve-Path "$PSScriptRoot\.."
bash "$root\tool\generate_api.sh"
