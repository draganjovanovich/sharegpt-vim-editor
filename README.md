# JSONL UI ShareGPT Editor Plugin for Vim


https://github.com/draganjovanovich/sharegpt-vim-editor/assets/13547364/4fae9c07-44ae-42e1-9dbc-591276f3d743


## Overview
This Vim plugin provides a UI for editing JSONL (JSON Lines) files, specifically tailored for ShareGPT conversations. It includes features like navigation through JSONL entries, custom syntax highlighting, and in-place editing of JSONL data.

## Features
- **Navigation**: Move through JSONL entries with Up/Down arrow keys.
- **Editing**: Edit JSONL entries directly in the UI buffer.
- **Syntax Highlighting**: Custom syntax highlighting for different parts of the conversation (SYSTEM, HUMAN, GPT).
- **Saving**: Save changes back to the original JSONL file with :W

## Installation
1. Copy the plugin files to your Vim plugin directory.
2. Open a `.jsonl` file and the plugin will load automatically.

## Usage
- Use the `Down` arrow key to move to the next JSONL entry.
- Use the `Up` arrow key to move to the previous JSONL entry.
- Edit the content in the Vim buffer.
- Press `:W` to save changes to the current JSONL entry.

## Dependencies
- Vim with JSON support (for `json_decode` and `json_encode` functions).

## Note:  
It's far from perfect as I am not exactly a "vim script" expert, use at your own risk and discretion, and consider testing in a controlled environment before applying it to critical tasks.
If you find it useful and improved it, please feel free to submit PR
