" May need latest version of neovim:
" brew upgrade neovim
"
" Packer commands:
" :PackerInstall
" :PackerSync
" :PackerClean
"
" Other commands:
" :Mason 
" :TSInstall vim
" :TSUpdate
"
" Load packer
lua require('plugins')

" Packer plugins setup
lua << END
  require('lualine').setup({
    sections = {
      lualine_a = {'mode'},
      lualine_b = {},
      lualine_c = {'filename'},
      lualine_x = {'location'},
      lualine_y = {},
      lualine_z = {}
    }
  })
  require('gitsigns').setup()

  -- Auto lint on save (eslint):
  -- Need to run this first before the below works
  -- npm i -g vscode-langservers-extracted
  -- require'lspconfig'.eslint.setup({
  --   on_attach = function(client, bufnr)
  --     vim.api.nvim_create_autocmd("BufWritePre", {
  --       buffer = bufnr,
  --       command = "EslintFixAll",
  --     })
  --   end,
  -- })

  -- This is needed for biome to help apply the edits synchronously
  -- https://zenn.dev/izumin/articles/b8046e64eaa2b5
	local function execute_code_action_sync(client, bufnr, action)
		local params = vim.lsp.util.make_range_params()
		params.context = { only = { action }, diagnostics = {} }
		local result = client.request_sync("textDocument/codeAction", params, 3000, bufnr)
		for _, res in pairs(result and result.result or {}) do
			if res.edit then
				local encoding = client.offset_encoding or "utf-16"
				vim.lsp.util.apply_workspace_edit(res.edit, encoding)
			end
		end
	end

	local function organize_imports_sync(client, bufnr)
		execute_code_action_sync(client, bufnr, "source.organizeImports")
	end

	local function fix_all_sync(client, bufnr)
		execute_code_action_sync(client, bufnr, "source.fixAll")
	end

  -- Auto lint on save (biome):
  -- Attach Biome LSP
  require'lspconfig'.biome.setup({
    on_attach = function(client, bufnr)
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function(args)
          local bufnr = args.buf
          for _, client in pairs(vim.lsp.get_active_clients({ bufnr = bufnr })) do
            if client.name == "biome" then
              organize_imports_sync(client, bufnr)
              fix_all_sync(client, bufnr)
              vim.lsp.buf.format({ bufnr = bufnr, async = false })
            end
          end
        end,
      })
    end,
  })

  -- prettier
  local status, prettier = pcall(require, "prettier")
  if (not status) then return end

  prettier.setup {
    bin = 'prettierd',
    filetypes = {
      "css",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "json",
      "scss",
      "less"
    }
  }

  require('nvim-ts-autotag').setup({})

  -- autopairs
	local status, autopairs = pcall(require, "nvim-autopairs")
	if (not status) then return end

	autopairs.setup({
		disable_filetype = { "TelescopePrompt" , "vim" },
	})

  -- lsp setup
  local status, cmp = pcall(require, "cmp")
  if (not status) then return end
  local lspkind = require 'lspkind'

  cmp.setup({
    snippet = {
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-d>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.close(),
      ['<CR>'] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
        select = true
      }),
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'buffer' },
    }),
    formatting = {
      format = lspkind.cmp_format({ with_text = false, maxwidth = 50 })
    }
  })

  vim.cmd [[
    set completeopt=menuone,noinsert,noselect
    highlight! default link CmpItemKind CmpItemMenuDefault
  ]]

  -- nvim-treesitter setup
  local status, ts = pcall(require, "nvim-treesitter.configs")
  if (not status) then return end

  ts.setup {
    highlight = {
      enable = true,
      disable = {},
    },
    indent = {
      enable = true,
      disable = {},
    },
    ensure_installed = {
      "bash",
      "javascript",
      "tsx",
      "json",
      "yaml",
      "css",
      "html",
      "lua",
      "prisma",
      "solidity",
      "typescript"
    },
  }

  local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
  parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }

  -- lspconfig setup
  local status, nvim_lsp = pcall(require, "lspconfig")
  if (not status) then return end

  local protocol = require('vim.lsp.protocol')

  local on_attach = function(client, bufnr)
    -- Format on save. Currently disabled since we're using eslint.
    -- if client.server_capabilities.documentFormattingProvider then
    --   vim.api.nvim_create_autocmd("BufWritePre", {
    --     group = vim.api.nvim_create_augroup("Format", { clear = true }),
    --     buffer = bufnr,
    --     callback = function() vim.lsp.buf.format() end
    --   })
    -- end
    client.server_capabilities.documentFormattingProvider = false

    local buf_map = function(mode, lhs, rhs, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    
    buf_map('n', '<leader>ca', vim.lsp.buf.code_action) -- Trigger code actions
  end

  -- JSON
  -- Run this first:
  -- npm i -g vscode-langservers-extracted
  require'lspconfig'.jsonls.setup{}

  -- Biome
  -- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#biome
  -- require'lspconfig'.biome.setup{}

  -- TypeScript
  local capabilities = require('cmp_nvim_lsp').default_capabilities()
  nvim_lsp.ts_ls.setup {
    on_attach = on_attach,
    filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
    cmd = { "typescript-language-server", "--stdio" },
    capabilities = capabilities,
    handlers = {
      -- pick the first response to a go to definition response. that way we go straight to the
      -- source definition without needing to choose from the type definition .d.ts file
      ["textDocument/definition"] = function(err, result, ...)
        result = vim.tbl_islist(result) and result[1] or result
        vim.lsp.handlers["textDocument/definition"](err, result, ...)
      end,
    },
  } 

  -- Python
  nvim_lsp.pyright.setup {
    on_attach = on_attach,
  }

  -- Mason setup
  local status, mason = pcall(require, "mason")
  if (not status) then return end
  local status2, lspconfig = pcall(require, "mason-lspconfig")
  if (not status2) then return end

  mason.setup({})

  lspconfig.setup {
    ensure_installed = { "lua_ls", "tailwindcss", "rust_analyzer", "pyright" },
  }

  -- Setup tailwind
  nvim_lsp.tailwindcss.setup {}

  -- Telescope setup
  local status, telescope = pcall(require, "telescope")
  if (not status) then return end
  local actions = require('telescope.actions')
  local builtin = require("telescope.builtin")

  local function telescope_buffer_dir()
    return vim.fn.expand('%:p:h')
  end

  telescope.setup {
    defaults = {
      mappings = {
        n = {
          ["q"] = actions.close
        },
        i = {
          -- Allows moving the cursor to front/end of line in insert mode
          -- when the file finder is open
          ["<C-a>"] = { "<Home>", type = "command" },
          ["<C-e>"] = { "<End>", type = "command" },
          -- Can also send custom commands like so:
          --["<C-a>"] = function()
            -- Neovim lua api to send vim commands
            -- vim.cmd [[normal! 0]]
          --end,
          --["<C-e>"] = function()
            -- vim.cmd [[normal! $]]
          --end,
        },
      },
    },
  }

  -- keymaps
  vim.keymap.set('n', ';f',
    function()
      builtin.find_files({
        no_ignore = false,
        hidden = true
      })
    end)
  vim.keymap.set('n', ';r', function()
    builtin.live_grep()
  end)
  vim.keymap.set("n", ";R", ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>")
  vim.keymap.set('n', '\\\\', function()
    builtin.buffers()
  end)
  vim.keymap.set('n', ';t', function()
    builtin.help_tags()
  end)
  vim.keymap.set('n', ';;', function()
    builtin.resume()
  end)
  vim.keymap.set('n', ';e', function()
    builtin.diagnostics()
  end)

  -- Gruvbox setup
  -- Must be called before loading the colorscheme
  require("gruvbox").setup({
    contrast = "hard",
  })

  -- tmux navigator
  require('Navigator').setup()
  vim.keymap.set({'n', 't'}, '<C-h>', '<CMD>NavigatorLeft<CR>')
  vim.keymap.set({'n', 't'}, '<C-l>', '<CMD>NavigatorRight<CR>')
  vim.keymap.set({'n', 't'}, '<C-k>', '<CMD>NavigatorUp<CR>')
  vim.keymap.set({'n', 't'}, '<C-j>', '<CMD>NavigatorDown<CR>')

  -- Show diagnostics on hover
  vim.o.updatetime = 250  -- Faster CursorHold trigger
  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
    local diagnostics = vim.diagnostic.get()
    if diagnostics and #diagnostics > 0 then
      vim.diagnostic.open_float(nil, { focus = false })
      end
    end
  })
END

" Ignore casing when searching
set ignorecase

" Use VIM settings, rather than VI settings
set nocompatible

" Search highlighting
set hlsearch

" Enable syntax highlighting
syntax on

" Line numbers
set nu

" Set leader
let mapleader = ","

" Open nerdtree to current file
nmap <Bar> :NERDTreeFind<CR>

" Show hidden files
let NERDTreeShowHidden=1

" Open current buffer in new tab
nnoremap <silent> <Leader>t :tab split<CR>

" Clear all marks
nnoremap <silent> <Leader>M :MarkClear<CR>

" Set available mark palette
let g:mwDefaultHighlightingPalette='maximum'

" Widen/shrink split buffer with + and -
if bufwinnr(1)
  map + <c-W>>
  map - <c-W><
endif

" 2 spaces for indenting
set shiftwidth=2

" 2 stops
set tabstop=2

" Spaces instead of tabs
set expandtab

" Show the matching bracket for the last ')'?
set showmatch

" Do not keep a backup files 
set nobackup
set nowritebackup

" Show the cursor position all the time
set ruler

" Set status line
set statusline=[%02n]\ %f\ %(\[%M%R%H]%)%=\ %4l,%02c%2V\ %P%*

" Always display a status line at the bottom of the window
set laststatus=2

" Give some more height when showing commands
set cmdheight=2

" Show (partial) commands
set showcmd

" Use j/k to escape
:imap jk <Esc>

" Gruvbox colorscheme
colorscheme gruvbox
set background=dark
