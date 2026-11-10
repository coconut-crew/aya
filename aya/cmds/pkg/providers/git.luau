const action_ty = require("@aya/cmds/pkg/providers/action_ty")

const git = {}

function git.install_package_to(action: action_ty.GitInstallPackage) end

function git.remove_package(action: action_ty.GitRemovePackage) end

return table.freeze(git)
