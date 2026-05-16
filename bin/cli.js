#!/usr/bin/env node
'use strict';

const fs   = require('fs');
const path = require('path');
const os   = require('os');

const CLAUDE_DIR   = path.join(os.homedir(), '.claude');
const SETTINGS     = path.join(CLAUDE_DIR, 'settings.json');
const TARGET       = path.join(CLAUDE_DIR, 'statusline-command.sh');
const SCRIPT_SRC   = path.join(__dirname, '..', 'statusline-command.sh');

// ── Dependency check ────────────────────────────────────────────────────────
const { execSync } = require('child_process');

function checkDep(cmd) {
  try {
    execSync(`command -v ${cmd}`, { stdio: 'ignore' });
  } catch {
    console.error(`\nError: '${cmd}' is required but not found.`);
    if (cmd === 'jq') {
      console.error('  macOS:  brew install jq');
      console.error('  Linux:  sudo apt install jq');
    } else {
      console.error('  macOS:  python3 is pre-installed');
      console.error('  Linux:  sudo apt install python3');
    }
    process.exit(1);
  }
}

const args = process.argv.slice(2);
const isUninstall = args.includes('--uninstall') || args.includes('uninstall');

// ── Uninstall ───────────────────────────────────────────────────────────────
if (isUninstall) {
  console.log('==> Uninstalling claude-bar...');

  if (fs.existsSync(TARGET)) {
    fs.unlinkSync(TARGET);
    console.log(`    Removed ${TARGET}`);
  }

  if (fs.existsSync(SETTINGS)) {
    const settings = JSON.parse(fs.readFileSync(SETTINGS, 'utf8'));
    delete settings.statusLine;
    fs.writeFileSync(SETTINGS, JSON.stringify(settings, null, 2) + '\n');
    console.log(`    Removed statusLine from ${SETTINGS}`);
  }

  console.log('\n✓ Uninstalled. Restart Claude Code to revert to the default status bar.');
  process.exit(0);
}

// ── Install ─────────────────────────────────────────────────────────────────
console.log('==> Installing claude-bar...\n');

checkDep('jq');
checkDep('python3');

// Copy script
fs.mkdirSync(CLAUDE_DIR, { recursive: true });
fs.copyFileSync(SCRIPT_SRC, TARGET);
fs.chmodSync(TARGET, 0o755);
console.log(`    Copied statusline-command.sh -> ${TARGET}`);

// Patch settings.json
if (!fs.existsSync(SETTINGS)) {
  fs.writeFileSync(SETTINGS, '{}\n');
}

const backup = SETTINGS + '.claude-bar_backup';
fs.copyFileSync(SETTINGS, backup);

let settings = {};
try {
  settings = JSON.parse(fs.readFileSync(SETTINGS, 'utf8'));
} catch {
  console.error(`\nError: Could not parse ${SETTINGS}. Fix the JSON and re-run.`);
  process.exit(1);
}

settings.statusLine = {
  type: 'command',
  command: `bash ${TARGET}`,
};

fs.writeFileSync(SETTINGS, JSON.stringify(settings, null, 2) + '\n');
console.log(`    Patched ${SETTINGS}`);
console.log(`    (backup saved at ${backup})\n`);

console.log('✓ Done! Restart Claude Code to see your new status bar.\n');
console.log('  Preview:');
console.log('  Sonnet 4.6  ~/myproject context[████░░░░░░ 40%] ↩12.3k ∑456k\n');
console.log('  To uninstall:  npx claude-bar uninstall');
