export type BIRCompileCommand = {}

export type BIRBuildObject = {}

export type BIRLinkCrates = {}

const build_ir = {}

function build_ir.emit_compile_command() end

function build_ir.emit_build_object() end

function build_ir.emit_crate_link() end

return table.freeze(build_ir)
