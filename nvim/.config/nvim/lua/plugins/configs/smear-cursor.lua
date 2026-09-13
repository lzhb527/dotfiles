-- =========================================================================
-- smear-cursor.nvim 光标拖尾动画配置
-- =========================================================================
return function()
	local smear_status, smear = pcall(require, "smear_cursor")
	if not smear_status then
		return
	end

	smear.setup({
		-- 拖尾颜色：Alacritty 会强制覆盖终端光标色，这里手动对齐绿色 #66ff66
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

		-- Fire hazard 特效参数（粒子火焰）
		particles_enabled = true,
		stiffness = 0.5,
		trailing_stiffness = 0.2,
		trailing_exponent = 5,
		damping = 0.6,
		gradient_exponent = 0,
		gamma = 1,
		never_draw_over_target = true,
		hide_target_hack = true,
		particle_spread = 1,
		particles_per_second = 500,
		particles_per_length = 50,
		particle_max_lifetime = 800,
		particle_max_initial_velocity = 20,
		particle_velocity_from_cursor = 0.5,
		particle_damping = 0.15,
		particle_gravity = -50,
		min_distance_emit_particles = 0,
	})
end
