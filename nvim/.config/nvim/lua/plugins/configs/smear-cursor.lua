-- =========================================================================
-- smear-cursor.nvim 光标拖尾动画配置（kitty 渐隐拖尾风格）
-- =========================================================================
return function()
	local smear_status, smear = pcall(require, "smear_cursor")
	if not smear_status then
		return
	end

	smear.setup({
		-- 默认关闭拖尾特效，按 <leader>uc 手动开启
		enabled = false,

		-- 拖尾颜色：kitty 光标色，手动对齐绿色 #66ff66
		cursor_color = "#66ff66",

		-- 半透明底色下的阴影回退色，与终端/主题底色保持一致
		transparent_bg_fallback_color = "#0a0a0a",

		-- JetBrainsMono Nerd Font 不支持 legacy computing 符号，保持关闭避免块状错位
		legacy_computing_symbols_support = false,

		-- 滚动时在缓冲区空间绘制，更顺滑
		scroll_buffer_space = true,

		-- 插入模式也带拖尾
		smear_insert_mode = true,

		-- 帧间隔（ms），约 60fps，性能与顺滑的平衡点
		time_interval = 17,

		-- kitty 拖尾无粒子，显式关闭
		particles_enabled = false,

		-- kitty 风格渐隐拖尾：头部跟手、尾巴滞后拉出拖尾
		stiffness = 0.7,
		trailing_stiffness = 0.3,
		damping = 0.8,

		-- 中间点更靠近尾部，拖尾更长
		trailing_exponent = 4,

		-- 头到尾纵向渐变，模拟 kitty 的 decay 渐隐
		gradient_exponent = 2,
		gamma = 2.2,

		-- 允许更长的拖尾
		max_length = 30,

		-- 插入模式同样跟手并带拖尾
		stiffness_insert_mode = 0.6,
		trailing_stiffness_insert_mode = 0.4,
		damping_insert_mode = 0.9,
	})
end
