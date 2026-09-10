return function()
	local ok, oil = pcall(require, "oil")
	if not ok then
		return
	end

	oil.setup({
		default_file_explorer = false, -- 不接管文件浏览（侧边栏由 snacks.explorer 承担）
		view_options = {
			show_hidden = true, -- 显示隐藏文件
		},
		float = {
			padding = 2,
			max_width = 100,
			max_height = 20,
			border = "rounded",
		},
	})

	-- snacks.rename 联动：用 oil 移动/重命名文件后，自动更新项目里所有引用
	vim.api.nvim_create_autocmd("User", {
		pattern = "OilActionsPost",
		callback = function(event)
			if event.data.actions.type == "move" then
				local snacks_ok, snacks = pcall(require, "snacks")
				if snacks_ok then
					snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
				end
			end
		end,
	})
end
