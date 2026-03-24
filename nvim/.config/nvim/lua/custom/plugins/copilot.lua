return {
	'github/copilot.vim',
	init = function()
		-- Copilot (github/copilot.vim) cria um mapeamento em insert para `<Tab>` aceitar a sugestão atual.
		-- Se `<Tab>` já estiver mapeado por outro plugin/config, o Copilot usa esse mapeamento existente
		-- como fallback quando NÃO há sugestão visível.
		--
		-- Estas são as opções atuais para controlar isso:
		-- - `vim.g.copilot_no_tab_map = true`  -> não mexe no `<Tab>`
		-- - `vim.g.copilot_no_maps = true`     -> desativa todos os mapas padrão do Copilot
		--
		-- Observação: `vim.g.copilot_assume_mapped` era uma opção legada e não consta mais na documentação atual.
		vim.g.copilot_no_tab_map = false
		vim.g.copilot_no_maps = false
	end,
}