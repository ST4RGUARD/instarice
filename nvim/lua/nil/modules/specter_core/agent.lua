local tools = require("nil.modules.specter_core.tools")
local safety = require("nil.modules.specter_core.safety")
local ui = require("nil.modules.specter_core.ui")
local session = require("nil.modules.specter_core.session")
local core_model = require("nil.modules.specter_core.core_model")
local utils = require("nil.modules.specter_core.utils")
local workspace = require("nil.modules.specter_core.workspace")
local diff_view = require("nil.modules.specter_core.diff_view")
local graph = require("nil.modules.specter_core.semantic_graph")
local refactor_ui = require("nil.modules.specter_core.refactor_ui")

local M = {}

M.config = {
    max_steps = 25,
}

local running = false

local function trace(msg)
    vim.schedule(function()
        vim.notify("[SPECTER] " .. msg)
    end)
end

local function disambiguate_choice(candidates, callback)
    vim.schedule(function()
        vim.ui.select(candidates, {
            prompt = "Specter: Multiple matches found. Please select target:",
            format_item = function(item)
                return string.format("%s (Score: %d)", vim.fn.fnamemodify(item.file, ":."), item.score)
            end,
        }, function(choice)
            if choice then
                callback(choice.file)
            else
                trace("Ambiguity resolution cancelled.")
                callback(nil)
            end
        end)
    end)
end

local function check_impact_and_run(plan, input)
    local impact_map = {}
    local has_impact = false

    for _, step in ipairs(plan.steps) do
        if step.args and step.args.symbol then
            local impacted_files = graph.get_impacted_files(step.args.symbol)
            if #impacted_files > 0 then
                impact_map[step.args.symbol] = impacted_files
                has_impact = true
            end
        end
    end

    if has_impact then
        refactor_ui.show_blast_radius(impact_map, function(proceed_full)
            if proceed_full then
                for symbol, files in pairs(impact_map) do
                    for _, f in ipairs(files) do
                        table.insert(plan.steps, 1, {
                            tool = "repo.read",
                            args = { file = f },
                            reason = "Analyzing impact for multi-file refactor of " .. symbol
                        })
                    end
                end
            end
            M.start_execution(plan, input)
        end)
    else
        M.start_execution(plan, input)
    end
end

local function execute_tool_async(step, context, callback)
    trace("STEP → " .. step.tool)
    ui.tool(step)
    if ui.active then ui.active() end

    local res = tools.execute(step, context)
    if not res.ok then
        ui.result("❌ " .. tostring(res.error))
        callback(nil)
        return
    end

    local result = res.result

    if result == "PROMPT_MODE" and res.payload then
        vim.schedule(function()
            if ui.active then ui.active() end
        end)

        core_model.generate_text_async(res.payload, function(async_result)
            if type(async_result) == "string" then
                async_result = utils.decode_newlines(async_result)
            end
            context.last_content = async_result
            ui.result(async_result)
            callback(async_result)
        end)
        return
    end

    if type(result) == "string" then
        result = utils.decode_newlines(result)
    end

    if step.tool == "repo.read" then
        context.last_content = result
        context.file = step.args and step.args.path or context.file

    elseif step.tool == "repo.search" and type(result) == "table" then
        context.last_result = result

        -- Format results as readable lines grouped by file
        local seen_files = {}
        local lines = {}
        local file_count = 0

        for _, match in ipairs(result) do
            local short = vim.fn.fnamemodify(match.path or "", ":~:.")
            if not seen_files[short] then
                seen_files[short] = true
                file_count = file_count + 1
                table.insert(lines, "")
                table.insert(lines, "  📄 " .. short)
            end
            if match.line and match.snippet then
                local snippet = (match.snippet or ""):gsub("^%s+", "")
                table.insert(lines, string.format("    %d: %s", match.line, snippet))
            end
        end

        local header = string.format("Found %d match%s in %d file%s:",
            #result, #result == 1 and "" or "es",
            file_count, file_count == 1 and "" or "s")

        ui.result(header .. table.concat(lines, "\n"))
        callback(result)
        return

    else
        context.last_result = result
    end

    ui.result(result)
    callback(result)
end

function M.run(input)
    if running then return end
    running = true

    ui.open()
    ui.clear()
    if ui.active then ui.active() end
    session.start(input)

    local files_to_index = {}
    local seen = {}

    -- WORKSPACE ROOT DETECTION: 
    -- This ensures that in a monorepo, we find the closest project marker relative to the file you are editing.
    local root = vim.fn.getcwd()
    local current_buf = vim.api.nvim_get_current_buf()
    local current_file = vim.api.nvim_buf_get_name(current_buf)
    
    if current_file ~= "" and not current_file:match("specter") then
        local project_markers = {'Cargo.toml', 'go.mod', 'package.json', '.git'}
        local root_match = vim.fs.find(project_markers, { path = current_file, upward = true })[1]
        if root_match then
            root = vim.fs.dirname(root_match)
            trace("Targeting Project Root: " .. root)
        end
    end

    local bufs = vim.api.nvim_list_bufs()
    for _, b in ipairs(bufs) do
        if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buftype == "" then
            local name = vim.api.nvim_buf_get_name(b)
            if name ~= "" and not seen[name] then
                table.insert(files_to_index, { file = name, lang = vim.bo[b].filetype })
                seen[name] = true
            end
        end
    end

    local extensions = { "rs", "go", "py", "ts", "js", "lua" }
    trace("Indexing Workspace: " .. vim.fn.fnamemodify(root, ":~"))

    for _, ext in ipairs(extensions) do
        local found = vim.fn.globpath(root, "**/*." .. ext, false, true)
        for _, path in ipairs(found) do
            if not path:find("/target/") and not path:find("/.git/") and not seen[path] then
                -- Load buffers for indexing if not already loaded
                local b = vim.fn.bufadd(path)
                vim.fn.bufload(b)
                table.insert(files_to_index, { file = path, lang = vim.bo[b].filetype })
                seen[path] = true
            end
        end
    end

    trace("Indexing " .. #files_to_index .. " files...")
    graph.reindex_all(files_to_index)

    local plan = core_model.process(input)
    if not plan or not plan.steps then
        ui.log("❌ Failed to generate plan.")
        running = false
        if ui.done then ui.done() end
        return
    end

    -- Attach detected root to the plan so tools know where to search
    plan.workspace_root = root

    if plan.is_ambiguous and plan.candidates then
        disambiguate_choice(plan.candidates, function(chosen_file)
            if not chosen_file then
                M.stop()
                return
            end
            for _, step in ipairs(plan.steps) do
                if step.args and step.args.file == nil then
                    step.args.file = chosen_file
                end
            end
            check_impact_and_run(plan, input)
        end)
    else
        check_impact_and_run(plan, input)
    end
end

function M.start_execution(plan, input)
    ui.log("📋 Executing Plan")
    
    local context = { 
        input = input,
        cwd = plan.workspace_root
    }

    local function run_step(step_index)
        local step = plan.steps[step_index]

        if not running or not step or step_index > M.config.max_steps then
            running = false
            vim.defer_fn(function()
                ui.log("🏁 Done")
                if ui.done then ui.done() end
                if vim.tbl_count(workspace.list()) > 0 then
                    diff_view.show()
                end
            end, 1000)
            return
        end

        ui.step(step_index)

        if not safety.allow(step.tool, step.args) then
            ui.log("⛔ Blocked: " .. step.tool)
            running = false
            if ui.done then ui.done() end
            return
        end

        execute_tool_async(step, context, function(result)
            if result == nil then
                running = false
                if ui.done then ui.done() end
                return
            end

            session.add_step({
                step = step_index,
                action = step,
                result = result,
            })

            vim.schedule(function()
                run_step(step_index + 1)
            end)
        end)
    end

    run_step(1)
end

function M.stop()
    running = false
    if ui.done then ui.done() end
end

return M
