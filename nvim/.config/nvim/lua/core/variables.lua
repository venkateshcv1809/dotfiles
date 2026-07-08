
local has_env, env = pcall(require, "env")
if not has_env then
    _, env = pcall(require, "env-example")
end

if type(env) == "table" then
    for key, value in pairs(env) do
        vim.g[key] = value
    end
end