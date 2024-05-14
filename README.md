#### Disclaimer
-- Some of the readme based on the provided code from this repo, while testing the plugin's capabilities and progress.
(so you might find mistakes)

---

# die-shchnecke.nvim

Meaning:
1. The name comes from German, which means "**The Snail**".
2. It represents my learning/developing process (and the fact I recently moved to Berlin), specifically for this plugin. (Not rushing, but learning).

Neovim plugin designed to enhance your coding experience by integrating with the Ollama service for code completion, 
refactoring, and documentation generation.

Tested with Ollama models: `llama3:instruct`, `codellama:7b-code` and `dolphincoder:15b-starcoder2`


## Features

- **Chat Interface**: Chat with the Ollama model to get code suggestions, improvements, and more.
- **Code Preview**: View code previews directly within the Neovim editor.
- **Customizable Prompts**: Choose from various prompts for code completion, refactoring, and documentation.
- **Extensible**: Easily extend the functionality by adding new prompts or modifying existing ones.
- **Compatible** with Ollama models.

## Installation

### Using Lazy

```lua
{ 'downzed/die-schnecke.nvim' }
```

### Using Vim-Plug

```vim
Plug 'downzed/die-schnecke.nvim'
```

## Usage

### Commands

- `:OpenDieSchnecke` - Open the Die Schnecke interface.
- `:OpenDieSchneckeWithSelectedCode` - Open Die Schnecke with the currently selected code with a preview.

### Keybindings

You can customize keybindings in your Neovim configuration. The default keybindings are:

```lua
vim.api.nvim_set_keymap('n', '<leader>xq', ':lua require("die-schnecke").open()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('x', '<C-e>', ':lua require("die-schnecke").chat_with_code()<CR>', { noremap = true, silent = true })
```

### Configuration

You can customize Die Schnecke by passing a configuration table to the `setup` function:

```lua
require('die-schnecke').setup{
  llama = {
    model  = "llama3:instruct",
    stream = true,
    port   = "11434"
  },
}
```

## API

die-schnecke.nvim will expose several functions that you can use in your configuration or other plugins.
for example:
- `open`: open die-schnecke interface in chat mode
- `chat_with_code`: open die-schnecke interface with latest yanked code in preview mode


## Next Features, WIP

- Expose relevant API functions, and or classes
- Code completion engine
- Prompts:
    - Specific model for specific "task"
    - Function calling

## Known Issues 
- win+buf regenaration
- running jobs of the ollama server in the background

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

