local ts = vim.treesitter
local M = {}

local function load_cursor_tree(cursor_node, isNext)
    local detail = ""
    if cursor_node then
        local type = cursor_node:type()
        local node_text = ts.get_node_text(cursor_node, 0)
        detail = detail .. "Cursor Node Type: " .. type
        detail = detail .. "\nCursor Node Text:" .. node_text

        if type == node_text then detail = detail .. "\nEqual" end
        local parent = cursor_node:parent()
        if parent then
            print()
            detail = detail .. "\nParent Node Type:" .. parent:type()
        end
    end
    detail = detail .. "\n"
    if isNext then
        local next_node = cursor_node:next_named_sibling()
        if next_node then
            detail = detail .. "\nNext Node Type: " .. next_node:type()
            detail = detail .. "\nCursor Node Text:" .. ts.get_node_text(next_node, 0)
            local parent = next_node:parent()
            if parent then
                print()
                detail = detail .. "\nParent Node Type:" .. parent:type()
            end
        end
    else
        local prev_node = cursor_node:prev_named_sibling()
        if prev_node then
            detail = detail .. "\nPrev Node Type: " .. prev_node:type()
            detail = detail .. "\nCursor Node Text:" .. ts.get_node_text(prev_node, 0)
            local parent = prev_node:parent()
            if parent then
                print()
                detail = detail .. "\nParent Node Type:" .. parent:type()
            end
        end
    end

    show_custom_notification(detail)
end

-- Function to move to the next TreeSitter node
function M.go_to_next_node()
    local parser = vim.treesitter.get_parser(0)
    local tree = parser:parse()[1]
    local root = tree:root()

    -- Find the current node at the cursor position
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local current_node = root:descendant_for_range(row - 1, col, row - 1, col)
    if not current_node then return nil end

    -- Recursive function to find the next node
    local function find_next_node(node)
        local next_node = node:next_named_sibling()
        if next_node then
            return next_node
        else
            local parent = node:parent()
            if parent then return find_next_node(parent) end
        end
        return nil
    end

    -- Find the next node starting from the current node
    local next_node = find_next_node(current_node)

    if next_node then
        local start_row, start_col, _, _ = next_node:range()
        vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    else
        print "No next node found"
    end
end

-- Function to move to the previous TreeSitter node
function M.go_to_prev_node()
    local parser = vim.treesitter.get_parser(0)
    local tree = parser:parse()[1]
    local root = tree:root()

    -- Find the current node at the cursor position
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local current_node = root:descendant_for_range(row - 1, col, row - 1, col)
    if not current_node then return nil end

    -- Find the lowest Named Child of the Node
    local function find_lowest_named_child(node, isFirst)
        local children = node:named_children()
        if children and #children > 0 then
            if isFirst then
                return find_lowest_named_child(children[1], isFirst)
            else
                return find_lowest_named_child(children[#children], isFirst)
            end
        else
            return node
        end
    end

    -- Recursive function to find the previous node
    local function find_prev_node(node)
        local prev = node:prev_named_sibling()
        if prev then
            return find_lowest_named_child(prev, false)
        else
            local parent = node:parent()
            if parent then
                local start_row, start_col, _, _ = parent:range()
                if start_row ~= row and start_col ~= col then
                    return parent
                else
                    return find_prev_node(parent)
                end
            end
        end
    end

    -- Find the previous node starting from the current node
    local prev_node = find_prev_node(current_node)
    if prev_node then
        local start_row, start_col, _, _ = prev_node:range()
        vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    else
        print "No previous node found"
    end
end

local astro_notify = require "astronvim.notify"

-- Function to show a custom print statement as a notification
function show_custom_notification(message) astro_notify.notify(message, "info", { title = "Custom Notification" }) end

return M
