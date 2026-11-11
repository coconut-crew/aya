const action_ty = require("@aya/pkg/pkg_types")

const git = {}

function git.install_package_to(action: action_ty.GitInstallPackage) end

function git.remove_package(action: action_ty.GitRemovePackage) end

return table.freeze(git)
